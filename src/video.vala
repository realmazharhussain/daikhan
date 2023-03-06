class Video : Adw.Bin {
    Gst.Element? video_sink;
    unowned Playback playback;

    construct {
        var image = new Gtk.Picture();

        set("css_name", "video");
        child = image;
        hexpand = true;
        vexpand = true;

        dynamic var gtksink = Gst.ElementFactory.make("gtk4paintablesink", "null");
        dynamic Gdk.Paintable paintable = gtksink.paintable;
        image.paintable = paintable;

        if (paintable.gl_context != null) {
            var glsink = Gst.ElementFactory.make("glsinkbin", "glsinkbin");
            glsink["sink"] = gtksink;
            video_sink = glsink;
        }
        else {
            video_sink = gtksink;
        }

        notify["root"].connect(notify_root);
    }

    void notify_root() {
        assert (root is PlaybackWindow);
        playback = ((PlaybackWindow)root).playback;
        playback.notify["pipeline"].connect(notify_pipeline_cb);
        notify["root"].disconnect(notify_root);
    }

    Gst.Pipeline? last_pipeline = null;
    void notify_pipeline_cb() {
        if (last_pipeline != null) {
            last_pipeline["video-sink"] = null;
        }
        if (playback.pipeline != null) {
            playback.pipeline["video-sink"] = video_sink;
        }

        last_pipeline = playback.pipeline;
    }
}
