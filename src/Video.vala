class Video : Adw.Bin {
    construct {
        var playback = Playback.get_default();

        set("css_name", "video");
        child = new Gtk.Picture.for_paintable (playback.paintable);
        hexpand = true;
        vexpand = true;
    }
}
