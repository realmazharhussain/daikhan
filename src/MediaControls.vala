[GtkTemplate (ui = "/app/MediaControls.ui")]
public class Daikhan.MediaControls : Adw.Bin {
    [GtkChild] unowned Gtk.Button prev_btn;
    [GtkChild] unowned Gtk.Button next_btn;
    [GtkChild] unowned Gtk.MenuButton streams_btn;
    [GtkChild] unowned Daikhan.VolumeButton volume_button;
    Daikhan.Player player;

    public bool popover_active { get; private set; default = false; }

    static construct {
        set_css_name ("mediacontrols");

        typeof (Daikhan.PlayButton).ensure ();
        typeof (Daikhan.ProgressLabel).ensure ();
        typeof (Daikhan.ProgressBar).ensure ();
        typeof (Daikhan.DurationLabel).ensure ();
        typeof (Daikhan.VolumeButton).ensure ();
    }

    construct {
        player = Daikhan.Player.get_default ();

        player.notify["queue"].connect (update_prev_next_visibility);
        player.notify["queue"].connect (update_prev_next_sensitivity);
        player.notify["current-track"].connect (update_prev_next_sensitivity);

        streams_btn.menu_model = Daikhan.StreamMenuBuilder.get_menu ();

        volume_button.notify["active"].connect(update_overlay_visible);
        streams_btn.notify["active"].connect(update_overlay_visible);
    }

    [GtkCallback]
    void prev_cb () {
        player.prev ();
    }

    [GtkCallback]
    void next_cb () {
        player.next ();
    }

    void update_overlay_visible() {
        popover_active = volume_button.active || streams_btn.active;
    }

    void update_prev_next_visibility () {
        prev_btn.visible = next_btn.visible = player.queue.length > 1;
    }

    void update_prev_next_sensitivity () {
        prev_btn.sensitive = player.current_track > 0;
        next_btn.sensitive = 0 < player.current_track + 1 < player.queue.length;
    }
}
