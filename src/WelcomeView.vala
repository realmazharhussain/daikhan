[GtkTemplate (ui = "/app/WelcomeView.ui")]
public class Daikhan.WelcomeView : Adw.Bin {
    static construct {
        typeof(Daikhan.AppMenuButton).ensure();
    }
}