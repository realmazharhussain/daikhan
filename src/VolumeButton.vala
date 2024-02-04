[GtkTemplate (ui = "/app/VolumeButton.ui")]
public class Daikhan.VolumeButton : Adw.Bin {
    [GtkChild] unowned Gtk.Adjustment adjustment;
    Daikhan.Playback playback;

    static construct {
        set_css_name ("volumebutton");
    }

    construct {
        playback = Daikhan.Playback.get_default ();
        playback.bind_property ("volume", adjustment, "value", SYNC_CREATE | BIDIRECTIONAL);
    }
}
