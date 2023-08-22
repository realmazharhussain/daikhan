internal StreamMenuBuilder menu_builder_instance;

class StreamMenuBuilder : Object {
    public Menu menu;

    Menu audio_menu;
    Menu subtitle_menu;
    Menu video_menu;
    Daikhan.Playback playback;

    construct {
        menu = new Menu ();

        audio_menu = new Menu ();
        video_menu = new Menu ();
        subtitle_menu = new Menu ();

        menu.append_submenu (_("Audio"), audio_menu);
        menu.append_submenu (_("Subtitles"), subtitle_menu);
        menu.append_submenu (_("Video"), video_menu);

        playback = Daikhan.Playback.get_default ();
        Signal.connect_swapped (playback.pipeline, "audio-changed", (Callback) update_audio_cb, this);
        Signal.connect_swapped (playback.pipeline, "text-changed", (Callback) update_text_cb, this);
        Signal.connect_swapped (playback.pipeline, "video-changed", (Callback) update_video_cb, this);

        var repeat_menu = new Menu ();
        menu.append_submenu (_("Repeat"), repeat_menu);
        repeat_menu.append (_("Off"), "win.repeat(\"off\")");
        repeat_menu.append (_("Single File"), "win.repeat(\"track\")");
        repeat_menu.append (_("Whole Queue"), "win.repeat(\"queue\")");
    }

    public static StreamMenuBuilder get_default () {
        menu_builder_instance = menu_builder_instance ?? new StreamMenuBuilder ();
        return menu_builder_instance;
    }

    public static Menu get_menu () {
        return get_default().menu;
    }

    void update_audio_cb () {
        Idle.add (() => {
            update_model (audio_menu);
            return Source.REMOVE;
        });
    }

    void update_text_cb () {
        Idle.add (() => {
            update_model (subtitle_menu);
            return Source.REMOVE;
        });
    }

    void update_video_cb () {
        Idle.add (() => {
            update_video_model ();
            return Source.REMOVE;
        });
    }

    void update_model (Menu model) {
        var type = "";

        if (model == audio_menu) {
            type = "audio";
        } else if (model == subtitle_menu) {
            type = "text";
        } else {
            assert_not_reached ();
        }

        model.remove_all ();

        Gst.TagList tags;
        string language_code = null, language_name = null;
        Object pipeline = playback.pipeline;

        int total_streams;
        pipeline.get (@"n-$type", out total_streams);


        if (total_streams == 0) {
            return;
        }

        model.append (_("Off"), @"win.$type(-1)");

        for (int stream = 0; stream < total_streams; stream++) {
            Signal.emit_by_name (pipeline, @"get-$type-tags", stream, out tags);

            if (tags == null) {
                // Nothing to do here
            } else if (tags.get_string (Gst.Tags.LANGUAGE_CODE, out language_code)) {
                language_name = Gst.Tag.get_language_name (language_code);
            } else {
                tags.get_string (Gst.Tags.LANGUAGE_NAME, out language_name);
            }

            if (language_name == null) {
                language_name = _("Unknown Language");
            }

            model.append (language_name, @"win.$type($stream)");
        }
    }

    void update_video_model () {
        video_menu.remove_all ();

        int total_streams;
        Object pipeline = playback.pipeline;
        pipeline.get (@"n-video", out total_streams);

        if (total_streams == 0) {
            return;
        }

        video_menu.append (_("Off"), "win.video(-1)");

        if (total_streams == 1) {
            video_menu.append (_("On"), "win.video(0)");
        } else for (int stream = 0; stream < total_streams; stream++) {
            // Translators: Keep %i as is. It will be replaced by the track number for each track.
            video_menu.append (_("Track %i").printf(stream + 1), @"win.video($stream)");
        }
    }
}
