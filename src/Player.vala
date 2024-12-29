internal unowned Daikhan.Player? default_player;

public class Daikhan.Player : Object {
    /* Read-Write properties */
    public Daikhan.Queue queue { get; set; default = new Daikhan.Queue (); }
    public Daikhan.RepeatMode repeat { get; set; default = OFF; }

    /* Read-only properties */
    public Daikhan.History history { get; private construct; }
    public int current_track { get; private set; default = -1; }

    /* Playback properties */
    public Daikhan.HistoryRecord? current_record { get { return playback.current_record; } }
    public Daikhan.TrackInfo track_info { get { return playback.track_info; }}
    public double volume { get; set; }
    public int64 progress { get { return playback.progress; } }
    public int64 duration { get { return playback.duration; } }
    public int n_audio { get { return playback.n_audio; } }
    public int n_video { get { return playback.n_video; } }
    public int n_text { get { return playback.n_text; } }
    public int current_audio { get; set; }
    public int current_video { get; set; }
    public int current_text { get; set; }
    public string filename { get { return playback.filename; } }
    public Gst.State current_state { get { return playback.current_state; } }
    public Gst.State target_state { get { return playback.target_state; } }
    public Gdk.Paintable paintable { get { return playback.paintable; } }
    public Gst.Element pipeline { get { return playback.pipeline; } }

    /* Signals */
    public signal void unsupported_file ();
    public signal void unsupported_codec (string debug_info);
    public signal void pipeline_error (Gst.Object source, Error error, string debug_info);

    /* Private fields */
    Settings state_mem;
    Daikhan.Playback playback;

    construct {
        playback = new Daikhan.Playback ();
        history = Daikhan.History.get_default ();

        playback.bind_property ("volume", this, "volume", SYNC_CREATE | BIDIRECTIONAL);
        playback.bind_property ("current-audio", this, "current-audio", SYNC_CREATE | BIDIRECTIONAL);
        playback.bind_property ("current-video", this, "current-video", SYNC_CREATE | BIDIRECTIONAL);
        playback.bind_property ("current-text", this, "current-text", SYNC_CREATE | BIDIRECTIONAL);

        playback.notify["current-record"].connect (() => { notify_property ("current-record"); });
        playback.notify["duration"].connect (() => { notify_property ("duration"); });
        playback.notify["progress"].connect (() => { notify_property ("progress"); });
        playback.notify["n-audio"].connect (() => { notify_property ("n-audio"); });
        playback.notify["n-video"].connect (() => { notify_property ("n-video"); });
        playback.notify["n-text"].connect (() => { notify_property ("n-text"); });
        playback.notify["filename"].connect (() => { notify_property ("filename"); });
        playback.notify["current-state"].connect (() => { notify_property ("current-state"); });
        playback.notify["target-state"].connect (() => { notify_property ("target-state"); });

        playback.unsupported_file.connect (() => { unsupported_file.emit (); });
        playback.unsupported_codec.connect ((debug_info) => { unsupported_codec.emit (debug_info); });
        playback.pipeline_error.connect ((src, err, dbg_info) => { pipeline_error.emit (src, err, dbg_info); });
        playback.end_of_stream.connect (end_of_stream_cb);

        state_mem = new Settings (Conf.APP_ID + ".state");
        state_mem.bind ("volume", this, "volume", DEFAULT);
        state_mem.bind ("repeat", this, "repeat", DEFAULT);
    }

    public static Player get_default () {
        default_player = default_player ?? new Player ();
        return default_player;
    }

    public void open (File[] files) {
        queue = new Daikhan.Queue (files);
        load_track (0);
    }

    public bool load_track (int track_index) {
        if (track_index < -1 || track_index >= queue.length) {
            return false;
        } else if (track_index == current_track == -1) {
            return true;
        } else if (track_index >= 0 && queue[track_index].get_uri () == (string) playback.pipeline.current_uri) {
            current_track = track_index;
            return true;
        }

        /* Save information of previous track */

        var desired_state = (playback.target_state == PAUSED) ? Gst.State.PAUSED : Gst.State.PLAYING;

        if (playback.current_record != null) {
            history.update (playback.current_record);
        }

        /* Set current track */
        current_track = track_index;

        /* Clear information */
        playback.reset ();

        if (current_track == -1) {
            return true;
        }

        /* Load track & information */
        return playback.open_file (queue[track_index], desired_state);
    }

    /* Loads the next track expected to be played in the list. In case
     * there is no track is expected to be played next, it stops playback.
     * This also implements the `queue` repeat mode.
     */
    public bool next () {
        if (current_track + 1 < queue.length) {
            return load_track (current_track + 1);
        } else if (repeat == QUEUE) {
            return load_track (0);
        } else {
            stop ();
            return false;
        }
    }

    public bool prev () {
        if (current_track < 1 || queue.length == 0) {
            return false;
        }

        return load_track (current_track - 1);
    }

    public bool toggle_playing () {
        if (playback.target_state == PLAYING) {
            return pause ();
        }

        return play ();
    }

    public bool play () {
        if (playback.target_state >= Gst.State.PAUSED) {
            return playback.set_state (PLAYING);
        } else if (current_track == -1 && queue.length > 0) {
            return load_track (0);
        }
        return false;
    }

    public bool pause () {
        if (playback.target_state < Gst.State.PAUSED) {
            return false;
        }

        return playback.set_state (PAUSED);
    }

    public bool seek (int64 seconds) {
        return playback.seek (seconds);
    }

    public bool seek_absolute (int64 seek_pos) {
        return playback.seek_absolute (seek_pos);
    }

    public void stop () {
        load_track (-1);
    }

    void end_of_stream_cb () {
        playback.current_record.progress = -1;

        if (repeat == TRACK) {
            playback.seek_absolute (0);
        } else {
            next ();
        }
    }

    ~Player () {
        stop ();
    }
}
