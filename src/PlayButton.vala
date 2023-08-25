public class Daikhan.PlayButton : Gtk.Button {
    Daikhan.Playback playback;

    construct {
        playback = Daikhan.Playback.get_default ();
        playback.notify["target-state"].connect (update_icon);
        playback.notify["queue"].connect (update_sensitivity);

        update_icon ();
        update_sensitivity ();
        clicked.connect (clicked_cb);
    }

    void update_icon () {
        if (playback.target_state == PLAYING) {
            icon_name = "media-playback-pause-symbolic";
        } else {
            icon_name = "media-playback-start-symbolic";
        }
    }

    void update_sensitivity () {
        sensitive = playback.queue.length > 0;
    }

    void clicked_cb () {
        playback.toggle_playing ();
    }
}
