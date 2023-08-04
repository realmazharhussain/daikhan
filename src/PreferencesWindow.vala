[GtkTemplate (ui = "/app/preferences.ui")]
class PreferencesWindow : Adw.PreferencesWindow {
    [GtkChild] unowned IdComboRow dark_mode_combo;
    Settings settings;

    static construct {
        typeof (IdComboRow).ensure ();
    }

    construct {
        settings = new Settings (Conf.APP_ID);

        dark_mode_combo.append("default", "Follow System");
        dark_mode_combo.append("force-light", "Light");
        dark_mode_combo.append("force-dark", "Dark");

        settings.bind("color-scheme", dark_mode_combo, "selected-id", DEFAULT);
    }
}
