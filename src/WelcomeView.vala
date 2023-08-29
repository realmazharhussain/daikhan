[GtkTemplate (ui = "/app/WelcomeView.ui")]
public class Daikhan.WelcomeView : Adw.Bin {
    [GtkChild] unowned Adw.StatusPage status;
    [GtkChild] unowned Gtk.FileDialog file_dialog;
    [GtkChild] unowned Daikhan.PillButton replay_btn;
    [GtkChild] unowned Daikhan.PillButton restore_btn;
    Daikhan.Playback playback;
    Settings state_mem;

    static construct {
        typeof (Daikhan.AppMenuButton).ensure ();
    }

    construct {
        playback = Daikhan.Playback.get_default ();
        state_mem = new Settings (Conf.APP_ID + ".state");

        playback.notify["queue"].connect (update_replay_btn_visibility);
        state_mem.changed["queue"].connect (update_restore_btn_visibility);

        update_replay_btn_visibility ();
        update_restore_btn_visibility ();

        add_controller (Daikhan.DropTarget.new ());
        status.add_controller (Daikhan.GestureDragWindow.new ());
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

    [GtkCallback]
    void replay_clicked () {
        playback.load_track (0);
    }

    [GtkCallback]
    void restore_clicked () {
        ((Daikhan.AppWindow) root).restore_state ();
    }

    void update_replay_btn_visibility () {
        replay_btn.visible = playback.queue.length > 0;
    }

    void update_restore_btn_visibility () {
        restore_btn.visible = state_mem.get_strv ("queue").length > 0;
    }
}
