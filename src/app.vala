class MediaPlayer : Adw.Application {
    public MediaPlayer() {
        resource_base_path = "/app";
        application_id = "io.gitlab.Envision.MediaPlayer";
        flags |= HANDLES_OPEN;
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
            {"show_shortcuts", show_shortcuts_cb},
            {"quit", quit},
        };

        add_action_entries(entries, this);
        set_accels_for_action("app.show_shortcuts", {"<Ctrl>question"});
        set_accels_for_action("app.quit", {"<Ctrl>q", "q"});
    }

    Gtk.Window shortcuts_win;

    void show_shortcuts_cb() {
      var builder = new Gtk.Builder.from_resource("/app/ui/shortcuts.ui");
      shortcuts_win = (Gtk.Window) builder.get_object("shortcuts_window");

      shortcuts_win.transient_for = get_active_window();
      shortcuts_win.present();
    }
}
