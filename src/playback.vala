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
    public Gst.Element? video_sink { get; set; }
    public string? filename { get; private set; }
    public double volume { get; set; default = 1; }
    public int64 progress { get; private set; default = -1; }
    public int64 duration { get; private set; default = -1; }

    public string? title { get; private set; }
    public string? artist { get; private set; }
    public string? album { get; private set; }

    public bool can_play { get; private set; default = false; }
    public bool can_next { get; private set; default = false; }
    public bool can_prev { get; private set; default = false; }
    public bool multiple_tracks { get; private set; default = false; }

    public File[]? prev_queue;
    public File[]? queue;
    public void set_queue(File[]? queue) {
        this.queue = queue;
        this.track = -1;
        this.can_prev = false;

        if (queue == null) {
            this.multiple_tracks = false;
            this.can_next = false;
        } else {
            this.multiple_tracks = queue.length > 1;
            this.can_next = can_play_track(0);
        }
    }

    private int _track = -1;
    public int track {
        get {
            return _track;
        }

        private set {
            if (value == _track)
                return;

            can_prev = can_play_track(value - 1);
            can_next = can_play_track(value + 1);

            _track = value;
        }
    }

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
                _pipeline["video-sink"] = null;
                volume_binding.unbind();
                try_set_state(NULL);

                var bus = _pipeline.get_bus();
                bus.message["tag"].disconnect(pipeline_tag_message_cb);
                bus.message["state-changed"].disconnect(pipeline_state_changed_message_cb);
                bus.message["error"].disconnect(pipeline_error_cb);
                bus.message["eos"].disconnect(pipeline_eos_cb);
                bus.remove_signal_watch();
            }

            // Reset all pipeline related properties
            current_state = NULL;
            progress = -1;
            duration = -1;
            filename = null;
            album = null;
            artist = null;
            title = null;

            if (value != null) {
                var bus = value.get_bus();
                bus.add_signal_watch();
                bus.message["eos"].connect(pipeline_eos_cb);
                bus.message["error"].connect(pipeline_error_cb);
                bus.message["state-changed"].connect(pipeline_state_changed_message_cb);
                bus.message["tag"].connect(pipeline_tag_message_cb);

                value["video-sink"] = video_sink;

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

    private bool can_play_track(int track_index) {
        if (queue == null)
            return false;

        if (track_index < 0 || track_index >= queue.length)
            return false;
        
        return true;
    }

    private bool play_track(int track_index) {
        if (!can_play_track(track_index))
            return false;

        pipeline = Gst.ElementFactory.make("playbin", null) as Gst.Pipeline;
        assert(pipeline != null);

        var file = queue[track_index];

        pipeline["uri"] = file.get_uri();

        if (!play()) {
            critical("Cannot play!");
            return false;
        }

        try {
            var info = file.query_info("standard::display-name", NONE);
            filename = info.get_display_name();
        } catch (Error err) {
            warning(err.message);
        }

        return true;
    }

    public bool next() {
        if (!can_next)
            return false;

        if (!play_track(track + 1))
            return false;

        track++;

        return true;
    }

    public bool prev() {
        if (!can_prev)
            return false;

        if (!play_track(track - 1))
            return false;

        track--;

        return true;
    }

    public bool open(File[] files) {
        assert(files.length > 0);

        set_queue(files);
        can_play = true;

        return next();
    }

    public bool toggle_playing() {
        if (desired_state == PLAYING)
            return pause();

        return play();
    }

    public bool play() {
        if (pipeline != null) {
            return try_set_state(PLAYING);
        } else if (prev_queue != null) {
            return open(prev_queue);
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

        if (queue != null) {
            prev_queue = queue;
            set_queue(null);
        }
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

    TimeoutSource? progress_source;

    void ensure_progress_tracking() {
        if (progress_source != null && !progress_source.is_destroyed())
            return;

        if (duration == -1)
            update_duration();

        update_progress();

        progress_source = new TimeoutSource(250);
        progress_source.set_callback(update_progress);
        progress_source.attach();
    }

    bool update_duration() {
        int64 duration;
        if (!pipeline.query_duration(TIME, out duration))
            return false;

        this.duration = duration;
        return true;
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

    void stop_progress_tracking() {
        if (progress_source == null || progress_source.is_destroyed())
            return;

        var source_id = progress_source.get_id();
        Source.remove(source_id);
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

    void pipeline_tag_message_cb (Gst.Bus bus, Gst.Message msg) {
        Gst.TagList tag_list;
        msg.parse_tag(out tag_list);

        if (this.album == null) {
            string album;
            tag_list.get_string(Gst.Tags.ALBUM, out album);
            this.album = album;
        }

        if (this.artist == null) {
            string artist;
            tag_list.get_string(Gst.Tags.ARTIST, out artist);
            this.artist = artist;
        }

        if (this.title == null) {
            string title;
            tag_list.get_string(Gst.Tags.TITLE, out title);
            this.title = title;
        }
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
        if (can_next)
            next();
        else
            stop();
    }

    ~Playback() {
        stop();
    }
}
