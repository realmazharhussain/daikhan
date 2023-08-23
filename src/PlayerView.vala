[GtkTemplate (ui = "/app/PlayerView.ui")]
class Daikhan.PlayerView : Adw.Bin {
    public string title { get; set; default = ""; }
    public bool fullscreened { get; set; default = false; }

    static construct {
        typeof(Daikhan.AppMenuButton).ensure();
        typeof(Daikhan.MediaControls).ensure();
        typeof(Daikhan.Title).ensure();
        typeof(Daikhan.VideoArea).ensure();
    }
}
