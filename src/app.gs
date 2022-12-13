[indent=4]

class MediaPlayer: Adw.Application

    init
        application_id = "com.gitlab.Envision.MediaPlayer"

    def override activate ()
        var win = new MainWindow(self)
        win.present()

    def override startup ()
        super.startup()
        typeof(HeaderBar).ensure()

        var quit_action = new SimpleAction("quit", null)
        quit_action.activate.connect(quit)
        add_action(quit_action)
        set_accels_for_action("app.quit", {"<Ctrl>q"})
