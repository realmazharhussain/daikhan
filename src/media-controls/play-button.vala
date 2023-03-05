public class PlayButton : Gtk.Button {
    construct {
        clicked.connect(clicked_cb);
    }

    Binding? can_play_binding = null;
    Binding? playing_binding = null;
    Playback? _playback = null;
    public Playback? playback {
        get { return _playback; }
        set {
            if (_playback == value) {
                return;
            }

            if (_playback != null) {
                can_play_binding.unbind();
                playing_binding.unbind();
            }

            if (value != null) {
                can_play_binding = value.bind_property("can_play", this, "sensitive",
                                                       BindingFlags.SYNC_CREATE);
                playing_binding = value.bind_property("playing", this, "icon-name",
                                                      BindingFlags.SYNC_CREATE,
                                                      playing_to_icon_name);
            }

            _playback = value;
        }
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
