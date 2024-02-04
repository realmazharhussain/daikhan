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

[GtkTemplate (ui = "/app/PlayerView.ui")]
public class Daikhan.PlayerView : Gtk.Widget {
    public string title { get; set; default = ""; }
    public bool fullscreened { get; set; default = false; }

    [GtkChild] unowned Gtk.Revealer top;
    [GtkChild] unowned Gtk.Picture video;
    [GtkChild] unowned Gtk.Revealer bottom;
    [GtkChild] unowned Gtk.HeaderBar headerbar;
    [GtkChild] unowned Daikhan.MediaControls controls;

    Settings settings = new Settings (Conf.APP_ID);
    Gdk.Cursor none_cursor = new Gdk.Cursor.from_name ("none", null);
    Gtk.EventControllerMotion headerbar_ctrlr;
    Gtk.EventControllerMotion controls_ctrlr;
    Daikhan.CursorTimeout[] timeouts = null;
    Source[] timeout_sources = null;
    double cursor_x_cached;
    double cursor_y_cached;
    bool overlay_ui_turning_on = false;

    static construct {
        set_css_name ("playerview");

        typeof (Daikhan.AppMenuButton).ensure ();
        typeof (Daikhan.Title).ensure ();
    }

    construct {
        video.paintable = Daikhan.Playback.get_default ().paintable;

        bind_property ("fullscreened", headerbar, "halign", SYNC_CREATE,
            (binding, fullscreened, ref halign) => {
                halign = ((bool) fullscreened) ? Gtk.Align.CENTER : Gtk.Align.FILL;
                return true;
            }
        );

        // notify["fullscreened"].connect (queue_allocate);
        // notify["fullscreened"].connect (queue_resize);
        // notify["fullscreened"].connect (queue_draw);

        notify["fullscreened"].connect (() => {
            top.transition_type = NONE;
            bottom.transition_type = NONE;

            do_motion_stuff ();

            top.transition_type = SLIDE_DOWN;
            bottom.transition_type = SLIDE_UP;
        });

        settings.changed["overlay-ui"].connect (() => {
            if (!fullscreened) {
                bool overlay_ui = settings.get_boolean ("overlay-ui");
                top.reveal_child = !overlay_ui;
                overlay_ui_turning_on = overlay_ui;
            }
        });

        top.notify["child-revealed"].connect (() => { overlay_ui_turning_on = false; });

        var ctrlr = new Gtk.EventControllerMotion ();
        ctrlr.motion.connect (cursor_motion_cb);
        this.add_controller (ctrlr);

        headerbar_ctrlr = new Gtk.EventControllerMotion ();
        headerbar.add_controller (headerbar_ctrlr);

        controls_ctrlr = new Gtk.EventControllerMotion ();
        controls.add_controller (controls_ctrlr);

        this.cursor = none_cursor;

        add_motion_timeout (500,
            () => { // Callback for when the cursor stops moving
                this.cursor = none_cursor;
            }, () => { // Callback for when the cursor starts moving
                this.cursor = null;
            });

        add_motion_timeout (2000,
            () => {
                if (fullscreened || settings.get_boolean ("overlay-ui")) {
                    top.reveal_child = false;
                }
            }, () => {
                top.reveal_child = true;
            });

        add_controller (Daikhan.DropTarget.new ());

        var click_gesture = new Gtk.GestureClick ();
        click_gesture.button = Gdk.BUTTON_PRIMARY;
        click_gesture.pressed.connect (click_gesture_pressed_cb);
        add_controller (click_gesture);

        add_controller (Daikhan.GestureDragWindow.new ());
    }

    public override void measure (Gtk.Orientation orientation,
                                  int for_size,
                                  out int minimum,
                                  out int natural,
                                  out int minimum_baseline,
                                  out int natural_baseline)
    {
        int top_min, video_min, bottom_min;
        int top_nat, video_nat, bottom_nat;

        top.measure (orientation, -1, out top_min, out top_nat, null, null);
        video.measure (orientation, for_size, out video_min, out video_nat, null, null);
        bottom.measure (orientation, -1, out bottom_min, out bottom_nat, null, null);

        if (orientation == HORIZONTAL) {
            minimum = int.max (video_min, int.max (top_min, bottom_min));
            natural = int.max (video_nat, int.max (top_nat, bottom_nat));
        } else if (fullscreened || (settings.get_boolean ("overlay-ui") && !overlay_ui_turning_on)) {
            minimum = int.max (video_min, top_min + bottom_min);
            natural = int.max (video_nat, top_nat + bottom_nat);
        } else {
            minimum = top_min + video_min + bottom_min;
            natural = top_nat + video_nat + bottom_nat;
        }

        minimum_baseline = -1;
        natural_baseline = -1;
    }

    private static Gsk.Transform? y_transform (int y_offset) {
        return new Gsk.Transform ().translate (Graphene.Point () { x = 0, y = y_offset });
    }

    public override void size_allocate (int width, int height, int baseline) {
        int top_min, bottom_min, video_min;
        int top_nat, bottom_nat;

        top.measure (VERTICAL, -1, out top_min, out top_nat, null, null);
        bottom.measure (VERTICAL, -1, out bottom_min, out bottom_nat, null, null);
        video.measure (VERTICAL, -1, out video_min, null, null, null);

        int top_height = (height - video_min - bottom_min).clamp (top_min, top_nat);

        int bottom_height = (height - video_min - top_min).clamp (bottom_min, bottom_nat);
        int bottom_offset = height - bottom_height;

        bool overlay = fullscreened || (settings.get_boolean ("overlay-ui") && !overlay_ui_turning_on);
        int video_height = overlay ? height : int.max (0, height - top_height - bottom_height);
        int video_offset = overlay ? 0 : top_height;

        top.allocate (width, top_height, -1, null);
        video.allocate (width, video_height, -1, y_transform (video_offset));
        bottom.allocate (width, bottom_height, -1, y_transform (bottom_offset));
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

        do_motion_stuff ();
    }

    void do_motion_stuff () {

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
        if (headerbar_ctrlr.contains_pointer || controls_ctrlr.contains_pointer) {
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
        if (controls_ctrlr.contains_pointer) {
            return;
        }

        var window = this.get_root () as Daikhan.AppWindow;
        assert (window != null);

        if (n_press == 1 &&
            !(headerbar_ctrlr.contains_pointer || controls_ctrlr.contains_pointer) &&
            (fullscreened || settings.get_boolean ("overlay-ui")))
        {
            top.reveal_child = !top.reveal_child;
            cursor = none_cursor;
        } else if (n_press == 2) {
            window.activate_action ("toggle_fullscreen", null);
        } else {
            return;
        }

        gesture.set_state (CLAIMED);
        gesture.reset ();
    }
}
