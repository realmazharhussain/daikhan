public class PlayButton : Gtk.Button {
    Playback playback;

    construct {
        playback = Playback.get_default();
        playback.bind_property("can_play", this, "sensitive", SYNC_CREATE);
        playback.state_requested.connect (update_icon);

        update_icon();
        clicked.connect(clicked_cb);
    }

    void update_icon () {
        var act = playback.target_state != PLAYING ? "start" : "pause";
        icon_name = @"media-playback-$(act)-symbolic";
    }

    void clicked_cb() {
        playback.toggle_playing();
    }
}
