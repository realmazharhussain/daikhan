[GtkTemplate (ui = "/app/preferences.ui")]
class PreferencesWindow : Adw.PreferencesWindow {
    [GtkChild] unowned Gtk.Switch dark_mode_switch;
    Settings settings;

    construct {
        settings = new Settings (Conf.APP_ID);
        settings.bind("prefer-dark-style", dark_mode_switch, "active", DEFAULT);
    }
}
