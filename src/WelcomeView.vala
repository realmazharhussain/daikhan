[GtkTemplate (ui = "/app/WelcomeView.ui")]
public class Daikhan.WelcomeView : Adw.Bin {
    [GtkChild] unowned Gtk.FileDialog file_dialog;

    static construct {
        typeof (Daikhan.AppMenuButton).ensure ();
        typeof (Daikhan.PillButton).ensure ();
    }

    [GtkCallback]
    void open_clicked () {
        file_dialog.open_multiple.begin ((Gtk.Window) root, null,
        (dialog, res) => {
            try {
                var model = file_dialog.open_multiple.end (res);
                var files = Daikhan.Utils.list_model_to_array<File> (model);
                ((Daikhan.AppWindow) root).playback.open (files);
            } catch (Gtk.DialogError.DISMISSED err) {
                // Nothing to do here
            } catch (Error err) {
                critical ("Error occured while opening files via dialog: %s", err.message);
            }
        });
    }
}
