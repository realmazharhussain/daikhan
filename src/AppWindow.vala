[GtkTemplate (ui = "/app/AppWindow.ui")]
class Daikhan.AppWindow : Adw.ApplicationWindow {
    [GtkChild] unowned Daikhan.Title title_widget;
    public Daikhan.Playback playback { get; private set; }
    public Settings settings { get; private construct; }
    Daikhan.History playback_history;
    bool restoring_state = false;

    static construct {
        typeof(Daikhan.VideoArea).ensure();
    }

    construct {
        add_css_class ("player");
        title_widget.bind_property ("title", this, "title", SYNC_CREATE);

        playback = Daikhan.Playback.get_default();
        playback.notify["target-state"].connect(notify_target_state_cb);
        playback.notify["current-track"].connect(()=> {
            if (playback.current_track < 0) {
                return;
            }

            var record = playback_history.find (playback.queue[playback.current_track].get_uri ());

            if (record == null) {
                return;
            }

            activate_action ("audio", new Variant("i", record.audio_track));
            activate_action ("text", new Variant("i", record.text_track));
            activate_action ("video", new Variant("i", record.video_track));

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
        });

        playback.unsupported_file.connect (() => {
            var dialog = new Adw.MessageDialog (this, _("Unsupported File Type"), null);
            dialog.body = _("The file '%s' is not an audio or a video file.").printf (playback.filename);
            dialog.add_response ("ok", _("OK"));
            dialog.response.connect (() => { playback.next(); });
            dialog.present ();
        });

        playback.unsupported_codec.connect ((debug_info) => {
            var dialog = new Adw.MessageDialog (this, _("Unsupported Codec"),
                _("Encoding of one or more streams in '%s' is not supported.\n"
                  + "\n"
                  + "If this is unexpected, please, file a bug report with the following"
                  + " debug information.\n"
                  ).printf(playback.filename)
            );

            var debug_view = new Gtk.TextView () {
                editable = false,
                monospace = true,
            };
            debug_view.buffer.text = debug_info.strip ();

            var scrld_win = new Gtk.ScrolledWindow () {
                child = debug_view,
                vscrollbar_policy = NEVER,
            };

            dialog.extra_child = scrld_win;
            dialog.add_response ("report-bug", _("Report Bug"));
            dialog.add_response ("ok", _("OK"));
            dialog.default_response = "ok";
            dialog.response.connect (() => { playback.next(); });
            dialog.response["report-bug"].connect (() => {
                new Gtk.UriLauncher ("https://gitlab.com/daikhan/daikhan/-/issues")
                    .launch.begin (this, null);
            });
            dialog.present ();
        });

        playback_history = Daikhan.History.get_default ();

        settings = new Settings (Conf.APP_ID + ".state");
        settings.bind ("width", this, "default-width", DEFAULT);
        settings.bind ("height", this, "default-height", DEFAULT);
        settings.bind ("maximized", this, "maximized", DEFAULT);
        settings.bind ("volume", playback, "volume", DEFAULT);
        settings.bind ("repeat", playback, "repeat", DEFAULT);

        ActionEntry[] entries = {
            {"seek", seek_cb, "i"},
            {"volume_step", volume_step_cb, "d"},
            {"play_pause", play_pause_cb},
            {"audio", null, "i", "0", select_audio_cb},
            {"text", null, "i", "0", select_text_cb},
            {"video", null, "i", "0", select_video_cb},
            {"toggle_fullscreen", toggle_fullscreen_cb},
            {"about", about_cb},
        };

        add_action_entries(entries, this);

	var repeat_act = new PropertyAction ("repeat", playback, "repeat");
	add_action(repeat_act);

        notify["application"].connect(()=> {
            if (!(application is Application)) {
                return;
            }

            application.set_accels_for_action("win.toggle_fullscreen", {"f"});
            application.set_accels_for_action("win.play_pause", {"space"});
            application.set_accels_for_action("win.seek(+10)", {"Right", "l"});
            application.set_accels_for_action("win.seek(-10)", {"Left", "h"});
            application.set_accels_for_action("win.seek(+3)", {"<Shift>Right", "<Shift>l"});
            application.set_accels_for_action("win.seek(-3)", {"<Shift>Left", "<Shift>h"});
            application.set_accels_for_action("win.volume_step(+0.05)", {"Up", "k"});
            application.set_accels_for_action("win.volume_step(-0.05)", {"Down", "j"});
            application.set_accels_for_action("win.volume_step(+0.02)", {"<Shift>Up", "<Shift>k"});
            application.set_accels_for_action("win.volume_step(-0.02)", {"<Shift>Down", "<Shift>j"});
        });
    }

