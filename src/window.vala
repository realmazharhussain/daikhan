[GtkTemplate (ui = "/ui/headerbar.ui")]
class HeaderBar : Adw.Bin {
    public string title { get; set construct; default = ""; }
}


[GtkTemplate (ui = "/ui/window.ui")]
class MainWindow : Adw.ApplicationWindow {
    [GtkChild] unowned HeaderBar      headerbar;
    [GtkChild] unowned Video          video;
    [GtkChild] unowned Gtk.Adjustment volume_adj;
    [GtkChild] unowned Gtk.Adjustment progress_adj;
    [GtkChild] unowned Gtk.Scale      progress_scale;
    [GtkChild] unowned PlayButton     play_btn;

    Playback playback;
    double last_progress_change = 0;

    static construct {
        typeof(HeaderBar).ensure();
        typeof(Video).ensure();
        typeof(PlayButton).ensure();
    }

    public MainWindow (Gtk.Application app) {
        application = app;

        playback = new Playback();
        playback.notify["playing"].connect(notify_playing_cb);

        video.playback = playback;
        play_btn.playback = playback;

        playback.bind_property("duration", progress_adj, "upper", BindingFlags.SYNC_CREATE);
        playback.bind_property("progress", progress_adj, "value", BindingFlags.SYNC_CREATE);
        playback.bind_property("volume", volume_adj, "value",
                               BindingFlags.SYNC_CREATE|BindingFlags.BIDIRECTIONAL);
        playback.bind_property("state", progress_scale, "sensitive", BindingFlags.SYNC_CREATE,
                               (binding, state, ref sensitive) => {
                                    sensitive = (state != Gst.State.NULL);
                                    return true;
                               });
        playback.bind_property("title", headerbar, "title", BindingFlags.SYNC_CREATE,
                               (binding, playback_title, ref headerbar_title) => {
                                    if (playback_title != "") {
                                        headerbar_title = playback_title;
                                    } else {
                                        headerbar_title = this.title;
                                    }
                                    return true;
                               });

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

    public bool open_file(File file) {
        return playback.open_file(file);
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
        playback.toggle_playing();
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
