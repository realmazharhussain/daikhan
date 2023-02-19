[indent=4]

[GtkTemplate (ui = "/ui/headerbar.ui")]
class HeaderBar: Adw.Bin
    init
        pass


[GtkTemplate (ui = "/ui/window.ui")]
class MainWindow : Adw.ApplicationWindow

    [GtkChild]
    video_image:    unowned Gtk.Image
    [GtkChild]
    volume_adj:     unowned Gtk.Adjustment
    [GtkChild]
    progress_adj:   unowned Gtk.Adjustment
    [GtkChild]
    progress_scale: unowned Gtk.Scale
    [GtkChild]
    play_btn:       unowned PlayButton

    playbin: Gst.Element
    volume: AudioVolume

    timeout_source_id: uint = 0
    duration: int64 = -1
    last_progress_change: double = 0

    construct (app: Gtk.Application)
        application = app

    init
        title = "Envision Media Player"

        var about_act = new SimpleAction("about", null)
        about_act.activate.connect(about_cb)
        add_action(about_act)

        playbin = Gst.ElementFactory.make("playbin", "playbin")
        if playbin is null
            print "Could not create playbin!"
            return

        play_btn.pipeline = (Gst.Pipeline)playbin

        volume = new AudioVolume()
        volume.bind_property("logarithmic", volume_adj, "value",
                             BindingFlags.SYNC_CREATE|BindingFlags.BIDIRECTIONAL)
        playbin.bind_property("volume", volume, "linear",
                              BindingFlags.SYNC_CREATE|BindingFlags.BIDIRECTIONAL)

        var bus = playbin.get_bus()
        bus.add_signal_watch()
        bus.message["eos"].connect(gst_eos_cb)
        bus.message["error"].connect(gst_error_cb)

        var gtksink = Gst.ElementFactory.make("gtk4paintablesink", "videosink")
        if gtksink is null
            print "Could not create Video Sink!"
            return

        paintable: Gdk.Paintable
        gtksink.get("paintable", out paintable)
        video_image.paintable = paintable

        gl_context: Gdk.GLContext
        paintable.get("gl-context", out gl_context)
        if gl_context is not null
            var glsink = Gst.ElementFactory.make("glsinkbin", "glsinkbin")
            glsink.set("sink", gtksink)
            playbin.set("video-sink", glsink)
        else
            playbin.set("video-sink", gtksink)

    final
        playbin.set_state(Gst.State.NULL)

    def open_file(file: File)
        if timeout_source_id is not 0
            Source.remove(timeout_source_id)
            timeout_source_id = 0

        result: int

        result = playbin.set_state(Gst.State.NULL)
        if result is Gst.StateChangeReturn.FAILURE
            printerr("Cannot reset playback!")
            return

        playbin.set("uri", file.get_uri())

        result = playbin.set_state(Gst.State.PLAYING)
        if result is Gst.StateChangeReturn.FAILURE
            printerr("Cannot play!")
            return

        timeout_source_id = Timeout.add(100, progress_update_cb)

        try
            var info = file.query_info("standard::display-name", FileQueryInfoFlags.NONE)
            title = info.get_display_name()
        except err: Error
            printerr(err.message)

    def progress_update_cb (): bool
        if duration is -1
            if not playbin.query_duration(Gst.Format.TIME, out duration)
                return true
            progress_adj.lower = 0
            progress_adj.upper = duration

        position: int64 = -1
        if not playbin.query_position(Gst.Format.TIME, out position)
            return true

        progress_adj.value = position
        progress_scale.sensitive = true

        return true

    [GtkCallback]
    def progress_scale_clicked_cb(range: Gtk.Range, scrl_type: Gtk.ScrollType, value: double): bool
        if last_progress_change is value
            return true
        last_progress_change = value

        playbin.seek_simple(Gst.Format.TIME, Gst.SeekFlags.FLUSH|Gst.SeekFlags.KEY_UNIT, (int64)value)

        return true

    def about_cb (action: SimpleAction, type: Variant?)
        show_about_window(self)

    def gst_eos_cb (bus: Gst.Bus, msg: Gst.Message)
        playbin.seek_simple(Gst.Format.TIME, Gst.SeekFlags.FLUSH|Gst.SeekFlags.KEY_UNIT, 0)
        playbin.set_state(Gst.State.PAUSED)
        //progress_scale.sensitive = false
        //if timeout_source_id is not 0
        //    Source.remove(timeout_source_id)
        //    timeout_source_id = 0

    def gst_error_cb (bus: Gst.Bus, msg: Gst.Message)
        err: Error
        debug_info: string

        msg.parse_error(out err, out debug_info)

        printerr(@"Error message received from $(msg.src.name): $(err.message)")
        printerr(@"Debugging info: $(debug_info)")
