namespace Daikhan.GestureDragWindow {
    public Gtk.GestureDrag new () {
        var gesture = new Gtk.GestureDrag ();
        gesture.drag_update.connect (on_drag_update);
        return gesture;
    }

    void on_drag_update (Gtk.GestureDrag gesture, double offset_x, double offset_y) {
        /* FIXME: I do not understand how all this works. I copied it from source code of
         * GtkWindowHandle <gtk/gtkwindowhandle.c>. I commented what I understood but I am
         * confident that I am wrong about some (or lot) of this stuff. I also renamed
         * variables to what I thought are more appropriate names in order to make the code
         * easier to understand.
         */

        // We only recognize the gesture if the threshold has been crossed in any direction.
        var threshold = gesture.widget.get_settings ().gtk_dnd_drag_threshold;
        if (offset_x.abs () < threshold && offset_y.abs () < threshold) {
            return;
        }

        var native = gesture.widget.get_native ();
        var toplevel = native.get_surface () as Gdk.Toplevel;

        // Cannot move window if it is fullscreen
        if (((Gtk.Window) native).fullscreened) {
            return;
        }

        // If toplevel is NULL, it means something went really wrong.
        assert (toplevel != null);

        gesture.set_state (CLAIMED);

        // Start point of Drag Gesture (relative to self i.e. Video widget)
        double start_x_video, start_y_video;
        gesture.get_start_point (out start_x_video, out start_y_video);

        var start_pt_video = Graphene.Point () {
            x = (float) start_x_video,
            y = (float) start_y_video,
        };

        // Start point of Drag Gesture (relative to Gtk.Native of self i.e. Window)
        Graphene.Point start_pt_native;
        gesture.widget.compute_point (native, start_pt_video, out start_pt_native);

        // Surface Coordinates of the Window itself
        double native_x, native_y;
        native.get_surface_transform (out native_x, out native_y);

        // Surface Coordinates of Gesture's start point
        var start_x = native_x + start_pt_native.x;
        var start_y = native_y + start_pt_native.y;

        toplevel.begin_move (gesture.get_device (),
                             (int) gesture.get_current_button (),
                             start_x, start_y,
                             gesture.get_current_event_time ());

        gesture.reset ();
    }
}
