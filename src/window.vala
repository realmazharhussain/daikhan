[GtkTemplate (ui = "/app/window.ui")]
class PlayerWindow : Adw.ApplicationWindow {
    [GtkChild] unowned Envision.Title title_widget;
    [GtkChild] unowned Video video;
    [GtkChild] unowned Gtk.Revealer top_revealer;
    public Playback playback { get; private set; }

    static construct {
        typeof(MediaControls).ensure();
    }

    construct {
        ActionEntry[] entries = {
            {"seek", seek_cb, "i"},
            {"volume_step", volume_step_cb, "d"},
            {"play_pause", play_pause_cb},
            {"toggle_fullscreen", toggle_fullscreen_cb},
            {"about", about_cb},
        };

        add_action_entries(entries, this);

        playback = Playback.get_default();
        playback.notify["desired-state"].connect(notify_playback_state_cb);

        title_widget.bind_property ("title", this, "title", SYNC_CREATE);
        video.notify["cursor-in-motion"].connect(notify_video_cursor_cb);
    }

    public PlayerWindow (Gtk.Application app) {
        application = app;

        app.set_accels_for_action("win.toggle_fullscreen", {"f"});
        app.set_accels_for_action("win.play_pause", {"space"});
        app.set_accels_for_action("win.seek(+10)", {"Right", "l"});
        app.set_accels_for_action("win.seek(-10)", {"Left", "h"});
        app.set_accels_for_action("win.seek(+3)", {"<Shift>Right", "<Shift>l"});
        app.set_accels_for_action("win.seek(-3)", {"<Shift>Left", "<Shift>h"});
        app.set_accels_for_action("win.volume_step(+0.05)", {"Up", "k"});
        app.set_accels_for_action("win.volume_step(-0.05)", {"Down", "j"});
        app.set_accels_for_action("win.volume_step(+0.02)", {"<Shift>Up", "<Shift>k"});
        app.set_accels_for_action("win.volume_step(-0.02)", {"<Shift>Down", "<Shift>j"});
    }

    public bool open(File[] files) {
        return playback.open(files);
    }

    uint inhibit_id = 0;
    void notify_playback_state_cb() {
        if (playback.desired_state == PLAYING) {
            inhibit_id = application.inhibit(this, IDLE, "Media is playing");
        } else {
            application.uninhibit(inhibit_id);
        }
    }

    TimeoutSource? overlay_timeout_source;
    void notify_video_cursor_cb() {
        if (overlay_timeout_source != null && !overlay_timeout_source.is_destroyed ())
            overlay_timeout_source.destroy ();

        if (video.cursor_in_motion)
            top_revealer.reveal_child = true;
        else {
            overlay_timeout_source = new TimeoutSource (1500);
            overlay_timeout_source.set_callback (() => {
                top_revealer.reveal_child = false;
                return Source.REMOVE;
            });
            overlay_timeout_source.attach ();
        }
    }

    void seek_cb (SimpleAction action, Variant? step) {
        playback.seek(step.get_int32());
    }

    void volume_step_cb (SimpleAction action, Variant? step) {
        playback.volume += step.get_double();
    }

    void play_pause_cb () {
        playback.toggle_playing();
    }

    void toggle_fullscreen_cb () {
        fullscreened = !fullscreened;
    }

    void about_cb () {
        show_about_window(this);
    }
}
