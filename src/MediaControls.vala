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
        playback.notify["current-track"].connect (notify_current_track_cb);

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
        prev_btn.visible = next_btn.visible = playback.queue.length > 1;
    }

    void notify_current_track_cb () {
        prev_btn.sensitive = playback.current_track > 0;
        next_btn.sensitive = 0 < playback.current_track + 1 < playback.queue.length;
    }
}
