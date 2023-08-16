[Flags]
public enum PipelinePlayFlags {
    VIDEO,
    AUDIO,
    SUBTITLES
}

public enum RepeatMode {
    OFF,
    TRACK,
    QUEUE
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


internal unowned Playback? default_playback;

public class Playback : Object {
    Settings settings;

    public Gst.Pipeline pipeline { get; private set; }
    public PlaybackHistory history { get; private construct; }

    public string? filename { get; private set; }
    public double volume { get; set; default = 1; }
    public int64 progress { get; private set; default = -1; }
    public int64 duration { get; private set; default = -1; }

    public string? title { get; private set; }
    public string? artist { get; private set; }
    public string? album { get; private set; }

    public bool paused { get; set; default = false; }
    public bool can_play { get; private set; default = false; }
    public bool can_next { get; private set; default = false; }
    public bool can_prev { get; private set; default = false; }
    public bool multiple_tracks { get; private set; default = false; }

    public RepeatMode repeat { get; set; default = OFF; }
    public uint flags { get; set; }

    public File[]? prev_queue;
    public File[]? queue;
    public void set_queue(File[]? queue) {
        this.queue = queue;
        this.track = -1;
        this.can_prev = false;

        can_play = (prev_queue != null || queue != null);

        if (queue == null) {
            this.multiple_tracks = false;
            this.can_next = false;
        } else {
            this.multiple_tracks = queue.length > 1;
            this.can_next = track_exists(0);
        }
    }

    public HistoryRecord? current_record = null;
    private int _track = -1;
    public int track {
        get {
            return _track;
        }

        private set {
            if (value == _track) {
                return;
            }

            can_prev = track_exists(value - 1);
            can_next = track_exists(value + 1);

            if (current_record != null) {
                history.update(current_record);
            }

            if (value < 0 || value >= queue.length) {
                filename = null;
                current_record = null;
            } else try {
                var info = queue[value].query_info("standard::display-name", NONE);
                filename = info.get_display_name();
                current_record = new HistoryRecord.with_uri(queue[value].get_uri());

                if ((flags & PipelinePlayFlags.AUDIO) == 0) {
                    current_record.audio_track = -1;
                }
                if ((flags & PipelinePlayFlags.SUBTITLES) == 0) {
                    current_record.text_track = -1;
                }
                if ((flags & PipelinePlayFlags.VIDEO) == 0) {
                    current_record.video_track = -1;
                }
            } catch (Error err) {
                warning(err.message);
            }

            progress = -1;
            duration = -1;
            album = null;
            artist = null;
            title = null;

            _track = value;
        }
    }

    construct {
        settings = new Settings(Conf.APP_ID);
        history = PlaybackHistory.get_default();

        pipeline = Gst.ElementFactory.make("playbin", null) as Gst.Pipeline;
        pipeline.bus.add_signal_watch();
        pipeline.bus.message["eos"].connect(pipeline_eos_cb);
        pipeline.bus.message["error"].connect(pipeline_error_cb);
        pipeline.bus.message["state-changed"].connect(pipeline_state_changed_message_cb);
        pipeline.bus.message["tag"].connect(pipeline_tag_message_cb);

        pipeline.bind_property("flags", this, "flags", SYNC_CREATE|BIDIRECTIONAL);
        pipeline.bind_property("volume", this, "volume",
                               SYNC_CREATE|BIDIRECTIONAL,
                               AudioVolume.linear_to_logarithmic,
                               AudioVolume.logarithmic_to_linear);
    }

    public static bool is_file_type_supported (File file) {
        string mimetype;

        try {
            mimetype = file.query_info ("standard::", NONE).get_content_type ();
        } catch (Error err) {
            return false;
        }

        return mimetype.has_prefix("video/") || mimetype.has_prefix("audio/");
    }

    private Gst.State _target_state = NULL;
    public Gst.State target_state {
        get {
            return _target_state;
        }

        private set {
            if (value == _target_state) {
                return;
            }

            if (value != PLAYING) {
                stop_progress_tracking();
            }

            _target_state = value;
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

            if (value == PLAYING) {
                ensure_progress_tracking();
            } else {
                stop_progress_tracking();
            }

            _current_state = value;
        }
    }

