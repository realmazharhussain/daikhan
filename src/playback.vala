[Flags]
enum PipelinePlayFlags {
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


internal Playback? default_playback;

public class Playback : Object {
    public File? last_opened_file { get; private set; }
    public string? title { get; private set; }
    public double volume { get; set; default = 1; }
    public int64 progress { get; private set; default = -1; }
    public int64 duration { get; private set; default = -1; }
    public bool can_play { get; private set; default = false; }

    Binding? volume_binding;

    private Gst.Pipeline? _pipeline;
    public Gst.Pipeline? pipeline {
        get {
            return _pipeline;
        }

        private set {
            if (_pipeline == value) {
                return;
            }

            if (_pipeline != null) {
                volume_binding.unbind();
                try_set_state(NULL);

                var bus = _pipeline.get_bus();
                bus.message["state-changed"].disconnect(pipeline_state_changed_message_cb);
                bus.message["error"].disconnect(pipeline_error_cb);
                bus.message["eos"].disconnect(pipeline_eos_cb);
                bus.remove_signal_watch();
            }

            // Reset all pipeline related properties
            current_state = NULL;
            title = null;
            progress = -1;
            duration = -1;

            if (value != null) {
                var bus = value.get_bus();
                bus.add_signal_watch();
                bus.message["eos"].connect(pipeline_eos_cb);
                bus.message["error"].connect(pipeline_error_cb);
                bus.message["state-changed"].connect(pipeline_state_changed_message_cb);

                volume_binding = value.bind_property("volume", this, "volume",
                                                     SYNC_CREATE|BIDIRECTIONAL,
                                                     AudioVolume.linear_to_logarithmic,
                                                     AudioVolume.logarithmic_to_linear);

                // Disable Subtitles
                dynamic Object _value = value;
                _value.flags = (PipelinePlayFlags) _value.flags & ~PipelinePlayFlags.SUBTITLES;
            }

            _pipeline = value;
        }
    }

    private Gst.State _desired_state = NULL;
    public Gst.State desired_state {
        get {
            return _desired_state;
        }

        private set {
            if (value == _desired_state) {
                return;
            }

            if (value != PLAYING)
                stop_progress_tracking();

            _desired_state = value;
        }
    }

    private Gst.State _current_state = NULL;
    public Gst.State current_state {
        get {
            return _current_state;
        }

        private set {
            if (value == _current_state) {
                return;
            }

            if (value == PLAYING)
                ensure_progress_tracking();
            else
                stop_progress_tracking();

            _current_state = value;
        }
    }

    public static unowned Playback get_default() {
        default_playback = default_playback ?? new Playback();
        return default_playback;
    }

    public bool open_file(File file) {
        stop();

        pipeline = Gst.ElementFactory.make("playbin", null) as Gst.Pipeline;
        if (pipeline == null) {
            critical("Failed to create pipeline!");
            return false;
        }

        pipeline["uri"] = file.get_uri();

        if (!play()) {
            critical("Cannot play!");
            return false;
        }

        last_opened_file = file;
        can_play = true;

        try {
            var info = file.query_info("standard::display-name", NONE);
            title = info.get_display_name();
        } catch (Error err) {
            warning(err.message);
        }

        return true;
    }

    public bool toggle_playing() {
        if (desired_state == PLAYING)
            return pause();

        return play();
    }

    public bool play() {
        if (pipeline != null) {
            return try_set_state(PLAYING);
        } else if (last_opened_file != null) {
            return open_file(last_opened_file);
        }
        return false;
    }

    public bool pause() {
        if (pipeline == null) {
            return false;
        }
        return try_set_state(PAUSED);
    }

    public void stop() {
        pipeline = null;
    }

    public bool seek(int64 seconds) {
        var absolute_time = progress + (seconds * Gst.SECOND);

        if (absolute_time < 0) {
            absolute_time = 0;
        }
        else if (absolute_time > duration) {
            absolute_time = duration;
        }
        return seek_absolute((Gst.ClockTime) absolute_time);
    }

    public bool seek_absolute(Gst.ClockTime nano_seconds) {
        if (pipeline.seek_simple(TIME, FLUSH, (int64)nano_seconds)) {
            progress = (int64) nano_seconds;
            return true;
        }

        return false;

    }

    uint timeout_id = 0;

    void ensure_progress_tracking() {
        if (timeout_id > 0)
            return;

        if (duration == -1)
            update_duration();

        update_progress();
        timeout_id = Timeout.add(100, update_progress);
    }

    bool update_progress() {
        int64 progress;
        if (!pipeline.query_position(TIME, out progress)) {
            warning("Failed to query playback position");
            return Source.REMOVE;
        }

        this.progress = progress;

        return Source.CONTINUE;
    }

    bool update_duration() {
        int64 duration;
        if (!pipeline.query_duration(TIME, out duration))
            return false;

        this.duration = duration;
        return true;
    }

    void stop_progress_tracking() {
        if (timeout_id == 0)
            return;

        if (Source.remove(timeout_id))
            timeout_id = 0;
    }

    bool try_set_state(Gst.State new_state) {
        if (desired_state == new_state) {
            return true;
        }

        if (pipeline.set_state(new_state) == FAILURE) {
            critical(@"Failed to set pipeline state to $(new_state)!");
            return false;
        }

        desired_state = new_state;
        return true;
    }

    void pipeline_state_changed_message_cb() {
        current_state = pipeline.current_state;
    }

    void pipeline_error_cb (Gst.Bus bus, Gst.Message msg) {
        Error err;
        string debug_info;

        msg.parse_error(out err, out debug_info);

        warning(@"Error message received from $(msg.src.name): $(err.message)");
        warning(@"Debugging info: $(debug_info)");
    }

    void pipeline_eos_cb () {
        stop();
    }

    ~Playback() {
        stop();
    }
}
