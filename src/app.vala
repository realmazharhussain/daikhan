class MediaPlayer : Adw.Application {
    construct {
        application_id = "io.gitlab.Envision.MediaPlayer";
        flags |= ApplicationFlags.HANDLES_OPEN;
    }

    PlayerWindow get_main_window() {
        var window = get_active_window() as PlayerWindow;
        window = window ?? new PlayerWindow(this);
        return window;
    }

    public override void activate() {
        get_main_window().present();
    }

    public override void open(File[] files, string hint) {
        var file = files[files.length-1];
        var win = get_main_window();
        win.open_file(file);
        win.present();
    }

    public override void startup() {
        base.startup();

        ActionEntry[] entries = {
            {"quit", quit},
        };

        add_action_entries(entries, this);
        set_accels_for_action("app.quit", {"<Ctrl>q", "q"});
    }
}
