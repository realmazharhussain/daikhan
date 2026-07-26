[GtkTemplate (ui = "/app/PreferencesWindow.ui")]
class Daikhan.PreferencesWindow : Adw.PreferencesDialog {
    [GtkChild] unowned Daikhan.ComboRow dark_mode_combo;
    [GtkChild] unowned Daikhan.ComboRow seeking_combo;
    [GtkChild] unowned Adw.SwitchRow overlay_switch;
    [GtkChild] unowned Adw.PreferencesGroup experimental_group;
    [GtkChild] unowned Adw.SwitchRow clapper_sink_switch;
    Settings settings;

    static construct {
        typeof (Daikhan.ComboRow).ensure ();
    }

    construct {
        settings = new Settings (Conf.APP_ID);

        settings.bind ("overlay-ui", overlay_switch, "active", DEFAULT);

        dark_mode_combo.append ("default", _("Follow System"));
        dark_mode_combo.append ("force-light", _("Light"));
        dark_mode_combo.append ("force-dark", _("Dark"));
        settings.bind ("color-scheme", dark_mode_combo, "selected-id", DEFAULT);

        seeking_combo.append ("fast", _("Fast"));
        seeking_combo.append ("balanced", _("Balanced"));
        seeking_combo.append ("accurate", _("Accurate"));
        settings.bind ("seeking-method", seeking_combo, "selected-id", DEFAULT);

        if (Gst.ElementFactory.find ("clappersink") == null) {
            experimental_group.visible = false;
        } else {
            settings.bind ("clapper-sink", clapper_sink_switch, "active", DEFAULT);
        }
    }
}
