[GtkTemplate (ui = "/ui/media-controls/volume-button.ui")]
public class VolumeButton : Adw.Bin {
    [GtkChild] unowned Gtk.Adjustment adjustment;

    Binding? state_binding;
    Binding? volume_binding;

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
                volume_binding.unbind();
                state_binding.unbind();
            }

            if (value != null) {
                var flags = BindingFlags.SYNC_CREATE|BindingFlags.BIDIRECTIONAL;
                volume_binding = value.bind_property("volume", adjustment, "value", flags);

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
}