    public AppWindow (Gtk.Application app) {
        Object(application: app);
    }

    public void open(File[] files) {
        playback.open(files);
    }

    uint inhibit_id = 0;
    void notify_target_state_cb() {
        if (playback.target_state == PLAYING) {
            inhibit_id = application.inhibit(this, IDLE, "Media is playing");
        } else if (inhibit_id > 0) {
            application.uninhibit(inhibit_id);
            inhibit_id = 0;
        }
    }

    void perform_seek (int64 position) {
        if (playback.current_state < Gst.State.PAUSED) {
            ulong handler_id = 0;
            handler_id = playback.notify["current-state"].connect(()=> {
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
        playback.seek(step.get_int32());
    }

    void volume_step_cb (SimpleAction action, Variant? step) {
        playback.volume += step.get_double();
    }

    void select_audio_cb (SimpleAction action, Variant? stream_index) {
        if (stream_index.get_int32 () < 0) {
            playback.flags &= ~Daikhan.PlayFlags.AUDIO;
        } else {
            playback.flags |= AUDIO;
            playback.pipeline["current-audio"] = stream_index.get_int32 ();
        }

        if (playback.current_record != null) {
            playback.current_record.audio_track = stream_index.get_int32 ();
        }

        action.set_state(stream_index);
    }

    void select_text_cb (SimpleAction action, Variant? stream_index) {
        if (stream_index.get_int32 () < 0) {
            playback.flags &= ~Daikhan.PlayFlags.SUBTITLES;
        } else {
            playback.flags |= SUBTITLES;
            playback.pipeline["current-text"] = stream_index.get_int32 ();
        }

        if (playback.current_record != null) {
            playback.current_record.text_track = stream_index.get_int32 ();
        }

        action.set_state(stream_index);
    }

    void select_video_cb (SimpleAction action, Variant? stream_index) {
        if (stream_index.get_int32 () < 0) {
            playback.flags &= ~Daikhan.PlayFlags.VIDEO;
        } else {
            playback.flags |= VIDEO;
            playback.pipeline["current-video"] = stream_index.get_int32 ();
        }

        if (playback.current_record != null) {
            playback.current_record.video_track = stream_index.get_int32 ();
        }

        action.set_state(stream_index);
    }

    void play_pause_cb () {
        playback.toggle_playing();
    }

    void toggle_fullscreen_cb () {
        fullscreened = !fullscreened;
    }

    void about_cb () {
        var win = new Adw.AboutWindow () {
            transient_for = this,
            issue_url = "https://gitlab.com/daikhan/daikhan/-/issues/new",
            application_icon = Conf.APP_ID,
            application_name = _("Daikhan (Early Access)"),
            copyright = _("Copyright 2022-2023 Mazhar Hussain"),
            license_type = Gtk.License.AGPL_3_0,
            developer_name = _("Mazhar Hussain"),
            version = "pre-alpha"
        };

        win.present();
    }

    public void save_state () {
        if (playback.current_track < 0) {
            settings.set_strv ("queue", null);
            return;
        }

        settings.set_strv ("queue", playback.queue.to_uri_array ());
        settings.set_int ("track", playback.current_track);
        settings.set_boolean ("paused", playback.target_state == PAUSED);
    }

    public void restore_state () {
        restoring_state = true;

        var uri_array = settings.get_strv ("queue");

        playback.queue = new Daikhan.Queue.from_uri_array (uri_array);
        playback.load_track (settings.get_int ("track"));

        if (settings.get_boolean ("paused")) {
            playback.pause ();
        }

        restoring_state = false;
    }
}
