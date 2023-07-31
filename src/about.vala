namespace Adw {
    extern void show_about_window(Gtk.Window parent,
                                  string first_property_name, ...);
}

void show_about_window(Gtk.Window parent) {

    Adw.show_about_window(parent,
        "issue_url", "https://gitlab.com/daikhan/daikhan/-/issues/new",
        "application_icon", Conf.APP_ID,
        "application_name", "Daikhan",
        "copyright", "Copyright 2022-2023 Mazhar Hussain",
        "license_type", Gtk.License.AGPL_3_0,
        "developer_name", "Mazhar Hussain",
        "version", "0.1.alpha"
    );
}
