class Daikhan.Title: Adw.Bin {
    public string title { get; set; }
    Daikhan.Playback playback;

    construct {
        child = new Adw.WindowTitle ("", "");
        playback = Daikhan.Playback.get_default ();

        bind_property("title", child, "title", BIDIRECTIONAL);
        playback.notify["filename"].connect(update_title);
        playback.track_info.notify["title"].connect(update_title);
        update_title();
    }

    void update_title() {
        if (playback.track_info.title == "") {
            title = playback.filename ?? _("Daikhan (Early Access)");
            child["subtitle"] = null;
            return;
        }

        var title_builder = new StringBuilder (playback.track_info.title);

        if (playback.track_info.album != "") {
            title_builder.append(" – ");
            title_builder.append(playback.track_info.album);
        }

        if (playback.track_info.artist != "") {
            title_builder.append(" – ");
            title_builder.append(playback.track_info.artist);
        }

        title = title_builder.str;
        child["subtitle"] = playback.filename;
    }
}
