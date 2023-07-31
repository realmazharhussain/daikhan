public class ProgressLabel : TimeLabel {
    construct {
        var playback = Playback.get_default();
        playback.bind_property("progress", this, "time", SYNC_CREATE);
    }
}

public class DurationLabel : TimeLabel {
    construct {
        var playback = Playback.get_default();
        playback.bind_property("duration", this, "time", SYNC_CREATE);
    }
}

public class TimeLabel : Gtk.Widget {
    public int64 time { get; set; default = -1;}
    Gtk.Label child;

    class construct {
        set_layout_manager_type (typeof (Gtk.BinLayout));
    }

    construct {
        set("css-name", "timelabel");

        child = new Gtk.Label (null);
        child.set_parent (this);

        notify["time"].connect(update_label);
    }

    ~TimeLabel() {
        child.unparent();
    }

    void update_label() {
        var total_seconds = time / Gst.SECOND;
        var total_minutes = total_seconds / 60;
        var hours = total_minutes / 60;
        var minutes = total_minutes % 60;
        var seconds = total_seconds % 60;

        var format = "%02" + int64.FORMAT;

        if (time < 0) {
            child.label = "--:--";
        } else  if (hours > 0) {
            child.label =  @"$format:$format:$format".printf(hours, minutes, seconds);
        } else {
            child.label =  @"$format:$format".printf(minutes, seconds);
        }
    }
}
