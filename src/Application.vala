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
    }

    Daikhan.AppWindow get_main_window () {
        return get_active_window () as Daikhan.AppWindow ?? new Daikhan.AppWindow (this);
    }

    public static File? get_data_dir() {
        var path = Environment.get_user_data_dir ();
        var file = File.new_for_path (path);
        if (!(Conf.APP_ID in path)) {
            file = file.get_child (Conf.APP_ID) ;
        }

        try {
            file.make_directory_with_parents ();
        } catch (IOError.EXISTS err) {
            // Nothing to do
        } catch (Error err) {
            critical ("Failed to create app data dir: %s", path);
            return null;
        }

        return file;
    }

    public override void activate () {
        var win = get_main_window ();
        win.present ();
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
            {"about", about_cb},
            {"quit", quit},
        };

        add_action_entries (entries, this);

        set_accels_for_action ("app.preferences", {"<Ctrl>comma"});
        set_accels_for_action ("app.show_shortcuts", {"<Ctrl>question"});
        set_accels_for_action ("app.quit", {"<Ctrl>q", "q"});
        set_accels_for_action ("win.exit_fullscreen", {"Escape"});
        set_accels_for_action ("win.toggle_fullscreen", {"f"});
        set_accels_for_action ("win.play_pause", {"space"});
        set_accels_for_action ("win.seek(+10)", {"Right", "l"});
        set_accels_for_action ("win.seek(-10)", {"Left", "h"});
        set_accels_for_action ("win.seek(+60)", {"<Ctrl>Right", "<Ctrl>l"});
        set_accels_for_action ("win.seek(-60)", {"<Ctrl>Left", "<Ctrl>h"});
        set_accels_for_action ("win.seek(+3)", {"<Shift>Right", "<Shift>l"});
        set_accels_for_action ("win.seek(-3)", {"<Shift>Left", "<Shift>h"});
        set_accels_for_action ("win.volume_step(+0.05)", {"Up", "k"});
        set_accels_for_action ("win.volume_step(-0.05)", {"Down", "j"});
        set_accels_for_action ("win.volume_step(+0.02)", {"<Shift>Up", "<Shift>k"});
        set_accels_for_action ("win.volume_step(-0.02)", {"<Shift>Down", "<Shift>j"});

        var style_mgr = Adw.StyleManager.get_default ();
        settings.bind ("color-scheme", style_mgr, "color-scheme", DEFAULT);

        try {
            playback_history.load ();
        } catch (Error e) {
            warning ("Error occured while loading history: %s", e.message);
        }

        Bus.own_name (SESSION, "org.mpris.MediaPlayer2.daikhan", ALLOW_REPLACEMENT | REPLACE,
            (conn) => {
                try {
                    conn.register_object("/org/mpris/MediaPlayer2", new MPRIS.App (conn));
                    conn.register_object("/org/mpris/MediaPlayer2", new MPRIS.Player (conn));
                } catch (IOError e) {
                    stderr.printf ("Could not register service\n");
                }
            },
            () => {},
            () => { stderr.printf ("Could not aquire name\n"); }
        );
    }

    Daikhan.PreferencesWindow pref_win;

    void preferences_cb () {
      pref_win = new Daikhan.PreferencesWindow ();
      pref_win.present (active_window);
    }

    Adw.Dialog shortcuts_dialog;

    void show_shortcuts_cb () {
      var builder = new Gtk.Builder.from_resource ("/app/Shortcuts.ui");
      shortcuts_dialog = (Adw.Dialog) builder.get_object ("shortcuts_dialog");
      shortcuts_dialog.present (get_active_window ());
    }

    void about_cb () {
        var win = new Adw.AboutDialog.from_appdata ("/app/metainfo.xml", Conf.VERSION.replace ("-", "~"));
        win.present (active_window);
    }

    public override void shutdown () {
        get_main_window ().close ();
        base.shutdown ();
    }
}
