public class Daikhan.DurationLabel : Daikhan.TimeLabel {
    construct {
        add_css_class ("durationlabel");

        var playback = Daikhan.Playback.get_default ();
        playback.bind_property ("duration", this, "time", SYNC_CREATE);
    }
}
