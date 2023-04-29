public class ProgressBar : Gtk.Scale {
    unowned Playback playback;

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
        playback.bind_property("current-state", this, "sensitive", SYNC_CREATE,
                               playback_state_to_sensitive);

        change_value.connect(change_value_cb);
    }

    bool playback_state_to_sensitive (Binding binding, Value state, ref Value sensitive) {
        sensitive = ((Gst.State) state != NULL);
        return true;
    }

    double last_progress_change = 0;

    bool change_value_cb(Gtk.Range range, Gtk.ScrollType scrl_type, double value) {
        if (last_progress_change == value || playback.pipeline == null) {
            return true;
        }

        last_progress_change = value;

        playback.seek_absolute((Gst.ClockTime) value);

        return true;
    }
}
