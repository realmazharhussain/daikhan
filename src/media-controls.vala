[GtkTemplate (ui = "/ui/media-controls.ui")]
public class MediaControls : Adw.Bin {
    static construct {
        typeof(PlayButton).ensure();
        typeof(ProgressLabel).ensure();
        typeof(ProgressBar).ensure();
        typeof(DurationLabel).ensure();
        typeof(VolumeButton).ensure();
    }

    construct {
        set("css-name", "mediacontrols");
    }

}
