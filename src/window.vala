[GtkTemplate (ui = "/ui/headerbar.ui")]
class HeaderBar : Adw.Bin {}


[GtkTemplate (ui = "/ui/window.ui")]
class MainWindow : Adw.ApplicationWindow {
    [GtkChild] unowned Video          video;
    [GtkChild] unowned Gtk.Adjustment volume_adj;
    [GtkChild] unowned Gtk.Adjustment progress_adj;
    [GtkChild] unowned Gtk.Scale      progress_scale;
    [GtkChild] unowned PlayButton     play_btn;

    Playback playback = new Playback();
    uint timeout_source_id = 0;
    int64 duration = -1;
    double last_progress_change = 0;

    static construct {
        typeof(HeaderBar).ensure();
        typeof(Video).ensure();
        typeof(PlayButton).ensure();
    }

    public MainWindow (Gtk.Application app) {
        application = app;

        video.playback = playback;
        play_btn.playback = playback;
        playback.notify["playing"].connect(notify_playing_cb);
        playback.bind_property("volume", volume_adj, "value",
                               BindingFlags.SYNC_CREATE|BindingFlags.BIDIRECTIONAL);

        var volume_up_act = new SimpleAction("volume_up", null);
        volume_up_act.activate.connect(volume_up_cb);
        add_action(volume_up_act);
        app.set_accels_for_action("win.volume_up", {"k"});

        var volume_down_act = new SimpleAction("volume_down", null);
        volume_down_act.activate.connect(volume_down_cb);
        add_action(volume_down_act);
        app.set_accels_for_action("win.volume_down", {"j"});

        var play_pause_act = new SimpleAction("play_pause", null);
        play_pause_act.activate.connect(play_pause_cb);
        add_action(play_pause_act);
        app.set_accels_for_action("win.play_pause", {"space"});

        var fullscreen_act = new SimpleAction("toggle_fullscreen", null);
        fullscreen_act.activate.connect(toggle_fullscreen_cb);
        add_action(fullscreen_act);
        app.set_accels_for_action("win.toggle_fullscreen", {"f"});

        var about_act = new SimpleAction("about", null);
        about_act.activate.connect(about_cb);
        add_action(about_act);
    }

    public void open_file(File file) {
        duration = -1;
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

    void volume_up_cb () {
        playback.volume += 0.05;
    }

    void volume_down_cb () {
        playback.volume -= 0.05;
    }

    void play_pause_cb () {
        playback.playing = !playback.playing;
    }

    void toggle_fullscreen_cb () {
        fullscreened = !fullscreened;
    }

    [GtkCallback]
    void notify_fullscreened_cb() {
        var cursor_name = fullscreened ? "none": "default";
        set_cursor_from_name(cursor_name);
    }

    void about_cb () {
        show_about_window(this);
    }
}
