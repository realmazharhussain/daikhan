[indent=4]

[GtkTemplate (ui = "/ui/headerbar.ui")]
class HeaderBar: Adw.Bin
    init
        pass


[GtkTemplate (ui = "/ui/window.ui")]
class MainWindow : Adw.ApplicationWindow

    [GtkChild]
    video:          unowned Gtk.Picture
    [GtkChild]
    volume_adj:     unowned Gtk.Adjustment
    [GtkChild]
    progress_adj:   unowned Gtk.Adjustment
    [GtkChild]
    progress_scale: unowned Gtk.Scale
    [GtkChild]
    play_btn:       unowned PlayButton

    playback: Playback = new Playback()
    volume: AudioVolume = new AudioVolume()

    timeout_source_id: uint = 0
    duration: int64 = -1
    last_progress_change: double = 0

    construct (app: Gtk.Application)
        application = app

    init
        var fullscreen_act = new SimpleAction("toggle_fullscreen", null)
        fullscreen_act.activate.connect(toggle_fullscreen_cb)
        add_action(fullscreen_act)

        var about_act = new SimpleAction("about", null)
        about_act.activate.connect(about_cb)
        add_action(about_act)

        play_btn.playback = playback

        volume.bind_property("logarithmic", volume_adj, "value",
                             BindingFlags.SYNC_CREATE|BindingFlags.BIDIRECTIONAL)
        playback.pipeline.bind_property("volume", volume, "linear",
                             BindingFlags.SYNC_CREATE|BindingFlags.BIDIRECTIONAL)

        var gtksink = Gst.ElementFactory.make("gtk4paintablesink", "videosink")
        if gtksink is null
            print "Could not create Video Sink!"
            return

        paintable: Gdk.Paintable
        gtksink.get("paintable", out paintable)
        video.paintable = paintable

        gl_context: Gdk.GLContext
        paintable.get("gl-context", out gl_context)
        if gl_context is not null
            var glsink = Gst.ElementFactory.make("glsinkbin", "glsinkbin")
            glsink.set("sink", gtksink)
            playback.pipeline.set("video-sink", glsink)
        else
            playback.pipeline.set("video-sink", gtksink)

    def open_file(file: File)
        if timeout_source_id is not 0
            Source.remove(timeout_source_id)
            timeout_source_id = 0
        
        if not playback.open_file(file)
            return

        timeout_source_id = Timeout.add(100, progress_update_cb)

        try
            var info = file.query_info("standard::display-name", FileQueryInfoFlags.NONE)
            title = info.get_display_name()
        except err: Error
            printerr(err.message)

    def progress_update_cb (): bool
        if duration is -1
            if not playback.pipeline.query_duration(Gst.Format.TIME, out duration)
                return true
            progress_adj.lower = 0
            progress_adj.upper = duration

        position: int64 = -1
        if not playback.pipeline.query_position(Gst.Format.TIME, out position)
            return true

        progress_adj.value = position
        progress_scale.sensitive = true

        return true

    [GtkCallback]
    def progress_scale_clicked_cb(range: Gtk.Range, scrl_type: Gtk.ScrollType, value: double): bool
        if last_progress_change is value
            return true
        last_progress_change = value

        playback.pipeline.seek_simple(Gst.Format.TIME, Gst.SeekFlags.FLUSH|Gst.SeekFlags.KEY_UNIT, (int64)value)

        return true

    def toggle_fullscreen_cb (action: SimpleAction, type: Variant?)
        fullscreened = not(fullscreened)

    [GtkCallback]
    def notify_fullscreened_cb ()
        var cursor_name = fullscreened ? "none": "default"
        set_cursor_from_name(cursor_name)

    def about_cb (action: SimpleAction, type: Variant?)
        show_about_window(self)
