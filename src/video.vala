class Video : Adw.Bin {
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

        playback = Playback.get_default();

        if (paintable.gl_context != null) {
            var glsink = Gst.ElementFactory.make("glsinkbin", "glsinkbin");
            glsink["sink"] = gtksink;
            playback.video_sink = glsink;
        }
        else {
            playback.video_sink = gtksink;
        }
    }
}
