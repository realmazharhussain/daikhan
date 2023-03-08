[GtkTemplate (ui = "/ui/headerbar.ui")]
public class HeaderBar : Adw.Bin {
    public string title { get; set construct; default = ""; }
    unowned Playback playback;

    construct {
        // Update headerbar title when title of the root Window is updated
        var root_expr = new Gtk.PropertyExpression(typeof(Gtk.Widget), null, "root");
        var root_title_expr = new Gtk.PropertyExpression(typeof(Gtk.Window), root_expr, "title");
        root_title_expr.watch(this, update_title);

        // Update headerbar title when playback title is updated
        playback = Playback.get_default();
        playback.notify["title"].connect(update_title);
    }

    void update_title() {
        if (playback.title != null) {
            title = playback.title;
        } else if (root is Gtk.Window) {
            title = ((Gtk.Window) root).title;
        }
    }
}
