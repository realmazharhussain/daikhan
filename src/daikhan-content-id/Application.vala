class Daikhan.ContentId.Application : GLib.Application {
    bool batch_mode  = false;
    bool json_format  = false;
    bool content_only = false;
    bool uri_only = false;

    public Application () {
        Object (
            application_id: Conf.APP_ID + "-content-id",
            flags: GLib.ApplicationFlags.HANDLES_OPEN
        );
    }

    public override void constructed() {
        base.constructed();

        add_main_option("batch", 'b', NONE, NONE, _("Calculate content ids of multiple files"), null);
        add_main_option("content", 'c', NONE, NONE, _("Only show content id"), null);
        add_main_option("uri", 'u', NONE, NONE, _("Only show URI id"), null);
        add_main_option("json", 'j', NONE, NONE, _("Output JSON"), null);
    }

    public override void activate () {}
    public override void open(GLib.File[] files, string hint) {}

    public override int handle_local_options(GLib.VariantDict options) {
        var retval = base.handle_local_options(options);

        batch_mode = "batch" in options;
        json_format = "json" in options;
        content_only = "content" in options;
        uri_only = "uri" in options;

        if (content_only && uri_only) {
            printerr("%s\n", _("`--content`, and `--uri` are mutually exclusive. They cannot be used together."));
            return 1;
        }

        return retval;
    }

    public override bool local_command_line(
        ref weak string[] arguments,
        out int exit_status
    ) {
        base.local_command_line(ref arguments, out exit_status);

        if (exit_status != 0) {
            return true;
        } else if (!batch_mode && arguments.length != 2) {
            printerr("%s\n", _("You should provide exactly 1 file path, or use `--batch` option."));
            exit_status = 1;
            return true;
        } else if (batch_mode && arguments.length < 2) {
            printerr("%s\n", _("You should provide at least 1 file path."));
            exit_status = 1;
            return true;
        }

        if (batch_mode) {
            bool json_comma = false;
            if (json_format) {
                print("{");
            }

            for (int i = 1; arguments[i] != null; i++) {
                if (arguments[i] == "--") {
                    continue;
                }

                var file = File.new_for_commandline_arg(arguments[i]);

                try {
                    var content_id = Daikhan.ContentId.for_file(file);
                    var uri_id = XXH.v3_128bits(file.get_uri().data).to_string();

                    if (json_format) {
                        if (json_comma) {
                            print(", ");
                        }
                        print("\"%s\": {\"content_id\": \"%s\", \"uri_id\": \"%s\"}\n", arguments[i].replace("\"", "\\\""), content_id, uri_id);
                        json_comma = true;
                    } else if (content_only) {
                        print("%s %s\n", content_id, arguments[i]);
                    } else if (uri_only) {
                        print("%s %s\n", uri_id, arguments[i]);
                    } else {
                        print("%s:\n", arguments[i]);
                        print("  ContentId: %s\n  UriId: %s\n", content_id, uri_id);
                    }
                } catch (Error e) {
                    exit_status = 1;
                    printerr ("Error calculating content-id: %s\n", e.message);
                }
            }

            if (json_format) {
                print("}\n");
            }
        } else {
            var file = File.new_for_commandline_arg(arguments[1]);

            try {
                var content_id = Daikhan.ContentId.for_file(file);
                var uri_id = XXH.v3_128bits(file.get_uri().data).to_string();

                if (json_format) {
                    print("{\"ContentId\": \"%s\", \"UriId\": \"%s\"}\n", content_id, uri_id);
                } else if (content_only) {
                    print("%s\n", content_id);
                } else if (uri_only) {
                    print("%s\n", uri_id);
                } else {
                    print("ContentId: %s\nUriId: %s\n", content_id, uri_id);
                }
            } catch (Error e) {
                exit_status = 1;
                printerr ("Error calculating content-id: %s\n", e.message);
            }
        }

        return true;
    }
}
