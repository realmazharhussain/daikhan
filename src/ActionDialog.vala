class ActionDialog : Adw.MessageDialog {
    public ActionDialog (Gtk.Window? parent, string question) {
        Object(
            transient_for: parent,
            heading: question
        );
    }

    construct {
        add_response ("deny", _("No"));
        add_response ("accept", _("Yes"));
        set_response_appearance ("accept", SUGGESTED);
        default_response = "accept";
    }
}
