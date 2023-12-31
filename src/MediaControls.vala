[GtkTemplate (ui = "/app/MediaControls.ui")]
public class Daikhan.MediaControls : Adw.Bin {
    [GtkChild] unowned Gtk.Button prev_btn;
    [GtkChild] unowned Gtk.Button next_btn;
    [GtkChild] unowned Gtk.MenuButton streams_btn;
    Daikhan.Playback playback;

    static construct {
        set_css_name ("mediacontrols");

        typeof (Daikhan.PlayButton).ensure ();
        typeof (Daikhan.ProgressLabel).ensure ();
        typeof (Daikhan.ProgressBar).ensure ();
        typeof (Daikhan.DurationLabel).ensure ();
        typeof (Daikhan.VolumeButton).ensure ();
    }

    construct {
        playback = Daikhan.Playback.get_default ();

        playback.notify["queue"].connect (update_prev_next_visibility);
        playback.notify["queue"].connect (update_prev_next_sensitivity);
        playback.notify["current-track"].connect (update_prev_next_sensitivity);

        streams_btn.menu_model = Daikhan.StreamMenuBuilder.get_menu ();
    }

    [GtkCallback]
    void prev_cb () {
        playback.prev ();
    }

    [GtkCallback]
    void next_cb () {
        playback.next ();
    }

    void update_prev_next_visibility () {
        prev_btn.visible = next_btn.visible = playback.queue.length > 1;
    }

    void update_prev_next_sensitivity () {
        prev_btn.sensitive = playback.current_track > 0;
        next_btn.sensitive = 0 < playback.current_track + 1 < playback.queue.length;
    }
}
