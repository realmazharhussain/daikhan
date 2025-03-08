class Daikhan.Title: Adw.Bin {
    public string title { get; private set; }
    Daikhan.Player player;

    static construct {
        set_css_name ("title");
    }

    construct {
        child = new Adw.WindowTitle ("", "");
        player = Daikhan.Player.get_default ();

        player.notify["filename"].connect (update_title);
        player.track_info.notify["title"].connect (update_title);
        update_title ();
    }

    void update_title () {
        if (player.track_info.title == "") {
            title = player.filename ?? _("Daikhan (Early Access)");
            child["title"] = player.filename ?? "";
            child["subtitle"] = "";
            return;
        }

        var title_builder = new StringBuilder (player.track_info.title);

        if (player.track_info.album != "") {
            title_builder.append (" – ");
            title_builder.append (player.track_info.album);
        }

        if (player.track_info.artist != "") {
            title_builder.append (" – ");
            title_builder.append (player.track_info.artist);
        }

        title = title_builder.str;
        child["title"] = title_builder.str;
        child["subtitle"] = player.filename;
    }
}
