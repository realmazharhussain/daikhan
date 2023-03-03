[GtkTemplate (ui = "/ui/headerbar.ui")]
class HeaderBar : Adw.Bin {}


[GtkTemplate (ui = "/ui/window.ui")]
class MainWindow : Adw.ApplicationWindow {
    [GtkChild] unowned Gtk.Picture    video;
    [GtkChild] unowned Gtk.Adjustment volume_adj;
    [GtkChild] unowned Gtk.Adjustment progress_adj;
    [GtkChild] unowned Gtk.Scale      progress_scale;
    [GtkChild] unowned PlayButton     play_btn;

    Playback    playback = new Playback();
    AudioVolume volume   = new AudioVolume();

    uint timeout_source_id = 0;
    int64 duration = -1;
    double last_progress_change = 0;

    static construct {
        typeof(HeaderBar).ensure();
        typeof(PlayButton).ensure();
    }

    public MainWindow (Gtk.Application app) {
        application = app;

        var fullscreen_act = new SimpleAction("toggle_fullscreen", null);
        fullscreen_act.activate.connect(toggle_fullscreen_cb);
        add_action(fullscreen_act);
        app.set_accels_for_action("win.toggle_fullscreen", {"f"});

        var about_act = new SimpleAction("about", null);
        about_act.activate.connect(about_cb);
        add_action(about_act);

        play_btn.playback = playback;

        volume.bind_property("logarithmic", volume_adj, "value",
                             BindingFlags.SYNC_CREATE|BindingFlags.BIDIRECTIONAL);
        playback.pipeline.bind_property("volume", volume, "linear",
                             BindingFlags.SYNC_CREATE|BindingFlags.BIDIRECTIONAL);

        var gtksink = Gst.ElementFactory.make("gtk4paintablesink", "videosink");
        if (gtksink == null) {
            printerr("Could not create Video Sink!");
            return;
        }

        Gdk.Paintable paintable;
        gtksink.get("paintable", out paintable);
        video.paintable = paintable;

        Gdk.GLContext gl_context;
        paintable.get("gl-context", out gl_context);
        if (gl_context != null) {
            var glsink = Gst.ElementFactory.make("glsinkbin", "glsinkbin");
            glsink.set("sink", gtksink);
            playback.pipeline.set("video-sink", glsink);
        }
        else {
            playback.pipeline.set("video-sink", gtksink);
        }

        playback.notify["playing"].connect(notify_playing_cb);
    }

    public void open_file(File file) {
        if (timeout_source_id != 0) {
            Source.remove(timeout_source_id);
            timeout_source_id = 0;
        }
        
        if (!(playback.open_file(file))) return;

        timeout_source_id = Timeout.add(100, progress_update_cb);

        try {
            var info = file.query_info("standard::display-name", FileQueryInfoFlags.NONE);
            title = info.get_display_name();
        } catch (Error err) {
            printerr(err.message);
        }
    }

    uint inhibit_id = 0;
    void notify_playing_cb() {
        if (playback.playing) {
            inhibit_id = application.inhibit(this, Gtk.ApplicationInhibitFlags.IDLE,
                                             "Media is playing");
        } else {
            application.uninhibit(inhibit_id);

        }
    }

    bool progress_update_cb() {
        if (duration == -1) {
            if (!(playback.pipeline.query_duration(Gst.Format.TIME, out duration))) {
                return true;
            }
            progress_adj.lower = 0;
            progress_adj.upper = duration;
        }

        int64 position = -1;
        if (!(playback.pipeline.query_position(Gst.Format.TIME, out position))) {
            return true;
        }

        progress_adj.value = position;
        progress_scale.sensitive = true;

        return true;
    }

    [GtkCallback]
    bool progress_scale_clicked_cb(Gtk.Range      range,
                                   Gtk.ScrollType scrl_type,
                                   double         value)
    {
        if (last_progress_change == value) {
            return true;
        }
        last_progress_change = value;

        playback.pipeline.seek_simple(
            Gst.Format.TIME,
            Gst.SeekFlags.FLUSH|Gst.SeekFlags.KEY_UNIT,
            (int64)value
        );

        return true;
    }

    void toggle_fullscreen_cb (SimpleAction action, Variant? type) {
        fullscreened = !fullscreened;
    }

    [GtkCallback]
    void notify_fullscreened_cb() {
        var cursor_name = fullscreened ? "none": "default";
        set_cursor_from_name(cursor_name);
    }

    void about_cb (SimpleAction action, Variant? type) {
        show_about_window(this);
    }
}
