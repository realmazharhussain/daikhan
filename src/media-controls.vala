[GtkTemplate (ui = "/app/media-controls.ui")]
public class MediaControls : Adw.Bin {
    [GtkChild] unowned Gtk.Button prev_btn;
    [GtkChild] unowned Gtk.Button next_btn;
    [GtkChild] unowned Gtk.MenuButton streams_btn;
    unowned Playback playback;

    static construct {
        typeof(PlayButton).ensure();
        typeof(ProgressLabel).ensure();
        typeof(ProgressBar).ensure();
        typeof(DurationLabel).ensure();
        typeof(VolumeButton).ensure();
    }

    construct {
        set("css-name", "mediacontrols");

        playback = Playback.get_default ();

        playback.bind_property ("multiple-tracks", prev_btn, "visible", SYNC_CREATE);
        playback.bind_property ("can-prev", prev_btn, "sensitive", SYNC_CREATE);

        playback.bind_property ("multiple-tracks", next_btn, "visible", SYNC_CREATE);
        playback.bind_property ("can-next", next_btn, "sensitive", SYNC_CREATE);

        streams_btn.menu_model = StreamMenuBuilder.get_menu();
    }

    [GtkCallback]
    void prev_cb() {
        playback.prev();
    }

    [GtkCallback]
    void next_cb() {
        playback.next();
    }
}
