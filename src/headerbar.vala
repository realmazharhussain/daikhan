[GtkTemplate (ui = "/ui/headerbar.ui")]
public class HeaderBar : Adw.Bin {
    public string title { get; set construct; default = ""; }
    unowned PlaybackWindow root_window;
    unowned Playback playback;

    construct {
        notify["root"].connect(notify_root);
    }

    void notify_root() {
        assert (root is PlaybackWindow);
        root_window = (PlaybackWindow)root;
        playback = root_window.playback;
        notify["root"].disconnect(notify_root);

        playback.bind_property("title", this, "title", BindingFlags.SYNC_CREATE,
                               playback_title_to_title);
    }

    bool playback_title_to_title(Binding binding, Value playback_title, ref Value title) {
        if ((string)playback_title != "") {
            title = playback_title;
        } else {
            title = root_window.title;
        }
        return true;
    }
}
