public class Daikhan.DurationLabel : Daikhan.TimeLabel {
    construct {
        add_css_class ("durationlabel");

        var player = Daikhan.Player.get_default ();
        player.bind_property ("duration", this, "time", SYNC_CREATE);
    }
}
