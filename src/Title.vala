class Daikhan.Title: Adw.Bin {
    public string title { get; set; }
    Playback playback;

    construct {
        child = new Adw.WindowTitle ("", "");
        playback = Playback.get_default ();

        bind_property("title", child, "title", BIDIRECTIONAL);
        playback.notify["filename"].connect(update_title);
        playback.track_info.notify["title"].connect(update_title);
        update_title();
    }

    void update_title() {
        if (playback.track_info.title.length == 0) {
            title = playback.filename ?? _("Daikhan (Early Access)");
            child["subtitle"] = null;
            return;
        }

        child["subtitle"] = playback.filename;
        title = playback.track_info.title;

        if (playback.track_info.album.length > 0) {
            title += " – " + playback.track_info.album;
        }

        if (playback.track_info.artist.length > 0) {
            title += " – " + playback.track_info.artist;
        }
    }
}
