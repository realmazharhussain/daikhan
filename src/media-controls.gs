[indent=4]

class PlayButton : Gtk.Button
    _pipeline: Gst.Pipeline? = null
    _pipeline_state: Gst.State = Gst.State.NULL
    _pipeline_state_handler_id: ulong = 0
    _playing: bool = false

    prop playing: bool
        get
            return _playing
        set
            if _playing is value
                return
            _playing = value
            if pipeline is not null
                if _playing
                    pipeline.set_state(Gst.State.PLAYING)
                else if pipeline.current_state is Gst.State.PLAYING
                    pipeline.set_state(Gst.State.PAUSED)

    prop pipeline: Gst.Pipeline?
        get
            return _pipeline
        set
            disconnect_pipeline()
            _pipeline = value
            connect_pipeline()

    init
        bind_property("playing", self, "icon-name", BindingFlags.SYNC_CREATE, playing_to_icon_name)
        clicked.connect(clicked_cb)

    def toggle_playing ()
        playing = not(playing)

    def private playing_to_icon_name (binding: Binding, playing: Value, ref icon_name: Value): bool
        if (bool)playing
            icon_name = "media-playback-pause-symbolic"
        else
            icon_name = "media-playback-start-symbolic"
        return true

    def private clicked_cb()
        toggle_playing()

    def private on_pipeline_state_changed ()
        if _pipeline_state is pipeline.current_state
            return

        _pipeline_state = pipeline.current_state

        if _pipeline_state is Gst.State.PLAYING
            playing = true
        else if (_pipeline_state is Gst.State.PAUSED or
                 _pipeline_state is Gst.State.NULL)
            playing = false

    def private disconnect_pipeline()
        if pipeline is null
            return
        disconnect(_pipeline_state_handler_id)

    def private connect_pipeline()
        var bus = pipeline.get_bus()
        _pipeline_state_handler_id = bus.message["state-changed"].connect(on_pipeline_state_changed)
