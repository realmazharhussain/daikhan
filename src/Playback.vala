internal unowned Daikhan.Playback? default_playback;

public class Daikhan.Playback : Daikhan.PlaybinProxy {
    /* Read-Write properties */
    public Daikhan.Queue queue { get; set; default = new Daikhan.Queue(); }
    public Daikhan.RepeatMode repeat { get; set; default = OFF; }

    /* Read-only properties */
    public Daikhan.History history { get; private construct; }
    public Daikhan.HistoryRecord? current_record { get; private set; default = null; }
    public Daikhan.TrackInfo track_info { get; private construct; }
    public int current_track { get; private set; default = -1; }
    public string? filename { get; private set; }
    public int64 progress { get; private set; default = -1; }
    public int64 duration { get; private set; default = -1; }

    /* Signals */
    public signal void unsupported_file ();

    /* Private fields */
    Settings settings;

    construct {
        track_info = new Daikhan.TrackInfo(pipeline);
        settings = new Settings(Conf.APP_ID);
        history = Daikhan.History.get_default();

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
            if (current_state == desired_state) {
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
        if (target_state == PLAYING) {
            return pause();
        }

        return play();
    }

    public bool play() {
        if (target_state >= Gst.State.PAUSED) {
            return set_state(PLAYING);
        } else if (current_track == -1 && queue.length > 0) {
            return load_track(0);
        }
        return false;
    }

    public bool pause() {
        if (target_state < Gst.State.PAUSED) {
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

    public void decide_on_progress_tracking () {
        if (current_state == target_state == Gst.State.PLAYING) {
            ensure_progress_tracking ();
        } else {
            stop_progress_tracking ();
        }
    }

    public override void end_of_stream () {
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
