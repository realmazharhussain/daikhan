public class Daikhan.ProgressBar : Gtk.Scale {
    Daikhan.Player player;

    construct {
        add_css_class ("progressbar");

        adjustment.lower = 0;
        adjustment.value = 0;
        adjustment.upper = 1;
        hexpand = true;

        player = Daikhan.Player.get_default ();
        player.bind_property ("duration", adjustment, "upper", SYNC_CREATE);
        player.bind_property ("progress", adjustment, "value", SYNC_CREATE);
        player.notify["current-state"].connect (update_sensitivity);

        update_sensitivity ();
        change_value.connect (change_value_cb);
    }

    void update_sensitivity () {
        sensitive = player.current_state >= Gst.State.PAUSED;
    }

    double last_progress_change = 0;

    bool change_value_cb (Gtk.Range range, Gtk.ScrollType scrl_type, double value) {
        if (last_progress_change == value || value < 0 || player.current_state < Gst.State.PAUSED) {
            return true;
        }

        last_progress_change = value;

        player.seek_absolute ((int64) value);

        return true;
    }
}
