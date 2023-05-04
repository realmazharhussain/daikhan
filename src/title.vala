class Envision.Title: Adw.Bin {
    public string title { get; set; }
    Playback playback;

    construct {
        child = new Adw.WindowTitle ("", "");
        playback = Playback.get_default ();

        bind_property("title", child, "title", BIDIRECTIONAL);
        playback.notify["title"].connect(update_title);
        update_title();
    }

    void update_title() {
        title = playback.title ?? "Envision Media Player";
    }
}