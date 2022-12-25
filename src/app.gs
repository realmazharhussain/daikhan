[indent=4]

class MediaPlayer: Adw.Application

    init
        application_id = "io.gitlab.Envision.MediaPlayer"
        flags |= ApplicationFlags.HANDLES_OPEN

    def override activate()
        var win = new MainWindow(self)
        win.present()

    def override open(files: array of File, hint: string)
        var file = files[files.length-1]
        var win = get_active_window()
        if win is null
            activate()
        win = get_active_window()
        if win isa MainWindow
          win.open_file(file)

    def override startup()
        super.startup()
        typeof(HeaderBar).ensure()

        var quit_action = new SimpleAction("quit", null)
        quit_action.activate.connect(quit)
        add_action(quit_action)
        set_accels_for_action("app.quit", {"<Ctrl>q"})
