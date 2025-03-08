[GtkTemplate (ui = "/app/VolumeButton.ui")]
public class Daikhan.VolumeButton : Adw.Bin {
    [GtkChild] unowned Gtk.Adjustment adjustment;
    [GtkChild] unowned Gtk.VolumeButton volume_button;
    Daikhan.Player player;

    public bool active { get; private set; default = false; }

    static construct {
        set_css_name ("volumebutton");
    }

    construct {
        player = Daikhan.Player.get_default ();
        player.bind_property ("volume", adjustment, "value", SYNC_CREATE | BIDIRECTIONAL);
        volume_button.notify["active"].connect (() => { active = volume_button.active; });
    }
}
