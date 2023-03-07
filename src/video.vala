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

        var target = new Gtk.DropTarget(typeof(Gdk.FileList), COPY);
        target.preload = true;
        target.notify["value"].connect(notify_drop_value_cb);
        target.drop.connect (drop_cb);
        add_controller(target);

        notify["root"].connect(notify_root_cb);
    }

    void notify_root_cb() {
        assert (root is PlaybackWindow);
        playback = ((PlaybackWindow)root).playback;
        playback.notify["pipeline"].connect(notify_pipeline_cb);
        notify["root"].disconnect(notify_root_cb);
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

    bool drop_value_is_acceptable(Value value) {
        var flist = (Gdk.FileList) value;
        var file = flist.get_files().last().data;
        string? mimetype;

        try {
            mimetype = file.query_info("standard::", NONE).get_content_type();
        } catch (Error err) {
            return false;
        }

        if (mimetype == null)
            return false;

        if (mimetype.has_prefix("video/"))
            return true;

        if (mimetype.has_prefix("audio/"))
            return true;

        return false;
    }

    void notify_drop_value_cb(Object obj, ParamSpec pspec) {
        var target = (Gtk.DropTarget) obj;

        var value = target.get_value();
        if (value == null)
            return;

        if (!drop_value_is_acceptable(value))
            target.reject();
    }

    bool drop_cb(Gtk.DropTarget target, Value value, double x, double y) {
        var file = ((Gdk.FileList) value).get_files().last().data;
        return playback.open_file(file);
    }
}
