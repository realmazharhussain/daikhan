[indent=4]

[Flags]
enum Gst.PlayFlags
    VIDEO
    AUDIO
    SUBTITLES


class Playback: Object
    _pipeline: Gst.Pipeline?
    _pipeline_state: Gst.State = Gst.State.NULL
    _pipeline_state_handler_id: ulong = 0
    _playing: bool = false

    prop pipeline: Gst.Pipeline?
        get
            return _pipeline
        set
            disconnect_pipeline()
            _pipeline = value
            connect_pipeline()

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

    init
        pipeline = (Gst.Pipeline) Gst.ElementFactory.make("playbin", null)
        if pipeline is null
            print "Could not create pipeline!"
            return

        var bus = pipeline.get_bus()
        bus.add_signal_watch()
        bus.message["eos"].connect(gst_eos_cb)
        bus.message["error"].connect(gst_error_cb)

        // Disable Subtitles
        play_flags: Gst.PlayFlags
        pipeline.get("flags", out play_flags)
        play_flags &= ~Gst.PlayFlags.SUBTITLES
        pipeline.set("flags", play_flags)

    final
        pipeline.set_state(Gst.State.NULL)

    def open_file(file: File): bool
        result: int

        result = pipeline.set_state(Gst.State.NULL)
        if result is Gst.StateChangeReturn.FAILURE
            printerr("Cannot reset playback!")
            return false

        pipeline.set("uri", file.get_uri())

        result = pipeline.set_state(Gst.State.PLAYING)
        if result is Gst.StateChangeReturn.FAILURE
            printerr("Cannot play!")
            return false
        
        return true

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

    def gst_eos_cb (bus: Gst.Bus, msg: Gst.Message)
        pipeline.seek_simple(Gst.Format.TIME, Gst.SeekFlags.FLUSH|Gst.SeekFlags.KEY_UNIT, 0)
        pipeline.set_state(Gst.State.PAUSED)

    def gst_error_cb (bus: Gst.Bus, msg: Gst.Message)
        err: Error
        debug_info: string

        msg.parse_error(out err, out debug_info)

        printerr(@"Error message received from $(msg.src.name): $(err.message)")
        printerr(@"Debugging info: $(debug_info)")
