public class Daikhan.DurationLabel : Daikhan.TimeLabel {
    construct {
        var playback = Daikhan.Playback.get_default ();
        playback.bind_property ("duration", this, "time", SYNC_CREATE);
    }
}
