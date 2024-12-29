public class Daikhan.ProgressLabel : Daikhan.TimeLabel {
    construct {
        add_css_class ("progresslabel");

        var player = Daikhan.Player.get_default ();
        player.bind_property ("progress", this, "time", SYNC_CREATE);
    }
}
