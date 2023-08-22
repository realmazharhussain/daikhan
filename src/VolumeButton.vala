[GtkTemplate (ui = "/app/VolumeButton.ui")]
public class Daikhan.VolumeButton : Adw.Bin {
    [GtkChild] unowned Gtk.Adjustment adjustment;
    Daikhan.Playback playback;

    construct {
        playback = Daikhan.Playback.get_default();
        playback.bind_property("volume", adjustment, "value", SYNC_CREATE|BIDIRECTIONAL);
    }
}
