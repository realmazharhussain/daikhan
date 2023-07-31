class MediaPlayer : Adw.Application {
    PlaybackHistory playback_history;

    public MediaPlayer() {
        resource_base_path = "/app";
        application_id = Conf.APP_ID;
        flags |= HANDLES_OPEN;

        playback_history = PlaybackHistory.get_default();
    }

    PlayerWindow get_main_window() {
        return get_active_window() as PlayerWindow ?? new PlayerWindow(this);
    }

    public override void activate() {
        var win = get_main_window();
        win.present();

        if (win.settings.get_strv ("queue").length > 0) {
            var dialog = new ActionDialog(win, "Restore last session?");
            dialog.response["accept"].connect (win.restore_state);
            dialog.present ();
        }
    }

    public override void open(File[] files, string hint) {
        var win = get_main_window();
        win.open(files);
        win.present();
    }

    public override void startup() {
        base.startup();

        ActionEntry[] entries = {
            {"show_shortcuts", show_shortcuts_cb},
            {"quit", quit},
        };

        add_action_entries(entries, this);
        set_accels_for_action("app.show_shortcuts", {"<Ctrl>question"});
        set_accels_for_action("app.quit", {"<Ctrl>q", "q"});

        try {
            playback_history.load();
        } catch (Error e) {
            warning("Error occured while loading history: %s", e.message);
        }
    }

    Gtk.Window shortcuts_win;

    void show_shortcuts_cb() {
      var builder = new Gtk.Builder.from_resource("/app/shortcuts.ui");
      shortcuts_win = (Gtk.Window) builder.get_object("shortcuts_window");

      shortcuts_win.transient_for = get_active_window();
      shortcuts_win.present();
    }

    public override void shutdown () {
        var win = get_main_window  ();
        win.save_state();
        win.playback.stop();

        try {
            playback_history.save();
        } catch (Error e) {
            warning("Error occured while saving history: %s", e.message);
        }

        base.shutdown();
    }
}
