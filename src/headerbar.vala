[GtkTemplate (ui = "/ui/headerbar.ui")]
public class HeaderBar : Adw.Bin {
    public string title { get; set construct; default = ""; }
    unowned Playback playback;

    construct {
        playback = Playback.get_default();
        playback.bind_property("title", this, "title", SYNC_CREATE,
                               playback_title_to_title);
    }

    bool playback_title_to_title(Binding binding, Value playback_title, ref Value title) {
        if ((string)playback_title != "") {
            title = playback_title;
        } else if (root is Gtk.Window) {
            title = ((Gtk.Window) root).title;
        } else {
            return false;
        }
        return true;
    }
}
