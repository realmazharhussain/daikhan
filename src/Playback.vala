internal unowned Daikhan.Playback? default_playback;

public class Daikhan.Playback : Object {
    /* Read-Write properties */
    public Daikhan.Queue queue { get; set; default = new Daikhan.Queue (); }
    public Daikhan.RepeatMode repeat { get; set; default = OFF; }

    /* Read-only properties */
    public Daikhan.History history { get; private construct; }
    public int current_track { get; private set; default = -1; }

    /* Playback properties */
    public Daikhan.HistoryRecord? current_record { get { return playbin_proxy.current_record; } }
    public Daikhan.TrackInfo track_info { get { return playbin_proxy.track_info; }}
    public double volume { get; set; }
    public int64 progress { get { return playbin_proxy.progress; } }
    public int64 duration { get { return playbin_proxy.duration; } }
    public int n_audio { get { return playbin_proxy.n_audio; } }
    public int n_video { get { return playbin_proxy.n_video; } }
    public int n_text { get { return playbin_proxy.n_text; } }
    public int current_audio { get; set; }
    public int current_video { get; set; }
    public int current_text { get; set; }
    public string filename { get { return playbin_proxy.filename; } }
    public Gst.State current_state { get { return playbin_proxy.current_state; } }
    public Gst.State target_state { get { return playbin_proxy.target_state; } }
    public Gdk.Paintable paintable { get { return playbin_proxy.paintable; } }
    public Gst.Element pipeline { get { return playbin_proxy.pipeline; } }

    /* Signals */
    public signal void unsupported_file ();
    public signal void unsupported_codec (string debug_info);
    public signal void pipeline_error (Gst.Object source, Error error, string debug_info);

    /* Private fields */
    Settings state_mem;
    Daikhan.PlaybinProxy playbin_proxy;

    construct {
        playbin_proxy = new Daikhan.PlaybinProxy ();
        history = Daikhan.History.get_default ();

        playbin_proxy.bind_property ("volume", this, "volume", SYNC_CREATE | BIDIRECTIONAL);
        playbin_proxy.bind_property ("current-audio", this, "current-audio", SYNC_CREATE | BIDIRECTIONAL);
        playbin_proxy.bind_property ("current-video", this, "current-video", SYNC_CREATE | BIDIRECTIONAL);
        playbin_proxy.bind_property ("current-text", this, "current-text", SYNC_CREATE | BIDIRECTIONAL);

        playbin_proxy.notify["current-record"].connect (() => { notify_property ("current-record"); });
        playbin_proxy.notify["duration"].connect (() => { notify_property ("duration"); });
        playbin_proxy.notify["progress"].connect (() => { notify_property ("progress"); });
        playbin_proxy.notify["n-audio"].connect (() => { notify_property ("n-audio"); });
        playbin_proxy.notify["n-video"].connect (() => { notify_property ("n-video"); });
        playbin_proxy.notify["n-text"].connect (() => { notify_property ("n-text"); });
        playbin_proxy.notify["filename"].connect (() => { notify_property ("filename"); });
        playbin_proxy.notify["current-state"].connect (() => { notify_property ("current-state"); });
        playbin_proxy.notify["target-state"].connect (() => { notify_property ("target-state"); });

        playbin_proxy.unsupported_file.connect (() => { unsupported_file.emit (); });
        playbin_proxy.unsupported_codec.connect ((debug_info) => { unsupported_codec.emit (debug_info); });
        playbin_proxy.pipeline_error.connect ((src, err, dbg_info) => { pipeline_error.emit (src, err, dbg_info); });
        playbin_proxy.end_of_stream.connect (end_of_stream_cb);

        state_mem = new Settings (Conf.APP_ID + ".state");
        state_mem.bind ("volume", this, "volume", DEFAULT);
        state_mem.bind ("repeat", this, "repeat", DEFAULT);
    }

    public static Playback get_default () {
        default_playback = default_playback ?? new Playback ();
        return default_playback;
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
        } else if (track_index >= 0 && queue[track_index].get_uri () == (string) playbin_proxy.pipeline.current_uri) {
            current_track = track_index;
            return true;
        }

        /* Save information of previous track */

        var desired_state = (playbin_proxy.target_state == PAUSED) ? Gst.State.PAUSED : Gst.State.PLAYING;

        if (playbin_proxy.current_record != null) {
            history.update (playbin_proxy.current_record);
        }

        /* Set current track */
        current_track = track_index;

        /* Clear information */
        playbin_proxy.reset ();

        if (current_track == -1) {
            return true;
        }

        /* Load track & information */
        return playbin_proxy.open_file (queue[track_index], desired_state);
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
        if (playbin_proxy.target_state == PLAYING) {
            return pause ();
        }

        return play ();
    }

    public bool play () {
        if (playbin_proxy.target_state >= Gst.State.PAUSED) {
            return playbin_proxy.set_state (PLAYING);
        } else if (current_track == -1 && queue.length > 0) {
            return load_track (0);
        }
        return false;
    }

    public bool pause () {
        if (playbin_proxy.target_state < Gst.State.PAUSED) {
            return false;
        }

        return playbin_proxy.set_state (PAUSED);
    }

    public bool seek (int64 seconds) {
        return playbin_proxy.seek (seconds);
    }

    public bool seek_absolute (int64 seek_pos) {
        return playbin_proxy.seek_absolute (seek_pos);
    }

    public void stop () {
        load_track (-1);
    }

    void end_of_stream_cb () {
        playbin_proxy.current_record.progress = -1;

        if (repeat == TRACK) {
            playbin_proxy.seek_absolute (0);
        } else {
            next ();
        }
    }

    ~Playback () {
        stop ();
    }
}
