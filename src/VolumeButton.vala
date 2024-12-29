[GtkTemplate (ui = "/app/VolumeButton.ui")]
public class Daikhan.VolumeButton : Adw.Bin {
    [GtkChild] unowned Gtk.Adjustment adjustment;
    Daikhan.Player player;

    static construct {
        set_css_name ("volumebutton");
    }

    construct {
        player = Daikhan.Player.get_default ();
        player.bind_property ("volume", adjustment, "value", SYNC_CREATE | BIDIRECTIONAL);
    }
}
