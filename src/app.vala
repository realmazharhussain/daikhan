class MediaPlayer : Adw.Application {
    construct {
        application_id = "io.gitlab.Envision.MediaPlayer";
        flags |= ApplicationFlags.HANDLES_OPEN;
    }

    public override void activate() {
        var win = get_active_window() ?? new MainWindow(this);
        win.present();
    }

    public override void open(File[] files, string hint) {
        activate();
        var file = files[files.length-1];
        var win = get_active_window() as MainWindow;
        win.open_file(file);
    }

    public override void startup() {
        base.startup();
        ensure_types();
        add_actions();
        assign_keyboard_shortcuts();
    }

    // Ensure that types are initialized in correct order
    void ensure_types() {
        typeof(HeaderBar).ensure();
        typeof(PlayButton).ensure();
    }

    void add_actions() {
        var quit_action = new SimpleAction("quit", null);
        quit_action.activate.connect(quit);
        add_action(quit_action);
    }

    void assign_keyboard_shortcuts() {
        set_accels_for_action("win.toggle_fullscreen", {"f"});
        set_accels_for_action("app.quit", {"<Ctrl>q"});
    }
}
