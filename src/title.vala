class Envision.Title: Adw.Bin {
    public string title { get; set; }
    Playback playback;

    construct {
        child = new Adw.WindowTitle ("", "");
        playback = Playback.get_default ();

        bind_property("title", child, "title", BIDIRECTIONAL);
        playback.notify["filename"].connect(update_title);
        playback.notify["title"].connect(update_title);
        update_title();
    }

    void update_title() {
        if (playback.title == null) {
            title = playback.filename ?? "Envision Media Player";
            child["subtitle"] = null;
            return;
        }

        child["subtitle"] = playback.filename;
        title = playback.title;

        if (playback.album != null)
            title += " – " + playback.album;

        if (playback.artist != null)
            title += " – " + playback.artist;
    }
}
