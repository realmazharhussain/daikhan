public enum RepeatMode {
    OFF,
    TRACK,
    QUEUE
}


internal unowned Playback? default_playback;

public class Playback : Object {
    /* Read-Write properties */
    public Daikhan.Queue queue { get; set; default = new Daikhan.Queue(); }
    public RepeatMode repeat { get; set; default = OFF; }
    public Daikhan.PlayFlags flags { get; set; }

    /* Read-only properties */
    public dynamic Gst.Pipeline pipeline { get; private construct; }
    public dynamic Gdk.Paintable paintable { get; private construct; }
    public Daikhan.History history { get; private construct; }
    public Daikhan.HistoryRecord? current_record { get; private set; default = null; }
    public Daikhan.TrackInfo track_info { get; private construct; }
    public Gst.State target_state { get; private set; default = NULL; }
    public Gst.State current_state { get; private set; default = NULL; }
    public int current_track { get; private set; default = -1; }
    public string? filename { get; private set; }
    public int64 progress { get; private set; default = -1; }
    public int64 duration { get; private set; default = -1; }

    /* Forwarded/transformed properties */
    [CCode (notify = false)]
    public double volume {
        get { return Gst.Audio.StreamVolume.convert_volume (LINEAR, CUBIC, pipeline.volume); }
        set { pipeline.volume = Gst.Audio.StreamVolume.convert_volume (CUBIC, LINEAR, value); }
    }

    /* Signals */
    public signal void unsupported_file ();
    public signal void unsupported_codec (string debug_info);

    /* Private fields */
    Settings settings;

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
        pipeline.bus.message["state-changed"].connect(pipeline_state_changed_cb);

        pipeline.bind_property("flags", this, "flags", SYNC_CREATE|BIDIRECTIONAL);
        pipeline.notify["volume"].connect(()=> { notify_property("volume"); });

        notify["target-state"].connect(decide_on_progress_tracking);
        notify["current-state"].connect(decide_on_progress_tracking);
    }

    public static Playback get_default() {
        default_playback = default_playback ?? new Playback();
        return default_playback;
    }

    public void open(File[] files) {
        queue = new Daikhan.Queue(files);
        load_track(0);
    }

    public bool load_track(int track_index) {
        if (track_index < -1 || track_index >= queue.length) {
            return false;
        }

        if (track_index == current_track) {
            return true;
        }

        /* Save information of previous track */

        var desired_state = (target_state == PAUSED) ? Gst.State.PAUSED : Gst.State.PLAYING;

        if (current_record != null) {
            history.update(current_record);
        }

        /* Set current track */
        current_track = track_index;

        /* Clear information */
        set_state(READY);
        track_info.reset();
        current_record = null;
        filename = null;
        progress = -1;
        duration = -1;

        if (current_track == -1) {
            return true;
        }

        /* Load track & information */

        var file = queue[track_index];

        try {
            var info = file.query_info("standard::display-name", NONE);
            filename = info.get_display_name();
        } catch (Error err) {
            filename = file.get_basename();
        }

        if (!Daikhan.Utils.is_file_type_supported(file)) {
            set_state(NULL);
            unsupported_file();
            return false;
        }

        pipeline["uri"] = file.get_uri();

        if (!set_state(desired_state)) {
            critical("Cannot load track!");
            return false;
        }

        ulong handler_id = 0;
        handler_id = notify["current-state"].connect(() => {
            if (pipeline.current_state == PAUSED) {
                update_duration ();
                update_progress ();
                SignalHandler.disconnect (this, handler_id);
            }
        });

        current_record = new Daikhan.HistoryRecord.with_uri(file.get_uri());

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

    /* Loads the next track expected to be played in the list. In case
     * there is no track is expected to be played next, it stops playback.
     * This also implements the `queue` repeat mode.
     */
    public bool next() {
        if (current_track + 1 < queue.length) {
            return load_track(current_track + 1);
        } else if (repeat == QUEUE) {
            return load_track(0);
        } else {
            stop();
            return false;
        }
    }

    public bool prev() {
        if (current_track < 1 || queue.length == 0) {
            return false;
        }

        return load_track(current_track - 1);
    }

    public bool toggle_playing() {
        if (pipeline.target_state == PLAYING) {
            return pause();
        }

        return play();
    }

    public bool play() {
        if (pipeline.target_state >= Gst.State.PAUSED) {
            return set_state(PLAYING);
        } else if (current_track == -1 && queue.length > 0) {
            return load_track(0);
        }
        return false;
    }

    public bool pause() {
        if (pipeline.target_state == NULL) {
            return false;
        }

        return set_state(PAUSED);
    }

    public void stop() {
        load_track(-1);
    }

    public bool seek(int64 seconds) {
        var seek_pos = progress + (seconds * Gst.SECOND);
        return seek_absolute(seek_pos);
    }

    public bool seek_absolute(int64 seek_pos) {
        var seeking_method = settings.get_string("seeking-method");

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

        if (pipeline.seek_simple(TIME, seek_flags, seek_pos)) {
            progress = seek_pos;
            return true;
        }

        return false;

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

    void stop_progress_tracking() {
        if (progress_source == null || progress_source.is_destroyed()) {
            return;
        }

        var source_id = progress_source.get_id();
        Source.remove(source_id);
    }

    public bool set_state(Gst.State new_state) {
        if (pipeline.target_state == new_state) {
            return true;
        }

        if (pipeline.set_state(new_state) == FAILURE) {
            critical(@"Failed to set pipeline state to $(new_state)!");
            return false;
        }

        target_state = new_state;
        return true;
    }

    public void decide_on_progress_tracking () {
        if (pipeline.current_state == pipeline.target_state == Gst.State.PLAYING) {
            ensure_progress_tracking ();
        } else {
            stop_progress_tracking ();
        }
    }

    void pipeline_state_changed_cb (Gst.Bus bus, Gst.Message msg) {
        current_state = pipeline.current_state;
    }

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
