public class PlayButton : Gtk.Button {
    Playback playback;

    construct {
        playback = Playback.get_default();
        playback.bind_property("can_play", this, "sensitive", SYNC_CREATE);
        playback.notify["target-state"].connect (update_icon);

        update_icon();
        clicked.connect(clicked_cb);
    }

    void update_icon () {
        if (playback.pipeline.target_state == PLAYING) {
            icon_name = "media-playback-pause-symbolic";
        } else {
            icon_name = "media-playback-start-symbolic";
        }
    }

    void clicked_cb() {
        playback.toggle_playing();
    }
}
