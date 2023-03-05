[GtkTemplate (ui = "/ui/media-controls.ui")]
public class MediaControls : Adw.Bin {
    static construct {
        typeof(PlayButton).ensure();
        typeof(ProgressBar).ensure();
        typeof(VolumeButton).ensure();
    }
}
