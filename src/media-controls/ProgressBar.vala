public class ProgressBar : Gtk.Scale {
    Playback playback;

    construct {
        adjustment.lower = 0;
        adjustment.value = 0;
        adjustment.upper = 1;
        hexpand = true;

        add_css_class("progress");

        var trough = get_first_child();
        trough.overflow = HIDDEN;

        playback = Playback.get_default();
        playback.bind_property("duration", adjustment, "upper", SYNC_CREATE);
        playback.bind_property("progress", adjustment, "value", SYNC_CREATE);
        playback.notify["current-state"].connect(update_sensitivity);

        update_sensitivity ();
        change_value.connect(change_value_cb);
    }

    void update_sensitivity () {
        sensitive = playback.current_state >= Gst.State.PAUSED;
    }

    double last_progress_change = 0;

    bool change_value_cb(Gtk.Range range, Gtk.ScrollType scrl_type, double value) {
        if (last_progress_change == value || value < 0 || playback.current_state < Gst.State.PAUSED) {
            return true;
        }

        last_progress_change = value;

        playback.seek_absolute((int64) value);

        return true;
    }
}
