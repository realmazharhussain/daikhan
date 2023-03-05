[GtkTemplate (ui = "/ui/headerbar.ui")]
public class HeaderBar : Adw.Bin {
    public string title { get; set construct; default = ""; }

    Binding? title_binding;

    private Playback? _playback;
    public Playback? playback {
        get {
            return _playback;
        }

        set {
            if (_playback == value) {
                return;
            }

            if (_playback != null) {
                title_binding.unbind();
            }

            if (value != null) {
                title_binding = value.bind_property("title", this, "title",
                                                    BindingFlags.SYNC_CREATE,
                                                    playback_title_to_title);
            }

            _playback = value;
        }
    }

    bool playback_title_to_title(Binding binding, Value playback_title, ref Value title) {
        if ((string)playback_title != "") {
            title = playback_title;
        } else {
            var win = root as PlayerWindow;
            if (win != null) {
                title = win.title;
            }
        }
        return true;
    }
}
