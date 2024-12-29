public class Daikhan.ProgressLabel : Daikhan.TimeLabel {
    construct {
        add_css_class ("progresslabel");

        var playback = Daikhan.Playback.get_default ();
        playback.bind_property ("progress", this, "time", SYNC_CREATE);
    }
}
