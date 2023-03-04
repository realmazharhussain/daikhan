class Video : Adw.Bin {
    Gst.Element? video_sink = null;

    private Playback? _playback = null;
    public Playback? playback {
        get { return _playback; }
        set {
            if (_playback == value) {
                return;
            }

            if (value != null && value.pipeline != null) {
                value.pipeline.set("video-sink", video_sink);
            }

            _playback = value;
        }
    }

    public Video () {
        Object(css_name: "video");
    }

    construct {
        child = new Gtk.Picture();
        hexpand = true;
        vexpand = true;

        add_css_class("video");

        var gtksink = Gst.ElementFactory.make("gtk4paintablesink", "null");
        if (gtksink == null) {
            printerr("Could not create Video Sink!");
            return;
        }

        Gdk.Paintable paintable;
        gtksink.get("paintable", out paintable);
        ((Gtk.Picture)child).paintable = paintable;

        Gdk.GLContext gl_context;
        paintable.get("gl-context", out gl_context);
        if (gl_context != null) {
            var glsink = Gst.ElementFactory.make("glsinkbin", "glsinkbin");
            glsink.set("sink", gtksink);
            video_sink = glsink;
        }
        else {
            video_sink = gtksink;
        }
    }
}
