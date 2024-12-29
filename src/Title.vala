class Daikhan.Title: Adw.Bin {
    public string title { get; private set; }
    Daikhan.Playback playback;

    static construct {
        set_css_name ("title");
    }

    construct {
        child = new Adw.WindowTitle ("", "");
        playback = Daikhan.Playback.get_default ();

        playback.playbin_proxy.notify["filename"].connect (update_title);
        playback.playbin_proxy.track_info.notify["title"].connect (update_title);
        update_title ();
    }

    void update_title () {
        if (playback.playbin_proxy.track_info.title == "") {
            title = playback.playbin_proxy.filename ?? _("Daikhan (Early Access)");
            child["title"] = playback.playbin_proxy.filename ?? "";
            child["subtitle"] = "";
            return;
        }

        var title_builder = new StringBuilder (playback.playbin_proxy.track_info.title);

        if (playback.playbin_proxy.track_info.album != "") {
            title_builder.append (" – ");
            title_builder.append (playback.playbin_proxy.track_info.album);
        }

        if (playback.playbin_proxy.track_info.artist != "") {
            title_builder.append (" – ");
            title_builder.append (playback.playbin_proxy.track_info.artist);
        }

        title = title_builder.str;
        child["title"] = title_builder.str;
        child["subtitle"] = playback.playbin_proxy.filename;
    }
}
