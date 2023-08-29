public class Daikhan.ProgressLabel : Daikhan.TimeLabel {
    construct {
        var playback = Daikhan.Playback.get_default ();
        playback.bind_property ("progress", this, "time", SYNC_CREATE);
    }
}
