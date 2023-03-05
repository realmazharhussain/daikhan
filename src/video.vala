class Video : Adw.Bin {
    Gst.Element? video_sink = null;

    construct {
        set("css_name", "video");
        child = new Gtk.Picture();
        hexpand = true;
        vexpand = true;

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

    private Playback? _playback = null;
    public Playback? playback {
        get { return _playback; }
        set {
            if (_playback == value) {
                return;
            }

            if (_playback != null) {
                _playback.notify["pipeline"].disconnect(notify_pipeline_cb);
            }

            if (value != null) {
                value.notify["pipeline"].connect(notify_pipeline_cb);
            }

            _playback = value;
        }
    }

    Gst.Pipeline? last_pipeline = null;
    void notify_pipeline_cb() {
        if (last_pipeline != null) {
            last_pipeline.set("video-sink", null);
        }
        if (playback.pipeline != null) {
            playback.pipeline.set("video-sink", video_sink);
        }

        last_pipeline = playback.pipeline;
    }
}
