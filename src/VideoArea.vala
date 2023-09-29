delegate void Daikhan.CursorTimeoutCallback ();

class Daikhan.CursorTimeout {
    public uint delay { get; set; default = 0; }
    public unowned CursorTimeoutCallback callback;
    public unowned CursorTimeoutCallback motion_callback;

    public CursorTimeout (uint delay,
                          CursorTimeoutCallback callback,
                          CursorTimeoutCallback motion_callback)
    {
        this.delay = delay;
        this.callback = callback;
        this.motion_callback = motion_callback;
    }
}

[GtkTemplate (ui = "/app/VideoArea.ui")]
class Daikhan.VideoArea : Adw.Bin {
    [GtkChild] unowned Gtk.Picture video;
    [GtkChild] unowned Gtk.Revealer top_revealer;
    [GtkChild] unowned Daikhan.Title title_overlay;
    [GtkChild] unowned Daikhan.MediaControls controls_overlay;

    Gtk.EventControllerMotion title_ctrlr;
    Gtk.EventControllerMotion ctrls_ctrlr;
    Daikhan.CursorTimeout[] timeouts = null;
    Source[] timeout_sources = null;
    Daikhan.Playback playback;

    double cursor_x_cached;
    double cursor_y_cached;
    Gdk.Cursor none_cursor = new Gdk.Cursor.from_name ("none", null);

    static construct {
        set_css_name ("videoarea");
    }

    construct {
        playback = Daikhan.Playback.get_default ();

        video.paintable = playback.paintable;

        var ctrlr = new Gtk.EventControllerMotion ();
        ctrlr.motion.connect (cursor_motion_cb);
        this.add_controller (ctrlr);

        title_ctrlr = new Gtk.EventControllerMotion ();
        title_overlay.add_controller (title_ctrlr);

        ctrls_ctrlr = new Gtk.EventControllerMotion ();
        controls_overlay.add_controller (ctrls_ctrlr);

        this.cursor = none_cursor;

        add_motion_timeout (500,
            () => { // Callback for when the cursor stops moving
                this.cursor = none_cursor;
            }, () => { // Callback for when the cursor starts moving
                this.cursor = null;
            });

        add_motion_timeout (2000,
            () => {
                top_revealer.reveal_child = false;
            }, () => {
                top_revealer.reveal_child = true;
            });

        add_controller (Daikhan.DropTarget.new ());

        var click_gesture = new Gtk.GestureClick ();
        click_gesture.button = Gdk.BUTTON_PRIMARY;
        click_gesture.pressed.connect (click_gesture_pressed_cb);
        add_controller (click_gesture);

        add_controller (Daikhan.GestureDragWindow.new ());
    }

    Daikhan.CursorTimeout add_motion_timeout (uint interval,
                                               CursorTimeoutCallback callback,
                                               CursorTimeoutCallback motion_callback)
    {
        var timeout = new Daikhan.CursorTimeout (interval, callback, motion_callback);
        timeouts.resize (timeouts.length + 1);
        timeouts[timeouts.length - 1] = timeout;
        return timeout;
    }

    void cursor_motion_cb (Gtk.EventControllerMotion ctrlr,
                           double x, double y)
    {
        /* Gtk keeps emitting motion signal with the same x & y values when the
         * cursor is over the current widget (Video) and video is playing, even
         * if the cursor is actually not moving anymore.
         */
        if (x == cursor_x_cached && y == cursor_y_cached) {
            return;
        }

        cursor_x_cached = x;
        cursor_y_cached = y;

        // Run motion callbacks
        foreach (var timeout in timeouts)
            timeout.motion_callback ();

        // Destroy any pending timeouts
        foreach (var src in timeout_sources) {
            if (!src.is_destroyed ()) {
                src.destroy ();
            }
        }

        timeout_sources = null;

        // No need to set up timeouts if the cursor is on an interface widget
        if (title_ctrlr.contains_pointer || ctrls_ctrlr.contains_pointer) {
            return;
        }

        // Set up timeouts

        timeout_sources.resize (timeouts.length);

        for (int i = 0; i < timeout_sources.length; i++) {
            var src = new TimeoutSource (timeouts[i].delay);
            src.set_callback ((SourceFunc) timeouts[i].callback);
            src.attach ();
            timeout_sources[i] = src;
        }
    }

    void click_gesture_pressed_cb (Gtk.GestureClick gesture,
                                   int n_press, double x, double y)
    {
        // Don't do anything if the cursor is on media controls
        if (ctrls_ctrlr.contains_pointer) {
            return;
        }

        var window = this.get_root () as Daikhan.AppWindow;
        assert (window != null);

        if (n_press != 2) {
            return;
        }

        gesture.set_state (CLAIMED);
        window.activate_action ("toggle_fullscreen", null);
        gesture.reset ();
    }
}
