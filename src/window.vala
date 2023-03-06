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

    construct {
        ActionEntry[] entries = {
            {"volume_step", volume_step_cb, "d"},
            {"play_pause", play_pause_cb},
            {"toggle_fullscreen", toggle_fullscreen_cb},
            {"about", about_cb},
        };

        add_action_entries(entries, this);
        playback.notify["playing"].connect(notify_playing_cb);
    }

    public PlayerWindow (Gtk.Application app) {
        application = app;

        app.set_accels_for_action("win.toggle_fullscreen", {"f"});
        app.set_accels_for_action("win.play_pause", {"space"});
        app.set_accels_for_action("win.volume_step(+0.05)", {"Up", "k"});
        app.set_accels_for_action("win.volume_step(-0.05)", {"Down", "j"});
        app.set_accels_for_action("win.volume_step(+0.01)", {"<Shift>Up", "<Shift>k"});
        app.set_accels_for_action("win.volume_step(-0.01)", {"<Shift>Down", "<Shift>j"});
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

    void volume_step_cb (SimpleAction action, Variant? step) {
        playback.volume += step.get_double();
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
