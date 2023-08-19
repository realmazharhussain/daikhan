class Daikhan.ActionDialog : Adw.MessageDialog {
    public ActionDialog (Gtk.Window? parent, string question) {
        Object(
            transient_for: parent,
            heading: question
        );
    }

    construct {
        add_response ("no", _("No"));
        add_response ("yes", _("Yes"));
        set_response_appearance ("yes", SUGGESTED);
        default_response = "yes";
    }
}
