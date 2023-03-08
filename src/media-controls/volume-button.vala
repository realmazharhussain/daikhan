[GtkTemplate (ui = "/ui/media-controls/volume-button.ui")]
public class VolumeButton : Adw.Bin {
    [GtkChild] unowned Gtk.Adjustment adjustment;
    unowned Playback playback;

    construct {
        playback = Playback.get_default();

        var flags = BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL;
        playback.bind_property("volume", adjustment, "value", flags);
        playback.bind_property("state", this, "sensitive", BindingFlags.SYNC_CREATE,
                               playback_state_to_sensitive);

    }

    bool playback_state_to_sensitive (Binding binding, Value state, ref Value sensitive) {
        sensitive = ((Gst.State)state != Gst.State.NULL);
        return true;
    }
}
