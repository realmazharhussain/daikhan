[GtkTemplate (ui = "/app/media-controls.ui")]
public class MediaControls : Adw.Bin {
    [GtkChild] unowned Gtk.Button prev_btn;
    [GtkChild] unowned Gtk.Button next_btn;
    [GtkChild] unowned Gtk.MenuButton streams_btn;
    Playback playback;

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

        playback.notify["queue"].connect (notify_queue_cb);

        playback.bind_property ("can-prev", prev_btn, "sensitive", SYNC_CREATE);
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

    void notify_queue_cb () {
        prev_btn.visible = next_btn.visible = (playback.queue != null && playback.queue.length > 1);
    }
}
