[GtkTemplate (ui = "/app/media-controls.ui")]
public class MediaControls : Adw.Bin {
    static construct {
        typeof(PlayButton).ensure();
        typeof(ProgressLabel).ensure();
        typeof(ProgressBar).ensure();
        typeof(DurationLabel).ensure();
        typeof(VolumeButton).ensure();
    }
}
