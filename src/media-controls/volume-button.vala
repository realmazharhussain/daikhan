[GtkTemplate (ui = "/ui/media-controls/volume-button.ui")]
public class VolumeButton : Adw.Bin {
    [GtkChild] unowned Gtk.Adjustment adjustment;
    unowned Playback playback;

    construct {
        playback = Playback.get_default();
        playback.bind_property("volume", adjustment, "value", SYNC_CREATE|BIDIRECTIONAL);
        playback.bind_property("current-state", this, "sensitive", SYNC_CREATE,
                               playback_state_to_sensitive);

    }

    bool playback_state_to_sensitive (Binding binding, Value state, ref Value sensitive) {
        sensitive = ((Gst.State) state != NULL);
        return true;
    }
}
