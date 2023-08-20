[GtkTemplate (ui = "/app/media-controls/volume-button.ui")]
public class VolumeButton : Adw.Bin {
    [GtkChild] unowned Gtk.Adjustment adjustment;
    Playback playback;

    construct {
        playback = Playback.get_default();
        playback.bind_property("volume", adjustment, "value", SYNC_CREATE|BIDIRECTIONAL);
    }
}
