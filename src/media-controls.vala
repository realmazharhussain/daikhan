[GtkTemplate (ui = "/ui/media-controls.ui")]
public class MediaControls : Adw.Bin {
    [GtkChild] unowned PlayButton   play_btn;
    [GtkChild] unowned ProgressBar  progress_bar;
    [GtkChild] unowned VolumeButton volume_btn;

    Playback? _playback = null;
    public Playback? playback {
        get {
            return _playback;
        }

        set {
            if (_playback == value) {
                return;
            }

            play_btn.playback = value;
            progress_bar.playback = value;
            volume_btn.playback = value;

            _playback = value;
        }
    }
}
