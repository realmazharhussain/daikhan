[indent=4]

namespace Adw
    def extern show_about_window(parent: Gtk.Window,
                                 first_property_name: string, ...)

def show_about_window(parent: Gtk.Window)
    developers: array of string = {"Mazhar Hussain"}

    Adw.show_about_window(parent,
        "issue_url", "https://gitlab.com/envision/media-player/-/issues/new",
        "website", "https://gitlab.com/envision/media-player",
        "application_name", "Envision Media Player",
        "copyright", "Copyright 2022 Mazhar Hussain",
        "license_type", Gtk.License.AGPL_3_0,
        "developer_name", developers[0],
        "version", "0.1.alpha",
        "documenters", developers,
        "developers", developers,
        "designers", developers
    )
