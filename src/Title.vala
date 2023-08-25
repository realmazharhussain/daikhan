class Daikhan.Title: Adw.Bin {
    public string title { get; private set; }
    Daikhan.Playback playback;

    construct {
        child = new Adw.WindowTitle ("", "");
        playback = Daikhan.Playback.get_default ();

        playback.notify["filename"].connect(update_title);
        playback.track_info.notify["title"].connect(update_title);
        update_title();
    }

    void update_title() {
        if (playback.track_info.title == "") {
            title = playback.filename ?? _("Daikhan (Early Access)");
            child["title"] = playback.filename ?? "";
            child["subtitle"] = "";
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
        child["title"] = title_builder.str;
        child["subtitle"] = playback.filename;
    }
}
