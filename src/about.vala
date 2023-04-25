namespace Adw {
    extern void show_about_window(Gtk.Window parent,
                                  string first_property_name, ...);
}

void show_about_window(Gtk.Window parent) {

    Adw.show_about_window(parent,
        "issue_url", "https://gitlab.com/envision-play/envision-media-player/-/issues/new",
        "application_icon", "io.gitlab.Envision.MediaPlayer",
        "application_name", "Envision Media Player",
        "copyright", "Copyright 2022-2023 Mazhar Hussain",
        "license_type", Gtk.License.AGPL_3_0,
        "developer_name", "Mazhar Hussain",
        "version", "0.1.alpha"
    );
}
