class Video : Adw.Bin {
    Gst.Element? video_sink;
    unowned Playback playback;

    construct {
        var image = new Gtk.Picture();

        set("css_name", "video");
        child = image;
        hexpand = true;
        vexpand = true;

        dynamic var gtksink = Gst.ElementFactory.make("gtk4paintablesink", "null");
        dynamic Gdk.Paintable paintable = gtksink.paintable;
        image.paintable = paintable;

        if (paintable.gl_context != null) {
            var glsink = Gst.ElementFactory.make("glsinkbin", "glsinkbin");
            glsink["sink"] = gtksink;
            video_sink = glsink;
        }
        else {
            video_sink = gtksink;
        }

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

        var motion_ctrlr = new Gtk.EventControllerMotion();
        motion_ctrlr.motion.connect(cursor_motion_cb);
        add_controller(motion_ctrlr);

        playback = Playback.get_default();
        playback.notify["pipeline"].connect(notify_pipeline_cb);
    }

    Gst.Pipeline? last_pipeline = null;
    void notify_pipeline_cb() {
        if (last_pipeline != null) {
            last_pipeline["video-sink"] = null;
        }
        if (playback.pipeline != null) {
            playback.pipeline["video-sink"] = video_sink;
        }

        last_pipeline = playback.pipeline;
    }

    bool drop_value_is_acceptable(Value value) {
        var flist = (Gdk.FileList) value;
        var file = flist.get_files().last().data;
        string? mimetype;

        try {
            mimetype = file.query_info("standard::", NONE).get_content_type();
        } catch (Error err) {
            return false;
        }

        if (mimetype == null)
            return false;

        if (mimetype.has_prefix("video/"))
            return true;

        if (mimetype.has_prefix("audio/"))
            return true;

        return false;
    }

    void notify_drop_value_cb(Object obj, ParamSpec pspec) {
        var target = (Gtk.DropTarget) obj;

        var value = target.get_value();
        if (value == null)
            return;

        if (!drop_value_is_acceptable(value))
            target.reject();
    }

    bool drop_cb(Gtk.DropTarget target, Value value, double x, double y) {
        var file = ((Gdk.FileList) value).get_files().last().data;
        return playback.open_file(file);
    }

    void click_gesture_pressed_cb(Gtk.GestureClick gesture,
                                  int n_press, double x, double y)
    {
        var window = this.get_root() as PlayerWindow;
        assert(window != null);

        if (n_press != 2)
            return;

        gesture.set_state(CLAIMED);
        window.activate_action("toggle_fullscreen", null);
        gesture.reset();
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
        if (offset_x.abs() < threshold && offset_y.abs() < threshold)
            return;

        var native = get_native();
        var toplevel = native.get_surface() as Gdk.Toplevel;

        // If toplevel is NULL, it means something went really wrong.
        assert(toplevel != null);

        gesture.set_state(CLAIMED);

        // Start point of Drag Gesture (relative to self i.e. Video widget)
        double start_x_video, start_y_video;
        gesture.get_start_point(out start_x_video, out start_y_video);

        // Start point of Drag Gesture (relative to Gtk.Native of self i.e. Window)
        double start_x_native, start_y_native;
        translate_coordinates(native, start_x_video, start_y_video,
                              out start_x_native, out start_y_native);

        // Surface Coordinates of the Window itself
        double native_x, native_y;
        native.get_surface_transform(out native_x, out native_y);

        // Surface Coordinates of Gesture's start point
        var start_x = native_x + start_x_native;
        var start_y = native_y + start_y_native;

        toplevel.begin_move(gesture.get_device(),
                            (int) gesture.get_current_button(),
                            start_x, start_y,
                            gesture.get_current_event_time());

        gesture.reset();
    }

    double cursor_x_cached;
    double cursor_y_cached;
    TimeoutSource? cursor_timeout_source;

    void cursor_motion_cb(Gtk.EventControllerMotion ctrlr,
                          double x, double y)
    {
        /* Gtk keeps emitting motion signal with the same x & y values when the
         * cursor is over the current widget (Video) and video is playing, even 
         * if the cursor is actually not moving anymore.
         */
        if (x == cursor_x_cached && y == cursor_y_cached)
            return;

        cursor_x_cached = x;
        cursor_y_cached = y;

        // Show cursor
        set_cursor_from_name("default");

        /* Reset cursor hide timer by destroying the old one (if any exists and is
         * not already destroyed) and creating a new one.
         */

        if (cursor_timeout_source != null && !cursor_timeout_source.is_destroyed())
            cursor_timeout_source.destroy();

        cursor_timeout_source = new TimeoutSource(700);
        cursor_timeout_source.set_callback(() => {
            set_cursor_from_name("none");
            return Source.REMOVE;
        });
        cursor_timeout_source.attach();
    }
}
