public class PlayButton : Gtk.Button {
    unowned Playback playback;

    construct {
        playback = Playback.get_default();
        playback.bind_property("can_play", this, "sensitive", SYNC_CREATE);
        playback.bind_property("target-state", this, "icon-name", SYNC_CREATE,
                               playback_state_to_icon_name);

        clicked.connect(clicked_cb);
    }

    bool playback_state_to_icon_name (Binding binding, Value state, ref Value icon_name) {
        var act = (Gst.State) state != PLAYING ? "start" : "pause";
        icon_name = @"media-playback-$(act)-symbolic";
        return true;
    }

    void clicked_cb() {
        playback.toggle_playing();
    }
}
