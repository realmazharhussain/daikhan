/* A helper class to make using GstPlayBin easier */
public class Daikhan.PlaybinProxy : Object {
    public dynamic Gst.Pipeline pipeline { get; private construct; }
    public dynamic Gdk.Paintable paintable { get; private construct; }
    public Gst.State target_state { get; private set; default = NULL; }
    public Gst.State current_state { get; private set; default = NULL; }
    public Daikhan.PlayFlags flags { get; set; }

    [CCode (notify = false)]
    public double volume {
        get { return Gst.Audio.StreamVolume.convert_volume (LINEAR, CUBIC, pipeline.volume); }
        set { pipeline.volume = Gst.Audio.StreamVolume.convert_volume (CUBIC, LINEAR, value); }
    }

    public signal void unsupported_file ();
    public virtual signal void end_of_stream () {}
    public signal void unsupported_codec (string debug_info);

    construct {
        dynamic var gtksink = Gst.ElementFactory.make ("gtk4paintablesink", null);

        pipeline = Gst.ElementFactory.make ("playbin", null) as Gst.Pipeline;
        paintable = gtksink.paintable;

        if (paintable.gl_context != null) {
            dynamic var glsink = Gst.ElementFactory.make ("glsinkbin", null);
            glsink.sink = gtksink;
            pipeline.video_sink = glsink;
        } else {
            pipeline.video_sink = gtksink;
        }

        pipeline.bus.add_signal_watch ();
        pipeline.bus.message["eos"].connect (pipeline_eos_cb);
        pipeline.bus.message["error"].connect (pipeline_error_cb);
        pipeline.bus.message["state-changed"].connect (pipeline_state_changed_cb);

        pipeline.bind_property ("flags", this, "flags", SYNC_CREATE | BIDIRECTIONAL);
        pipeline.notify["volume"].connect (() => { notify_property ("volume"); });
    }

    public bool set_state (Gst.State new_state) {
        if (pipeline.target_state == new_state) {
            return true;
        }

        if (pipeline.set_state (new_state) == FAILURE) {
            critical (@"Failed to set pipeline state to $(new_state)!");
            return false;
        }

        target_state = new_state;
        return true;
    }

    void pipeline_state_changed_cb () {
        current_state = pipeline.current_state;
    }

    void pipeline_error_cb (Gst.Bus bus, Gst.Message msg) {
        Error err;
        string debug_info;

        msg.parse_error (out err, out debug_info);

        if (err is Gst.CoreError.MISSING_PLUGIN) {
            unsupported_codec (debug_info);
        } else if (err is Gst.StreamError.TYPE_NOT_FOUND) {
            unsupported_file ();
        } else {
            warning (@"Error message received from $(msg.src.name): $(err.message)");
            warning (@"Debugging info: $(debug_info)");
        }

        set_state (READY);
    }

    void pipeline_eos_cb () {
        end_of_stream.emit ();
    }
}
