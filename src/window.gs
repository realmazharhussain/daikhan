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

    playbin: Gst.Element

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

        playbin.bind_property("volume", volume_adj, "value", BindingFlags.SYNC_CREATE|BindingFlags.BIDIRECTIONAL)

        var bus = playbin.get_bus()
        bus.add_signal_watch()
        bus.message["error"].connect(gst_error_cb)

        var gtksink = Gst.ElementFactory.make("gtk4paintablesink", "videosink")
        if gtksink is null
            print "Could not create Video Sink!"
            return

        paintable: Gdk.Paintable
        gtksink.get("paintable", out paintable)
        video_image.paintable = paintable

        playbin.set("uri", "file:///mnt/Data/gitapps/skipper/build/src/test.mp4")

        gl_context: Gdk.GLContext
        paintable.get("gl-context", out gl_context)
        if gl_context is not null
            var glsink = Gst.ElementFactory.make("glsinkbin", "glsinkbin")
            glsink.set("sink", gtksink)
            playbin.set("video-sink", glsink)
        else
            playbin.set("video-sink", gtksink)

        var result = playbin.set_state(Gst.State.PLAYING)
        if result is Gst.StateChangeReturn.FAILURE
            printerr("Cannot play!")
            return

    final
        playbin.set_state(Gst.State.NULL)

    def about_cb (action: SimpleAction, type: Variant?)
        show_about_window(self)

    def static gst_error_cb (bus: Gst.Bus, msg: Gst.Message)
        err: Error
        debug_info: string

        msg.parse_error(out err, out debug_info)

        printerr(@"Error message received from $(msg.src.name): $(err.message)")
        printerr(@"Debugging info: $(debug_info)")
