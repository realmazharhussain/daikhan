public class PlayButton : Gtk.Button {
    unowned Playback playback;

    construct {
        playback = Playback.get_default();
        playback.bind_property("can_play", this, "sensitive", SYNC_CREATE);
        playback.bind_property("playing", this, "icon-name", SYNC_CREATE,
                               playing_to_icon_name);

        clicked.connect(clicked_cb);
    }

    bool playing_to_icon_name (Binding binding, Value playing, ref Value icon_name) {
        var act = (bool)playing ? "pause" : "start";
        icon_name = @"media-playback-$(act)-symbolic";
        return true;
    }

    void clicked_cb() {
        playback.toggle_playing();
    }
}
