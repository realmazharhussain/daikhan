public enum RepeatMode {
    OFF,
    TRACK,
    QUEUE
}


internal unowned Playback? default_playback;

public class Playback : Object {
    Settings settings;

    public dynamic Gst.Pipeline pipeline { get; private construct; }
    public dynamic Gdk.Paintable paintable { get; private construct; }
    public Daikhan.History history { get; private construct; }

    public string? filename { get; private set; }
    public int64 progress { get; private set; default = -1; }
    public int64 duration { get; private set; default = -1; }

    public Daikhan.TrackInfo track_info { get; private construct; }

    public bool paused { get; set; default = false; }
    public bool can_play { get; private set; default = false; }

    public RepeatMode repeat { get; set; default = OFF; }
    public Daikhan.PlayFlags flags { get; set; }

    public signal void unsupported_file ();

    [CCode (notify = false)]
    public double volume {
        get { return Gst.Audio.StreamVolume.convert_volume (LINEAR, CUBIC, pipeline.volume); }
        set { pipeline.volume = Gst.Audio.StreamVolume.convert_volume (CUBIC, LINEAR, value); }
    }

    public Daikhan.Queue? prev_queue;
    private Daikhan.Queue? _queue = new Daikhan.Queue();
    public Daikhan.Queue? queue {
        get {
            return _queue;
        }

        set construct {
            _queue = value;
            this.current_track = -1;

            can_play = (prev_queue != null || value != null);
        }
    }

    public Daikhan.HistoryRecord? current_record = null;
    private int _current_track = -1;
    public int current_track {
        get {
            return _current_track;
        }

        private set {
            if (value == _current_track) {
                return;
            }

            if (current_record != null) {
                history.update(current_record);
            }

            if (value < 0 || value >= queue.length) {
                filename = null;
                current_record = null;
            } else try {
                var info = queue[value].query_info("standard::display-name", NONE);
                filename = info.get_display_name();
                current_record = new Daikhan.HistoryRecord.with_uri(queue[value].get_uri());

                if (!(AUDIO in flags)) {
                    current_record.audio_track = -1;
                }
                if (!(SUBTITLES in flags)) {
                    current_record.text_track = -1;
                }
                if (!(VIDEO in flags)) {
                    current_record.video_track = -1;
                }
            } catch (Error err) {
                warning(err.message);
            }

            progress = -1;
            duration = -1;
            track_info.reset();

            _current_track = value;
        }
    }

    construct {
        dynamic var gtksink = Gst.ElementFactory.make("gtk4paintablesink", null);

        pipeline = Gst.ElementFactory.make("playbin", null) as Gst.Pipeline;
        track_info = new Daikhan.TrackInfo(pipeline);
        settings = new Settings(Conf.APP_ID);
        history = Daikhan.History.get_default();
        paintable = gtksink.paintable;

        if (paintable.gl_context != null) {
            dynamic var glsink = Gst.ElementFactory.make("glsinkbin", null);
            glsink.sink = gtksink;
            pipeline.video_sink = glsink;
        } else {
            pipeline.video_sink = gtksink;
        }

        pipeline.bus.add_signal_watch();
        pipeline.bus.message["eos"].connect(pipeline_eos_cb);
        pipeline.bus.message["error"].connect(pipeline_error_cb);
        pipeline.bus.message["state-changed"].connect(pipeline_state_changed_message_cb);

        pipeline.bind_property("flags", this, "flags", SYNC_CREATE|BIDIRECTIONAL);
        pipeline.notify["volume"].connect(()=> { notify_property("volume"); });
    }

    public Gst.State target_state { get; private set; default = NULL; }
    public Gst.State current_state { get; private set; default = NULL; }

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

        current_track = track_index;

        var file = queue[track_index];

        if (!Daikhan.Utils.is_file_type_supported(file)) {
            set_state(NULL);
            unsupported_file();
            return false;
        }

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

        return true;
    }

    /* Loads the next track expected to be played in the list. In case
     * there is no track is expected to be played next, it stops playback.
     * This also implements the `queue` repeat mode.
     */
    public bool next() {
        if (queue != null && current_track + 1 < queue.length) {
            return load_track(current_track + 1);
        } else if (repeat == QUEUE) {
            return load_track(0);
        } else {
            stop();
            return false;
        }
    }

    public bool prev() {
        if (current_track < 1 || queue == null || queue.length == 0) {
            return false;
        }

        return load_track(current_track - 1);
    }

    public bool open_files(File[] files) {
        return open_queue(new Daikhan.Queue(files));
    }

    public bool open_queue(Daikhan.Queue queue) {
        this.queue = queue;

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
            return open_queue(prev_queue);
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
            queue = null;
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

    void pipeline_state_changed_message_cb() {
        current_state = pipeline.current_state;

        if (pipeline.current_state == pipeline.target_state == Gst.State.PLAYING) {
            ensure_progress_tracking ();
        } else {
            stop_progress_tracking ();
        }
    }

    public signal void unsupported_codec (string debug_info);

    void pipeline_error_cb (Gst.Bus bus, Gst.Message msg) {
        Error err;
        string debug_info;

        msg.parse_error(out err, out debug_info);

        if (err is Gst.CoreError.MISSING_PLUGIN) {
            set_state(NULL);
            unsupported_codec(debug_info);
            return;
        }

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
