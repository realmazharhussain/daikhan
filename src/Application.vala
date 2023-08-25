class Daikhan.Application : Adw.Application {
    Daikhan.History playback_history;
    Settings settings;

    public Application () {
        Object (
            application_id: Conf.APP_ID,
            flags: ApplicationFlags.HANDLES_OPEN,
            resource_base_path: "/app"
        );

        playback_history = Daikhan.History.get_default ();
        settings = new Settings (Conf.APP_ID);

        var style_mgr = Adw.StyleManager.get_default ();
        settings.bind ("color-scheme", style_mgr, "color-scheme", DEFAULT);
    }

    Daikhan.AppWindow get_main_window () {
        return get_active_window () as Daikhan.AppWindow ?? new Daikhan.AppWindow (this);
    }

    public override void activate () {
        var win = get_main_window ();
        win.present ();

        if (win.settings.get_strv ("queue").length > 0) {
            var dialog = new Daikhan.ActionDialog (win, _("Restore last session?"));
            dialog.response["yes"].connect (win.restore_state);
            dialog.present ();
        }
    }

    public override void open (File[] files, string hint) {
        var win = get_main_window ();
        win.open (files);
        win.present ();
    }

    public override void startup () {
        base.startup ();

        ActionEntry[] entries = {
            {"preferences", preferences_cb},
            {"show_shortcuts", show_shortcuts_cb},
            {"quit", quit},
        };

        add_action_entries (entries, this);

        set_accels_for_action ("app.preferences", {"<Ctrl>comma"});
        set_accels_for_action ("app.show_shortcuts", {"<Ctrl>question"});
        set_accels_for_action ("app.quit", {"<Ctrl>q", "q"});
        set_accels_for_action ("win.toggle_fullscreen", {"f"});
        set_accels_for_action ("win.play_pause", {"space"});
        set_accels_for_action ("win.seek(+10)", {"Right", "l"});
        set_accels_for_action ("win.seek(-10)", {"Left", "h"});
        set_accels_for_action ("win.seek(+3)", {"<Shift>Right", "<Shift>l"});
        set_accels_for_action ("win.seek(-3)", {"<Shift>Left", "<Shift>h"});
        set_accels_for_action ("win.volume_step(+0.05)", {"Up", "k"});
        set_accels_for_action ("win.volume_step(-0.05)", {"Down", "j"});
        set_accels_for_action ("win.volume_step(+0.02)", {"<Shift>Up", "<Shift>k"});
        set_accels_for_action ("win.volume_step(-0.02)", {"<Shift>Down", "<Shift>j"});

        try {
            playback_history.load ();
        } catch (Error e) {
            warning ("Error occured while loading history: %s", e.message);
        }
    }

    Daikhan.PreferencesWindow pref_win;

    void preferences_cb () {
      pref_win = new Daikhan.PreferencesWindow () { transient_for = get_active_window () };
      pref_win.present ();
    }

    Gtk.Window shortcuts_win;

    void show_shortcuts_cb () {
      var builder = new Gtk.Builder.from_resource ("/app/Shortcuts.ui");
      shortcuts_win = (Gtk.Window) builder.get_object ("shortcuts_window");

      shortcuts_win.transient_for = get_active_window ();
      shortcuts_win.present ();
    }

    public override void shutdown () {
        var win = get_main_window ();
        win.save_state ();
        win.playback.stop ();

        try {
            playback_history.save ();
        } catch (Error e) {
            warning ("Error occured while saving history: %s", e.message);
        }

        base.shutdown ();
    }
}
