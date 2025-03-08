[GtkTemplate (ui = "/app/ErrorDialog.ui")]
class Daikhan.ErrorDialog : Adw.AlertDialog {
    public string additional_message { get; set; default = ""; }
    public string debug_info { get; set; default = ""; }
    private string default_message;

    construct {
        add_css_class ("errordialog");

        heading = _("Error");
        default_message = _("If this is unexpected, please, file a bug report"
                            + " with the following debug information.\n"
                            );

        body = default_message;
        notify["additional_message"].connect (() => {
            if (additional_message != "") {
                body = additional_message + "\n\n" + default_message;
            } else {
                body = default_message;
            }
        });
    }

    [GtkCallback]
    void report_bug_cb () {
        new Gtk.UriLauncher ("https://gitlab.com/daikhan/daikhan/-/issues")
            .launch.begin (root as Gtk.Window, null);
    }
}
