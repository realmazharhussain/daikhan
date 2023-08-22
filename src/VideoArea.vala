delegate void Daikhan.CursorTimeoutCallback();

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

[GtkTemplate (ui = "/app/video-area.ui")]
class Daikhan.VideoArea : Adw.Bin {
    [GtkChild] unowned Gtk.Picture video;
    [GtkChild] unowned Gtk.Revealer top_revealer;
    [GtkChild] unowned Daikhan.Title title_overlay;
    [GtkChild] unowned MediaControls controls_overlay;

    Gtk.EventControllerMotion title_ctrlr;
    Gtk.EventControllerMotion ctrls_ctrlr;
    Daikhan.CursorTimeout[] timeouts = null;
    Source[] timeout_sources = null;
    Playback playback;

    double cursor_x_cached;
    double cursor_y_cached;
    Gdk.Cursor none_cursor = new Gdk.Cursor.from_name("none", null);

    construct {
        playback = Playback.get_default();

        video.paintable = playback.paintable;

        var ctrlr = new Gtk.EventControllerMotion();
        ctrlr.motion.connect(cursor_motion_cb);
        this.add_controller(ctrlr);

        title_ctrlr = new Gtk.EventControllerMotion();
        title_overlay.add_controller(title_ctrlr);

        ctrls_ctrlr = new Gtk.EventControllerMotion();
        controls_overlay.add_controller(ctrls_ctrlr);

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

        var target = new Gtk.DropTarget(typeof(Gdk.FileList), COPY);
        target.preload = true;
        target.notify["value"].connect(notify_drop_value_cb);
        target.drop.connect (drop_cb);
        add_controller(target);

        var click_gesture = new Gtk.GestureClick();
        click_gesture.button = Gdk.BUTTON_PRIMARY;
        click_gesture.pressed.connect(click_gesture_pressed_cb);
        add_controller(click_gesture);

        var drag_gesture = new Gtk.GestureDrag();
        drag_gesture.drag_update.connect(drag_gesture_update_cb);
        add_controller(drag_gesture);

        var root_expr = new Gtk.PropertyExpression(typeof(VideoArea), null, "root");
        var fllscrn_expr = new Gtk.PropertyExpression(typeof(Gtk.Window), root_expr, "fullscreened");
        fllscrn_expr.bind(top_revealer, "visible", this);
    }

    Daikhan.CursorTimeout add_motion_timeout (uint interval,
                                               CursorTimeoutCallback callback,
                                               CursorTimeoutCallback motion_callback)
    {
        var timeout = new Daikhan.CursorTimeout(interval, callback, motion_callback);
        timeouts.resize(timeouts.length + 1);
        timeouts[timeouts.length - 1] = timeout;
        return timeout;
    }

    void cursor_motion_cb(Gtk.EventControllerMotion ctrlr,
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
            timeout.motion_callback();

        // Destroy any pending timeouts
        foreach (var src in timeout_sources) {
            if (!src.is_destroyed()) {
                src.destroy();
            }
        }

        timeout_sources = null;

        // No need to set up timeouts if the cursor is on an interface widget
        if (title_ctrlr.contains_pointer || ctrls_ctrlr.contains_pointer) {
            return;
        }

        // Set up timeouts

        timeout_sources.resize(timeouts.length);

        for (int i = 0; i < timeout_sources.length; i++) {
            var src = new TimeoutSource(timeouts[i].delay);
            src.set_callback((SourceFunc) timeouts[i].callback);
            src.attach();
            timeout_sources[i] = src;
        }
    }

    void click_gesture_pressed_cb(Gtk.GestureClick gesture,
                                  int n_press, double x, double y)
    {
        // Don't do anything if the cursor is on media controls
        if (ctrls_ctrlr.contains_pointer) {
            return;
        }

        var window = this.get_root() as Daikhan.AppWindow;
        assert(window != null);

        if (n_press != 2) {
            return;
        }

        gesture.set_state(CLAIMED);
        window.activate_action("toggle_fullscreen", null);
        gesture.reset();
    }

    bool drop_value_is_acceptable(Value value) {
        var files = ((Gdk.FileList) value).get_files ();

        foreach (var file in files) {
            if (Daikhan.Utils.is_file_type_supported(file)) {
                return true;
            }
        }

        return false;
    }

    void notify_drop_value_cb(Object obj, ParamSpec pspec) {
        var target = (Gtk.DropTarget) obj;

        var value = target.get_value();
        if (value == null) {
            return;
        }

        if (!drop_value_is_acceptable(value)) {
            target.reject();
        }
    }

    bool drop_cb(Gtk.DropTarget target, Value value, double x, double y) {
        var file_list = ((Gdk.FileList) value).get_files();
        var file_array = new File[file_list.length()];

        int i = 0;
        foreach (var file in file_list) {
            file_array[i] = file;
            i++;
        }

        playback.open(file_array);
        return true;
    }

    void drag_gesture_update_cb(Gtk.GestureDrag gesture,
                                double offset_x, double offset_y)
    {
        /* FIXME: I do not understand how all this works. I copied it from source code of
         * GtkWindowHandle <gtk/gtkwindowhandle.c>. I commented what I understood but I am
         * confident that I am wrong about some (or lot) of this stuff. I also renamed
         * variables to what I thought are more appropriate names in order to make the code
         * easier to understand.
         */

        // We only recognize the gesture if the threshold has been crossed in any direction.
        var threshold = this.get_settings().gtk_dnd_drag_threshold;
        if (offset_x.abs() < threshold && offset_y.abs() < threshold) {
            return;
        }

        var native = get_native();
        var toplevel = native.get_surface() as Gdk.Toplevel;

        // Cannot move window if it is fullscreen
        if (((Gtk.Window) native).fullscreened) {
            return;
        }

        // If toplevel is NULL, it means something went really wrong.
        assert(toplevel != null);

        gesture.set_state(CLAIMED);

        // Start point of Drag Gesture (relative to self i.e. Video widget)
        double start_x_video, start_y_video;
        gesture.get_start_point(out start_x_video, out start_y_video);

        var start_pt_video = Graphene.Point() {
            x = (float) start_x_video,
            y = (float) start_y_video,
        };

        // Start point of Drag Gesture (relative to Gtk.Native of self i.e. Window)
        Graphene.Point start_pt_native;
        compute_point(native, start_pt_video, out start_pt_native);

        // Surface Coordinates of the Window itself
        double native_x, native_y;
        native.get_surface_transform(out native_x, out native_y);

        // Surface Coordinates of Gesture's start point
        var start_x = native_x + start_pt_native.x;
        var start_y = native_y + start_pt_native.y;

        toplevel.begin_move(gesture.get_device(),
                            (int) gesture.get_current_button(),
                            start_x, start_y,
                            gesture.get_current_event_time());

        gesture.reset();
    }
}
