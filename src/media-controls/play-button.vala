public class PlayButton : Gtk.Button {
    construct {
        clicked.connect(clicked_cb);
    }

    Playback? _playback = null;
    public Playback? playback {
        get { return _playback; }
        set {
            if (_playback == value) {
                return;
            }

            _playback = value;
            _playback.bind_property("playing", this, "icon-name",
                                    BindingFlags.SYNC_CREATE,
                                    playing_to_icon_name);
        }
    }

    void toggle_playing() {
        playback.playing = !(playback.playing);
    }

    bool playing_to_icon_name (Binding binding, Value playing, ref Value icon_name) {
        var act = (bool)playing ? "pause" : "start";
        icon_name = @"media-playback-$(act)-symbolic";
        return true;
    }

    void clicked_cb() {
        toggle_playing();
    }
}
