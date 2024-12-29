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
public class Daikhan.PlayerView : Adw.Bin {
    public string title { get; set; default = ""; }
    public bool fullscreened { get; set; default = false; }

    [GtkChild] unowned Gtk.Widget empty;
    [GtkChild] unowned Adw.Spinner spinner;
    [GtkChild] unowned Gtk.Image icon;
    [GtkChild] unowned Gtk.Picture video;

    [GtkChild] unowned Gtk.Revealer top;
    [GtkChild] unowned Gtk.Stack content;
    [GtkChild] unowned Gtk.Revealer bottom;
    [GtkChild] unowned Gtk.HeaderBar headerbar;
    [GtkChild] unowned Daikhan.MediaControls controls;
    [GtkChild] unowned Adw.MultiLayoutView layout_controller;

    Settings settings = new Settings (Conf.APP_ID);
    Gdk.Cursor none_cursor = new Gdk.Cursor.from_name ("none", null);
    Gtk.EventControllerMotion headerbar_ctrlr;
    Gtk.EventControllerMotion controls_ctrlr;
    Daikhan.CursorTimeout[] timeouts = null;
    Source[] timeout_sources = null;
    double cursor_x_cached;
    double cursor_y_cached;

    static construct {
        set_css_name ("playerview");

        typeof (Daikhan.AppMenuButton).ensure ();
        typeof (Daikhan.Title).ensure ();
    }

    construct {
        var player = Daikhan.Player.get_default ();
        player.track_info.notify["image"].connect (content_cb);
        player.notify["n-audio"].connect (content_cb);
        player.notify["n-video"].connect (content_cb);
        player.notify["current-video"].connect (content_cb);
        player.notify["target-state"].connect (content_cb);
        content_cb ();

        bind_property ("fullscreened", headerbar, "halign", SYNC_CREATE,
            (binding, fullscreened, ref halign) => {
                halign = ((bool) fullscreened) ? Gtk.Align.CENTER : Gtk.Align.FILL;
                return true;
            }
        );

        notify["fullscreened"].connect (() => {
            top.transition_type = NONE;
            bottom.transition_type = NONE;

            do_motion_stuff ();

            top.transition_type = SLIDE_DOWN;
            bottom.transition_type = SLIDE_UP;
        });

        notify["fullscreened"].connect (update_layout);
        top.notify["child-revealed"].connect (update_layout);
        settings.changed["overlay-ui"].connect (update_layout);

        settings.changed["overlay-ui"].connect (() => {
            if (!fullscreened) {
                top.reveal_child = !settings.get_boolean ("overlay-ui");
                bottom.reveal_child = !settings.get_boolean ("overlay-ui");
            }
        });

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
                    bottom.reveal_child = false;
                }
            }, () => {
                top.reveal_child = true;
                bottom.reveal_child = true;
            });

        add_controller (Daikhan.DropTarget.new ());

        var click_gesture = new Gtk.GestureClick ();
        click_gesture.button = Gdk.BUTTON_PRIMARY;
        click_gesture.pressed.connect (click_gesture_pressed_cb);
        add_controller (click_gesture);

        add_controller (Daikhan.GestureDragWindow.new ());
    }

    private void update_layout () {
        // Wait for revealer's hide animation to complete before switching to overlay layout
        var temp_disable_overlay = layout_controller.layout_name != "overlay" && top.child_revealed;
        var use_overlay = fullscreened || (settings.get_boolean ("overlay-ui") && !temp_disable_overlay);

        layout_controller.layout_name = use_overlay ? "overlay" : "box";
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

    TimeoutSource? click_timeout_source = null;

    void click_gesture_pressed_cb (Gtk.GestureClick gesture,
                                   int n_press, double x, double y)
    {
        if (click_timeout_source != null && !click_timeout_source.is_destroyed ()) {
            click_timeout_source.destroy ();
        }

        if (headerbar_ctrlr.contains_pointer || controls_ctrlr.contains_pointer) {
            return;
        }

        if (n_press == 2) {
            var window = this.get_root () as Daikhan.AppWindow;
            window.activate_action ("toggle_fullscreen", null);
            gesture.set_state (CLAIMED);
            gesture.reset ();
        } else if (n_press == 1 && (fullscreened || settings.get_boolean ("overlay-ui"))) {
            click_timeout_source = new TimeoutSource (250);
            click_timeout_source.set_callback (() => {
                top.reveal_child = !top.reveal_child;
                bottom.reveal_child = !bottom.reveal_child;
                cursor = none_cursor;
                return Source.REMOVE;
            });
            click_timeout_source.attach ();
        }

    }

    private void content_cb () {
        var player = Daikhan.Player.get_default ();

        var image = player.track_info.image;
        Gdk.Paintable? image_paintable = null;
        if (image != null) {
            try {
                image_paintable = Gdk.Texture.from_file (image);
            } catch (Error err) {
                critical ("%s:%s:%s", err.domain.to_string (), err.code.to_string (), err.message);
            }
        }

        if (player.n_video > 0 && player.current_video >= 0) {
            video.paintable = player.paintable;
            video.remove_css_class ("album_art");
            video.add_css_class ("video");
            content.visible_child = video;
        } else if (player.n_audio > 0 && player.current_audio >= 0) {
            if (image_paintable != null) {
                video.paintable = image_paintable;
                video.remove_css_class ("video");
                video.add_css_class ("album_art");
                content.visible_child = video;
            } else {
                content.visible_child = icon;
            }
        } else if (player.target_state > player.current_state) {
            content.visible_child = spinner;
        } else {
            content.visible_child = empty;
        }
    }
}