    public static Playback get_default() {
        default_playback = default_playback ?? new Playback();
        return default_playback;
    }

    private bool track_exists(int track_index) {
        if (queue == null) {
            return false;
        }

        if (track_index < 0 || track_index >= queue.length) {
            return false;
        }

        return true;
    }

    public bool load_track(int track_index) {
        if (!track_exists(track_index)) {
            return false;
        }

        var file = queue[track_index];

        if (target_state != NULL) {
            set_state(NULL);
        }

        pipeline["uri"] = file.get_uri();

        if (!set_state(paused ? Gst.State.PAUSED : Gst.State.PLAYING)) {
            critical("Cannot load track!");
            return false;
        }

        ulong handler_id = 0;
        handler_id = notify["current-state"].connect(() => {
            if (current_state == PAUSED) {
                update_duration ();
                update_progress ();
                SignalHandler.disconnect (this, handler_id);
            }
        });

        track = track_index;

        return true;
    }

    /* Loads the next track expected to be played in the list. In case
     * there is no track is expected to be played next, it stops playback.
     * This also implements the `queue` repeat mode.
     */
    public bool next() {
        if (can_next) {
            return load_track(track + 1);
        } else if (repeat == QUEUE) {
            return load_track(0);
        } else {
            stop();
            return false;
        }
    }

    public bool prev() {
        if (!can_prev) {
            return false;
        }

        return load_track(track - 1);
    }

    public bool open(File[] files) {
        set_queue(files);

        var status = false;
        if (load_track(0)) {
            status = set_state(PLAYING);
        }
        return status;
    }

    public bool toggle_playing() {
        if (target_state == PLAYING) {
            return pause();
        }

        return play();
    }

    public bool play() {
        paused = false;

        if (target_state != NULL) {
            return set_state(PLAYING);
        } else if (prev_queue != null) {
            return open(prev_queue);
        }
        return false;
    }

    public bool pause() {
        paused = true;

        if (target_state == NULL) {
            return false;
        }

        return set_state(PAUSED);
    }

    public void stop() {
        if (target_state != NULL) {
            set_state(NULL);
        }

        if (queue != null) {
            prev_queue = queue;
            set_queue(null);
        }
    }

    public bool seek(int64 seconds) {
        var absolute_time = progress + (seconds * Gst.SECOND);

        if (absolute_time < 0) {
            absolute_time = 0;
        } else if (absolute_time > duration) {
            absolute_time = duration;
        }
        return seek_absolute((Gst.ClockTime) absolute_time);
    }

    public bool seek_absolute(Gst.ClockTime nano_seconds) {
        var seeking_method = settings.get_string("seeking-method");

        Gst.SeekFlags seek_flags = FLUSH;
        if (seeking_method == "fast") {
            seek_flags |= KEY_UNIT;
        } else if (seeking_method == "accurate") {
            seek_flags |= ACCURATE;
        }

        if (pipeline.seek_simple(TIME, seek_flags, (int64)nano_seconds)) {
            progress = (int64) nano_seconds;
            return true;
        }

        return false;

    }

    TimeoutSource? progress_source;

    void ensure_progress_tracking() {
        if (progress_source != null && !progress_source.is_destroyed()) {
            return;
        }

        if (duration == -1) {
            update_duration();
        }

        update_progress();

        progress_source = new TimeoutSource(250);
        progress_source.set_callback(update_progress);
        progress_source.attach();
    }

    bool update_duration() {
        int64 duration;
        if (!pipeline.query_duration(TIME, out duration)) {
            return false;
        }

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
        current_record.progress = progress;

        return Source.CONTINUE;
    }

    void stop_progress_tracking() {
        if (progress_source == null || progress_source.is_destroyed()) {
            return;
        }

        var source_id = progress_source.get_id();
        Source.remove(source_id);
    }

    public bool set_state(Gst.State new_state) {
        if (target_state == new_state) {
            return true;
        }

        if (pipeline.set_state(new_state) == FAILURE) {
            critical(@"Failed to set pipeline state to $(new_state)!");
            return false;
        }

        target_state = new_state;
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
        current_record.progress = -1;

        if (repeat == TRACK) {
            seek_absolute(0);
        } else {
            next();
        }
    }

    ~Playback() {
        stop();
    }
}
