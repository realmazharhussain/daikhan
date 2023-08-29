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

        var target = new Gtk.DropTarget (typeof (Gdk.FileList), COPY);
        target.preload = true;
        target.notify["value"].connect (notify_drop_value_cb);
        target.drop.connect (drop_cb);
        add_controller (target);

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

    bool drop_value_is_acceptable (Value value) {
        var files = ((Gdk.FileList) value).get_files ();

        foreach (var file in files) {
            if (Daikhan.Utils.is_file_type_supported (file)) {
                return true;
            }
        }

        return false;
    }

    void notify_drop_value_cb (Object obj, ParamSpec pspec) {
        var target = (Gtk.DropTarget) obj;

        var value = target.get_value ();
        if (value == null) {
            return;
        }

        if (!drop_value_is_acceptable (value)) {
            target.reject ();
        }
    }

    bool drop_cb (Gtk.DropTarget target, Value value, double x, double y) {
        var file_list = ((Gdk.FileList) value).get_files ();
        var file_array = new File[file_list.length ()];

        int i = 0;
        foreach (var file in file_list) {
            file_array[i] = file;
            i++;
        }

        playback.open (file_array);
        return true;
    }
}
