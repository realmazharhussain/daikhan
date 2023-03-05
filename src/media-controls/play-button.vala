public class PlayButton : Gtk.Button {
    unowned Playback playback;

    construct {
        clicked.connect(clicked_cb);
        notify["root"].connect(notify_root);
    }

    void notify_root() {
        assert (root is PlaybackWindow);
        playback = ((PlaybackWindow)root).playback;
        notify["root"].disconnect(notify_root);

        playback.bind_property("can_play", this, "sensitive", BindingFlags.SYNC_CREATE);
        playback.bind_property("playing", this, "icon-name", BindingFlags.SYNC_CREATE,
                               playing_to_icon_name);
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
