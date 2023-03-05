[GtkTemplate (ui = "/ui/window.ui")]
class PlayerWindow : Adw.ApplicationWindow, PlaybackWindow {
    private Playback _playback;
    public Playback playback {
        get {
            _playback = _playback ?? new Playback();
            return _playback;
        }
    }

    static construct {
        typeof(HeaderBar).ensure();
        typeof(Video).ensure();
        typeof(MediaControls).ensure();
    }

    public PlayerWindow (Gtk.Application app) {
        application = app;

        playback.notify["playing"].connect(notify_playing_cb);

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
