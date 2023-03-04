[Flags]
enum Gst.PlayFlags {
    VIDEO,
    AUDIO,
    SUBTITLES
}


namespace AudioVolume {
    bool linear_to_logarithmic (Binding binding, Value linear, ref Value logarithmic) {
        logarithmic = Math.cbrt((double)linear);
        return true;
    }

    bool logarithmic_to_linear (Binding binding, Value logarithmic, ref Value linear) {
        linear = Math.pow((double)logarithmic, 3);
        return true;
    }
}


public class Playback : Object {
    Gst.State _pipeline_state = Gst.State.NULL;
    ulong _pipeline_state_handler_id = 0;

    public double volume { get; set; default=1; }

    private Gst.Pipeline? _pipeline;
    public Gst.Pipeline? pipeline {
        get { return _pipeline; }
        set {
            if (_pipeline == value) {
                return;
            }

            disconnect_pipeline();
            _pipeline = value;
            connect_pipeline();
        }
    }

    private bool _playing = false;
    public bool playing {
        get { return _playing; }
        set {
            if (_playing == value) {
                return;
            }

            _playing = value;

            if (pipeline != null) {
                if (_playing) {
                    pipeline.set_state(Gst.State.PLAYING);
                } else if (pipeline.current_state == Gst.State.PLAYING) {
                    pipeline.set_state(Gst.State.PAUSED);
                }
            }
        }
    }

    construct {
        pipeline = Gst.ElementFactory.make("playbin", null) as Gst.Pipeline;
        if (pipeline == null) {
            critical("Failed to create pipeline!");
            return;
        }

        var bus = pipeline.get_bus();
        bus.add_signal_watch();
        bus.message["eos"].connect(gst_eos_cb);
        bus.message["error"].connect(gst_error_cb);

        // Disable Subtitles
        Gst.PlayFlags play_flags;
        pipeline.get("flags", out play_flags);
        play_flags &= ~Gst.PlayFlags.SUBTITLES;
        pipeline.set("flags", play_flags);

        pipeline.bind_property("volume", this, "volume",
                               BindingFlags.SYNC_CREATE|BindingFlags.BIDIRECTIONAL,
                               AudioVolume.linear_to_logarithmic,
                               AudioVolume.logarithmic_to_linear);
    }

    ~Playback() {
        if (pipeline != null) {
            pipeline.set_state(Gst.State.NULL);
        }
    }

    public bool open_file(File file) {
        var result = pipeline.set_state(Gst.State.NULL);
        if (result == Gst.StateChangeReturn.FAILURE) {
            warning("Failed to change pipeline state to NULL!");
        }


        pipeline.set("uri", file.get_uri());

        result = pipeline.set_state(Gst.State.PLAYING);
        if (result == Gst.StateChangeReturn.FAILURE) {
            critical("Failed to change pipeline state to PLAYING!");
            return false;
        }
        
        return true;
    }

    void on_pipeline_state_changed() {
        if (_pipeline_state == pipeline.current_state) {
            return;
        }

        _pipeline_state = pipeline.current_state;

        if (_pipeline_state == Gst.State.PLAYING) {
            playing = true;
        } else if (_pipeline_state == Gst.State.PAUSED ||
                   _pipeline_state == Gst.State.NULL) {
            playing = false;
        }
    }

    void disconnect_pipeline() {
        if (pipeline != null) {
            disconnect(_pipeline_state_handler_id);
        }
    }

    void connect_pipeline() {
        if (pipeline == null) {
            return;
        }

        var bus = pipeline.get_bus();
        _pipeline_state_handler_id = bus.message["state-changed"].connect(on_pipeline_state_changed);
    }

    void gst_eos_cb () {
        if (!pipeline.seek_simple(Gst.Format.TIME, Gst.SeekFlags.FLUSH|Gst.SeekFlags.KEY_UNIT, 0)) {
            critical("Failed to seek!");
        }
        var result = pipeline.set_state(Gst.State.PAUSED);
        if (result == Gst.StateChangeReturn.FAILURE) {
            critical("Failed to change pipeline state to PAUSED!");
        }
    }

    void gst_error_cb (Gst.Bus bus, Gst.Message msg) {
        Error err;
        string debug_info;

        msg.parse_error(out err, out debug_info);

        warning(@"Error message received from $(msg.src.name): $(err.message)");
        warning(@"Debugging info: $(debug_info)");
    }
}
