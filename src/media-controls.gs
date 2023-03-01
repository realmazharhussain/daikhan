[indent=4]

class PlayButton : Gtk.Button
    _playback: Playback? = null
    prop playback: Playback?
        get
            return _playback
        set
            _playback = value
            _playback.bind_property("playing", self, "icon-name",
                                    BindingFlags.SYNC_CREATE,
                                    playing_to_icon_name)

    init
        clicked.connect(clicked_cb)

    def toggle_playing ()
        playback.playing = not(playback.playing)

    def private playing_to_icon_name (binding: Binding, playing: Value, ref icon_name: Value): bool
        if (bool)playing
            icon_name = "media-playback-pause-symbolic"
        else
            icon_name = "media-playback-start-symbolic"
        return true

    def private clicked_cb()
        toggle_playing()
