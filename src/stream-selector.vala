internal StreamMenuBuilder menu_builder_instance;

class StreamMenuBuilder : Object {
    public Menu menu;

    Menu audio_streams;
    Menu subtitle_streams;
    Menu video_streams;
    Playback playback;

    construct {
        menu = new Menu ();

        var audio_menu = new Menu ();
        audio_streams = new Menu ();
        menu.append_submenu ("Audio", audio_menu);
        audio_menu.append ("Off", "win.select_audio(-1)");
        audio_menu.append_section (null, audio_streams);

        var subtitle_menu = new Menu ();
        subtitle_streams = new Menu ();
        menu.append_submenu ("Subtitles", subtitle_menu);
        subtitle_menu.append ("Off", "win.select_text(-1)");
        subtitle_menu.append_section (null, subtitle_streams);

        var video_menu = new Menu ();
        video_streams = new Menu ();
        menu.append_submenu ("Video", video_menu);
        video_menu.append ("Off", "win.select_video(-1)");
        video_menu.append_section (null, video_streams);

        playback = Playback.get_default ();
        Signal.connect_swapped (playback.pipeline, "audio-changed", (Callback) update_audio_cb, this);
        Signal.connect_swapped (playback.pipeline, "text-changed", (Callback) update_text_cb, this);
        Signal.connect_swapped (playback.pipeline, "video-changed", (Callback) update_video_cb, this);

        var repeat_menu = new Menu ();
        menu.append_submenu ("Repeat", repeat_menu);
        repeat_menu.append ("Off", "win.repeat(\"off\")");
        repeat_menu.append ("Single File", "win.repeat(\"track\")");
        repeat_menu.append ("Whole Queue", "win.repeat(\"queue\")");
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
            update_model (audio_streams);
            return Source.REMOVE;
        });
    }

    void update_text_cb () {
        Idle.add (() => {
            update_model (subtitle_streams);
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

        if (model == audio_streams)
            type = "audio";
        else if (model == subtitle_streams)
            type = "text";
        else
            assert_not_reached ();

        model.remove_all ();

        Gst.TagList tags;
        string language_code = null, language_name = null;
        Object pipeline = playback.pipeline;

        int total_streams;
        pipeline.get (@"n-$type", out total_streams);


        if (total_streams == 1) {
            model.append (@"On", @"win.select_$type(0)");
        } else for (int stream = 0; stream < total_streams; stream++) {
            Signal.emit_by_name (pipeline, @"get-$type-tags", stream, out tags);

            if (tags == null) {
                // Nothing to do here
            } else if (tags.get_string (Gst.Tags.LANGUAGE_CODE, out language_code)) {
                language_name = Gst.Tag.get_language_name (language_code);
            } else {
                tags.get_string (Gst.Tags.LANGUAGE_NAME, out language_name);
            }

            if (language_name == null)
                language_name = "Unknown Language";

            model.append (language_name, @"win.select_$type($stream)");
        }
    }

    void update_video_model () {
        video_streams.remove_all ();

        int total_streams;
        Object pipeline = playback.pipeline;
        pipeline.get (@"n-video", out total_streams);

        if (total_streams == 1) {
            video_streams.append (@"On", @"win.select_video(0)");
        } else for (int stream = 0; stream < total_streams; stream++) {
            video_streams.append (@"Track $(stream + 1)", @"win.select_video($stream)");
        }
    }
}
