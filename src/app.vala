class MediaPlayer : Adw.Application {
    construct {
        application_id = "io.gitlab.Envision.MediaPlayer";
        flags |= ApplicationFlags.HANDLES_OPEN;
    }

    MainWindow get_main_window() {
        var window = get_active_window() as MainWindow;
        window = window ?? new MainWindow(this);
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

        var quit_action = new SimpleAction("quit", null);
        quit_action.activate.connect(quit);
        add_action(quit_action);
        set_accels_for_action("app.quit", {"<Ctrl>q"});
    }
}
