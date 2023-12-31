public class Daikhan.TimeLabel : Gtk.Widget {
    public int64 time { get; set; default = -1;}
    Gtk.Label child;

    class construct {
        set_css_name ("timelabel");
        set_layout_manager_type (typeof (Gtk.BinLayout));
    }

    construct {
        child = new Gtk.Label (null);
        child.set_parent (this);

        notify["time"].connect (update_label);
    }

    ~TimeLabel () {
        child.unparent ();
    }

    void update_label () {
        var total_seconds = time / Gst.SECOND;
        var total_minutes = total_seconds / 60;
        var hours = total_minutes / 60;
        var minutes = total_minutes % 60;
        var seconds = total_seconds % 60;

        if (time < 0) {
            child.label = "--:--";
        } else if (hours > 0) {
            child.label = "%02lli:%02lli:%02lli".printf (hours, minutes, seconds);
        } else {
            child.label = "%02lli:%02lli".printf (minutes, seconds);
        }
    }
}
