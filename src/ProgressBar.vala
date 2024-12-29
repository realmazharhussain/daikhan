public class Daikhan.ProgressBar : Gtk.Scale {
    Daikhan.Playback playback;

    construct {
        add_css_class ("progressbar");

        adjustment.lower = 0;
        adjustment.value = 0;
        adjustment.upper = 1;
        hexpand = true;

        playback = Daikhan.Playback.get_default ();
        playback.playbin_proxy.bind_property ("duration", adjustment, "upper", SYNC_CREATE);
        playback.playbin_proxy.bind_property ("progress", adjustment, "value", SYNC_CREATE);
        playback.playbin_proxy.notify["current-state"].connect (update_sensitivity);

        update_sensitivity ();
        change_value.connect (change_value_cb);
    }

    void update_sensitivity () {
        sensitive = playback.playbin_proxy.current_state >= Gst.State.PAUSED;
    }

    double last_progress_change = 0;

    bool change_value_cb (Gtk.Range range, Gtk.ScrollType scrl_type, double value) {
        if (last_progress_change == value || value < 0 || playback.playbin_proxy.current_state < Gst.State.PAUSED) {
            return true;
        }

        last_progress_change = value;

        playback.playbin_proxy.seek_absolute ((int64) value);

        return true;
    }
}
