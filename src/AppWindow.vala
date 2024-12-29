[GtkTemplate (ui = "/app/AppWindow.ui")]
class Daikhan.AppWindow : Adw.ApplicationWindow {
    [GtkChild] unowned Gtk.Stack stack;
    [GtkChild] unowned Daikhan.PlayerView player_view;
    [GtkChild] unowned Daikhan.WelcomeView welcome_view;
    public Daikhan.Playback playback { get; private set; }
    public Settings state_mem { get; private construct; }
    Daikhan.History playback_history;
    bool restoring_state = false;

    construct {
        playback = Daikhan.Playback.get_default ();
        state_mem = new Settings (Conf.APP_ID + ".state");
        playback_history = Daikhan.History.get_default ();

        playback.notify["target-state"].connect (notify_target_state_cb);
        playback.notify["current-track"].connect (notify_current_track_cb);
        playback.unsupported_file.connect (unsupported_file_cb);
        playback.unsupported_codec.connect (unsupported_codec_cb);
        playback.pipeline_error.connect (pipeline_error_cb);

        state_mem.bind ("width", this, "default-width", DEFAULT);
        state_mem.bind ("height", this, "default-height", DEFAULT);
        state_mem.bind ("maximized", this, "maximized", DEFAULT);
        state_mem.bind ("player-fullscreened", player_view, "fullscreened", DEFAULT);

        ActionEntry[] entries = {
            {"seek", seek_cb, "i"},
            {"volume_step", volume_step_cb, "d"},
            {"play_pause", play_pause_cb},
            {"audio", null, "i", "0", select_audio_cb},
            {"text", null, "i", "0", select_text_cb},
            {"video", null, "i", "0", select_video_cb},
            {"toggle_fullscreen", toggle_fullscreen_cb},
        };

        add_action_entries (entries, this);

        var repeat_act = new PropertyAction ("repeat", playback, "repeat");
        add_action (repeat_act);
    }

    public AppWindow (Gtk.Application app) {
        Object (application: app);
    }

    public void open (File[] files) {
        playback.open (files);
    }

    unowned Binding _binding;

    [GtkCallback]
    void on_view_changed () {
        if (stack.visible_child == player_view) {
            _binding = player_view.bind_property ("fullscreened", this, "fullscreened", SYNC_CREATE | BIDIRECTIONAL);
        } else {
            save_state ();
            playback.stop ();
            _binding.unbind ();
            unfullscreen ();
        }
    }

    uint inhibit_id = 0;
    void notify_target_state_cb () {
        if (playback.target_state == PLAYING) {
            inhibit_id = application.inhibit (this, IDLE, "Media is playing");
        } else if (inhibit_id > 0) {
            application.uninhibit (inhibit_id);
            inhibit_id = 0;
        }
    }

    void notify_current_track_cb () {
        if (playback.current_track < 0) {
            stack.visible_child = welcome_view;
            return;
        }

        stack.visible_child = player_view;

        var record = playback_history.find (playback.queue[playback.current_track].get_uri ());

        if (record == null) {
            return;
        }

        activate_action ("audio", new Variant ("i", record.audio_track));
        activate_action ("text", new Variant ("i", record.text_track));
        activate_action ("video", new Variant ("i", record.video_track));

        if (record.progress <= 0) {
            return;
        }

        if (restoring_state) {
            perform_seek (record.progress);
        } else {
            var dialog = new Daikhan.ActionDialog (this, _("Resume playback?"));
            dialog.response["yes"].connect (()=> { perform_seek (record.progress); });
            dialog.present ();
        }
    }

    void unsupported_file_cb () {
        var dialog = new Adw.AlertDialog (_("Unsupported File Type"), null);
        dialog.body = _("The file '%s' is not an audio or a video file.").printf (playback.filename);
        dialog.add_response ("ok", _("OK"));
        dialog.response.connect (() => { playback.next (); });
        dialog.present (this);
    }

    void unsupported_codec_cb (string debug_info) {
        var dialog = new Daikhan.ErrorDialog () {
            heading = _("Unsupported Codec"),
            additional_message = _(
                "Encoding of one or more streams in '%s' is not supported."
                ).printf (playback.filename),
            debug_info = debug_info.strip (),
        };

        dialog.response.connect (() => { playback.next (); });
        dialog.present (this);
    }

    void pipeline_error_cb (Gst.Object source, Error error, string debug_info) {
        var dbg_info = debug_info.strip ().replace ("\n", "\n\t");
        var info = (@"Source: $(source.name)\n"
                    + @"Domain: $(error.domain)\n"
                    + @"Code:   $(error.code)\n"
                    + @"Message: $(error.message)\n"
                    + "Debug info:\n"
                    + @"\t$(dbg_info)"
                    );

        var dialog = new Daikhan.ErrorDialog () { debug_info = info };
        dialog.response.connect (() => { playback.next (); });
        dialog.present (this);
    }

    void perform_seek (int64 position) {
        if (playback.current_state < Gst.State.PAUSED) {
            ulong handler_id = 0;
            handler_id = playback.notify["current-state"].connect (()=> {
                if (playback.current_state < Gst.State.PAUSED) {
                    return;
                }

                playback.seek_absolute (position);
                SignalHandler.disconnect (playback, handler_id);
            });
        } else {
            playback.seek_absolute (position);
        }
    }

    void seek_cb (SimpleAction action, Variant? step) {
        playback.seek (step.get_int32 ());
    }

    void volume_step_cb (SimpleAction action, Variant? step) {
        playback.volume += step.get_double ();
    }

    void select_audio_cb (SimpleAction action, Variant? stream_index) {
        playback.current_audio = stream_index.get_int32 ();

        if (playback.current_record != null) {
            playback.current_record.audio_track = stream_index.get_int32 ();
        }

        action.set_state (stream_index);
    }

    void select_text_cb (SimpleAction action, Variant? stream_index) {
        playback.current_text = stream_index.get_int32 ();

        if (playback.current_record != null) {
            playback.current_record.text_track = stream_index.get_int32 ();
        }

        action.set_state (stream_index);
    }

    void select_video_cb (SimpleAction action, Variant? stream_index) {
        playback.current_video = stream_index.get_int32 ();

        if (playback.current_record != null) {
            playback.current_record.video_track = stream_index.get_int32 ();
        }

        action.set_state (stream_index);
    }

    void play_pause_cb () {
        playback.toggle_playing ();
    }

    void toggle_fullscreen_cb () {
        fullscreened = (stack.visible_child == welcome_view) ? false : !fullscreened;
    }

    public void save_state () {
        if (playback.current_track < 0) {
            state_mem.set_strv ("queue", null);
            return;
        }

        state_mem.set_strv ("queue", playback.queue.to_uri_array ());
        state_mem.set_int ("track", playback.current_track);
        state_mem.set_boolean ("paused", playback.target_state == PAUSED);
    }

    public void restore_state () {
        restoring_state = true;

        var uri_array = state_mem.get_strv ("queue");

        playback.queue = new Daikhan.Queue.from_uri_array (uri_array);
        playback.load_track (state_mem.get_int ("track"));

        if (state_mem.get_boolean ("paused")) {
            playback.pause ();
        }

        restoring_state = false;
    }

    public override bool close_request () {
        stack.visible_child = welcome_view;
        return base.close_request ();
    }
}
