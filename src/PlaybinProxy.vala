/* A helper class to make using GstPlayBin easier */
public class Daikhan.PlaybinProxy : Object {
    public dynamic Gst.Pipeline pipeline { get; private construct; }
    public dynamic Gdk.Paintable paintable { get; private construct; }
    public Daikhan.TrackInfo track_info { get; private construct; }
    public Daikhan.HistoryRecord? current_record { get; private set; default = null; }
    public Gst.State target_state { get; private set; default = NULL; }
    public Gst.State current_state { get; private set; default = NULL; }
    public string? filename { get; private set; default = null; }
    public int64 progress { get; private set; default = -1; }
    public int64 duration { get; private set; default = -1; }
    public Daikhan.PlayFlags flags { get; set; }
    public double volume { get; set; }

    public signal void unsupported_file ();
    public virtual signal void end_of_stream () {}
    public signal void unsupported_codec (string debug_info);
    public signal void pipeline_error (Gst.Object source, Error error, string debug_info);

    Settings settings;

    construct {
        settings = new Settings (Conf.APP_ID);
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

        track_info = new Daikhan.TrackInfo (pipeline);

        pipeline.bus.add_signal_watch ();
        pipeline.bus.message["eos"].connect (pipeline_eos_cb);
        pipeline.bus.message["error"].connect (pipeline_error_cb);
        pipeline.bus.message["state-changed"].connect (pipeline_state_changed_cb);

        pipeline.bind_property ("flags", this, "flags", SYNC_CREATE | BIDIRECTIONAL);

        pipeline.bind_property ("volume", this, "volume", SYNC_CREATE | BIDIRECTIONAL,
            (binding, linear, ref cubic) => {
                cubic = Gst.Audio.StreamVolume.convert_volume (LINEAR, CUBIC, (double) linear);
                return true;
            },
            (binding, cubic, ref linear) => {
                linear = Gst.Audio.StreamVolume.convert_volume (CUBIC, LINEAR, (double) cubic);
                return true;
            }
        );

        notify["target-state"].connect (decide_on_progress_tracking);
        notify["current-state"].connect (decide_on_progress_tracking);
    }

    public void reset () {
        set_state (NULL);
        track_info.reset ();
        current_record = null;
        filename = null;
        progress = -1;
        duration = -1;
    }

    public bool open_file (File file, Gst.State desired_state) {
        try {
            var info = file.query_info ("standard::display-name", NONE);
            filename = info.get_display_name ();
        } catch (Error err) {
            filename = file.get_basename ();
        }

        pipeline["uri"] = file.get_uri ();

        ulong handler_id = 0;
        handler_id = notify["current-state"].connect (() => {
            if (current_state == desired_state) {
                update_duration ();
                update_progress ();
                SignalHandler.disconnect (this, handler_id);
            }
        });

        current_record = new Daikhan.HistoryRecord.with_uri (file.get_uri ());

        if (!set_state (desired_state)) {
            critical ("Cannot load track!");
            return false;
        }

        if (!(AUDIO in flags)) {
            current_record.audio_track = -1;
        }
        if (!(SUBTITLES in flags)) {
            current_record.text_track = -1;
        }
        if (!(VIDEO in flags)) {
            current_record.video_track = -1;
        }

        return true;
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

    public bool seek (int64 seconds) {
        var seek_pos = progress + (seconds * Gst.SECOND);
        return seek_absolute (seek_pos);
    }

    public bool seek_absolute (int64 seek_pos) {
        var seeking_method = settings.get_string ("seeking-method");

        Gst.SeekFlags seek_flags = FLUSH;
        if (seeking_method == "fast") {
            seek_flags |= KEY_UNIT;
        } else if (seeking_method == "accurate") {
            seek_flags |= ACCURATE;
        }

        if (seek_pos < 0) {
            seek_pos = 0;
        } else if (seek_pos > duration > 0) {
            seek_pos = duration;
        }

        if (pipeline.seek_simple (TIME, seek_flags, seek_pos)) {
            progress = seek_pos;
            return true;
        }

        return false;

    }

    bool update_duration () {
        int64 duration;
        if (!pipeline.query_duration (TIME, out duration)) {
            return false;
        }

        this.duration = duration;
        return true;
    }

    bool update_progress () {
        int64 progress;
        if (!pipeline.query_position (TIME, out progress)) {
            warning ("Failed to query playback position");
            return Source.REMOVE;
        }

        this.progress = progress;
        current_record.progress = progress;

        return Source.CONTINUE;
    }

    TimeoutSource? progress_source;

    void ensure_progress_tracking () {
        if (progress_source != null && !progress_source.is_destroyed ()) {
            return;
        }

        if (duration == -1) {
            update_duration ();
        }

        update_progress ();

        progress_source = new TimeoutSource (250);
        progress_source.set_callback (update_progress);
        progress_source.attach ();
    }

    void stop_progress_tracking () {
        if (progress_source == null || progress_source.is_destroyed ()) {
            return;
        }

        var source_id = progress_source.get_id ();
        Source.remove (source_id);
    }

    public void decide_on_progress_tracking () {
        if (current_state == target_state == Gst.State.PLAYING) {
            ensure_progress_tracking ();
        } else {
            stop_progress_tracking ();
        }
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
            pipeline_error (msg.src, err, debug_info);
        }

        set_state (NULL);
    }

    void pipeline_eos_cb () {
        end_of_stream.emit ();
    }
}
