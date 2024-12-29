internal unowned Daikhan.Playback? default_playback;

public class Daikhan.Playback : Object {
    /* Read-Write properties */
    public Daikhan.Queue queue { get; set; default = new Daikhan.Queue (); }
    public Daikhan.RepeatMode repeat { get; set; default = OFF; }

    /* Read-only properties */
    public Daikhan.History history { get; private construct; }
    public int current_track { get; private set; default = -1; }

    /* Private fields */
    Settings state_mem;
    public Daikhan.PlaybinProxy playbin_proxy;

    construct {
        playbin_proxy = new Daikhan.PlaybinProxy ();
        history = Daikhan.History.get_default ();

        playbin_proxy.end_of_stream.connect (end_of_stream_cb);

        state_mem = new Settings (Conf.APP_ID + ".state");
        state_mem.bind ("volume", playbin_proxy, "volume", DEFAULT);
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
