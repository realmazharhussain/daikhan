delegate void Envision.CursorTimeoutCallback();

class Envision.CursorTimeout {
    public uint delay { get; set; default = 0; }
    public CursorTimeoutCallback callback;
    public CursorTimeoutCallback motion_callback;

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
class Envision.VideoArea : Adw.Bin {
    [GtkChild] unowned Gtk.Revealer top_revealer;
    [GtkChild] unowned Envision.Title title_overlay;
    [GtkChild] unowned MediaControls controls_overlay;

    Gtk.EventControllerMotion title_ctrlr;
    Gtk.EventControllerMotion ctrls_ctrlr;
    Envision.CursorTimeout[] timeouts = null;
    Source[] timeout_sources = null;

    double cursor_x_cached;
    double cursor_y_cached;
    Gdk.Cursor none_cursor = new Gdk.Cursor.from_name("none", null);

    static construct {
        typeof(Video).ensure();
    }

    construct {
        var ctrlr = new Gtk.EventControllerMotion();
        ctrlr.motion.connect(cursor_motion_cb);
        this.add_controller(ctrlr);

        title_ctrlr = new Gtk.EventControllerMotion();
        title_overlay.add_controller(title_ctrlr);

        ctrls_ctrlr = new Gtk.EventControllerMotion();
        controls_overlay.add_controller(ctrls_ctrlr);

        this.cursor = none_cursor;

        add_motion_timeout (750,
            () => { // Callback for when the cursor stops moving
                this.cursor = none_cursor;
            }, () => { // Callback for when the cursor starts moving
                this.cursor = null;
            });

        add_motion_timeout (1750,
            () => {
                top_revealer.reveal_child = false;
            }, () => {
                top_revealer.reveal_child = true;
            });

        var root_expr = new Gtk.PropertyExpression(typeof(VideoArea), null, "root");
        var fllscrn_expr = new Gtk.PropertyExpression(typeof(Gtk.Window), root_expr, "fullscreened");
        fllscrn_expr.bind(top_revealer, "visible", this);
    }

    Envision.CursorTimeout add_motion_timeout (uint interval,
                                               CursorTimeoutCallback callback,
                                               CursorTimeoutCallback motion_callback)
    {
        var timeout = new Envision.CursorTimeout(interval, callback, motion_callback);
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
        if (x == cursor_x_cached && y == cursor_y_cached)
            return;

        cursor_x_cached = x;
        cursor_y_cached = y;

        // Run motion callbacks
        foreach (var timeout in timeouts)
            timeout.motion_callback();

        // Destroy any pending timeouts
        foreach (var src in timeout_sources)
            if (!src.is_destroyed())
                src.destroy();

        timeout_sources = null;

        // No need to set up timeouts if the cursor is on an interface widget
        if (title_ctrlr.contains_pointer || ctrls_ctrlr.contains_pointer)
            return;

        // Set up timeouts

        timeout_sources.resize(timeouts.length);

        for (int i = 0; i < timeout_sources.length; i++) {
            var src = new TimeoutSource(timeouts[i].delay);
            src.set_callback((SourceFunc) timeouts[i].callback);
            src.attach();
            timeout_sources[i] = src;
        }
    }
}
