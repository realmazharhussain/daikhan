public class ProgressBar : Gtk.Scale {
    construct {
        adjustment.lower = 0;
        adjustment.value = 0;
        adjustment.upper = 1;
        hexpand = true;

        change_value.connect(change_value_cb);
    }

    Binding? duration_binding;
    Binding? progress_binding;
    Binding? state_binding;

    private Playback? _playback;
    public Playback? playback {
        get {
            return _playback;
        }

        set {
            if (value == _playback) {
                return;
            }

            if (_playback != null) {
                duration_binding.unbind();
                progress_binding.unbind();
                state_binding.unbind();
            }

            if (value != null) {
                duration_binding = value.bind_property("duration", adjustment, "upper",
                                                       BindingFlags.SYNC_CREATE);
                progress_binding = value.bind_property("progress", adjustment, "value",
                                                       BindingFlags.SYNC_CREATE);
                state_binding = value.bind_property("state", this, "sensitive",
                                                    BindingFlags.SYNC_CREATE,
                                                    playback_state_to_sensitive);
            }

            _playback = value;
        }
    }

    bool playback_state_to_sensitive (Binding binding, Value state, ref Value sensitive) {
        sensitive = ((Gst.State)state != Gst.State.NULL);
        return true;
    }

    double last_progress_change = 0;

    bool change_value_cb(Gtk.Range range, Gtk.ScrollType scrl_type, double value) {
        if (last_progress_change == value || playback.pipeline == null) {
            return true;
        }

        last_progress_change = value;

        playback.pipeline.seek_simple(
            Gst.Format.TIME,
            Gst.SeekFlags.FLUSH|Gst.SeekFlags.KEY_UNIT,
            (int64)value
        );

        return true;
    }
}
