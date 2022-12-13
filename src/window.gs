[indent=4]

[GtkTemplate (ui = "/ui/headerbar.ui")]
class HeaderBar: Adw.Bin
    init
        pass

[GtkTemplate (ui = "/ui/window.ui")]
class MainWindow : Adw.ApplicationWindow

    [GtkChild]
    video_image: unowned Gtk.Image
    [GtkChild]
    volume_adj:  unowned Gtk.Adjustment

    _playbin: Gst.Element

    construct (app: Gtk.Application)
        application = app

    init
        title = "Envision Media Player"

        var about_act = new SimpleAction("about", null)
        about_act.activate.connect(about_cb)
        add_action(about_act)

        _playbin = Gst.ElementFactory.make("playbin", "playbin")
        if _playbin is null
            print "Could not create playbin!"
            return

        _playbin.bind_property("volume", volume_adj, "value", BindingFlags.SYNC_CREATE|BindingFlags.BIDIRECTIONAL)

        var bus = _playbin.get_bus()
        bus.add_signal_watch()
        bus.message["error"].connect(gst_error_cb)

        var videosink = Gst.ElementFactory.make("gtk4paintablesink", "videosink")
        if videosink is null
            print "Could not create Video Sink!"
            return

        paintable: Gdk.Paintable
        videosink.get("paintable", out paintable)
        video_image.paintable = paintable

        _playbin.set("uri", "file:///mnt/Data/gitapps/skipper/build/src/test.mp4",
                    "video-sink", videosink)

        var result = _playbin.set_state(Gst.State.PLAYING)
        if result is Gst.StateChangeReturn.FAILURE
            printerr("Cannot play!")
            return

    final
        _playbin.set_state(Gst.State.NULL)

    def about_cb (action: SimpleAction, type: Variant?)
        show_about_window(self)

    def static gst_error_cb (bus: Gst.Bus, msg: Gst.Message)
        err: Error
        debug_info: string

        msg.parse_error(out err, out debug_info)

        printerr(@"Error message received from $(msg.src.name): $(err.message)")
        printerr(@"Debugging info: $(debug_info)")
