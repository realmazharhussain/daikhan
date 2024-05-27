public abstract class Daikhan.MPRIS.ServerBase : Object {
    public weak DBusConnection conn { get; construct; }
    public string interface_name { get; construct; default = ""; }
    StringBuilder changed_property_name = new StringBuilder.sized (32);

    ServerBase(DBusConnection conn, string interface_name) {
        Object(conn: conn, interface_name: interface_name);
    }

    public override void constructed () {
        base.constructed ();
        notify.connect (send_property_change);
    }

    void send_property_change(ParamSpec pspec) {
        changed_property_name.truncate ();
        foreach (var part in pspec.name.split ("-")) {
            changed_property_name.append (capitalize (part));
        }

        var changed_props = new HashTable<string, Variant>(str_hash, str_equal);
        var invalidated_props = new string[] {};

        var property_value = get_property_value (pspec);
        if (property_value != null) {
            changed_props[changed_property_name.str] = property_value;
        } else {
            invalidated_props.resize (1);
            invalidated_props[0] = changed_property_name.str;
        }

        var params_builder = new VariantBuilder (new VariantType ("(sa{sv}as)"));
        params_builder.add_value (interface_name);
        params_builder.add_value (changed_props);
        params_builder.add_value (invalidated_props);
        var parameters = params_builder.end ();

        try {
            conn.emit_signal (null, "/org/mpris/MediaPlayer2", "org.freedesktop.DBus.Properties", "PropertiesChanged", parameters);
        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }
    }

    protected abstract Variant? get_property_value(ParamSpec pspec);

    private unowned string capitalize (string input) {
        unowned var input_a = input.data;
        input_a[0] -= 32;
        return input;
    }
}

[DBus (name = "org.mpris.MediaPlayer2")]
public class Daikhan.MPRIS.App: Daikhan.MPRIS.ServerBase {
    public App (DBusConnection conn) {
        base (conn, "org.mpris.MediaPlayer2");
    }

    /* Real */
    public string desktop_entry { owned get; default = Conf.APP_ID; }
    public string identity { owned get; default = _("Daikhan (Early Access)"); }
    public bool can_quit { get; default = true; }

    public void quit () throws DBusError, IOError { GLib.Application.get_default ().quit (); }


    /* Mock */
    public bool fullscreen { get; set; default = true; }
    public bool can_set_fullscreen { get; default = false; }
    public bool can_raise { get; default = false; }
    public bool has_track_list { get; default = false; }
    public string[] supported_mime_types { owned get; default = {}; }
    public string[] supported_uri_schemes { owned get; default = {}; }

    public void raise () throws DBusError, IOError {}

    protected override Variant? get_property_value (GLib.ParamSpec pspec) {
        Variant? value = null;
        switch (pspec.name) {
            case "desktop-entry": value = desktop_entry; break;
            case "identity": value = identity; break;
            case "can-quit": value = can_quit; break;
            case "fullscreen": value = fullscreen; break;
            case "can-set-fullscreen": value = can_set_fullscreen; break;
            case "can-raise": value = can_raise; break;
            case "has-track-list": value = has_track_list; break;
            case "supported-mime-types": value = supported_mime_types; break;
            case "supported-uri-schemes": value = supported_uri_schemes; break;
        }
        return value;
    }
}

[DBus (name = "org.mpris.MediaPlayer2.Player")]
public class Daikhan.MPRIS.Player: Daikhan.MPRIS.ServerBase {
    public Player (DBusConnection conn) {
        base (conn, "org.mpris.MediaPlayer2.Player");
    }

    Playback playback = Playback.get_default ();

    public override void constructed () {
        base.constructed ();

        playback.bind_property ("current-state", this, "playback-status", SYNC_CREATE,
            (binding, current_state, ref playback_status) => {
                switch ((Gst.State) current_state) {
                    case Gst.State.PLAYING: playback_status = "Playing"; break;
                    case Gst.State.PAUSED: playback_status = "Paused"; break;
                    default: playback_status = "Stopped"; break;
                }
                return true;
            }
        );

        playback.track_info.notify.connect (update_metadata);
        playback.notify["duration"].connect (update_metadata);
        playback.notify["current-track"].connect (update_metadata);

        playback.bind_property ("repeat", this, "loop-status", SYNC_CREATE|BIDIRECTIONAL,
            (binding, repeat, ref loop_status) => {
                switch ((RepeatMode) repeat) {
                    case RepeatMode.TRACK: loop_status = "Track"; break;
                    case RepeatMode.QUEUE: loop_status = "Playlist"; break;
                    default: loop_status = "None"; break;
                }
                return true;
            },
            (binding, loop_status, ref repeat) => {
                switch ((string) loop_status) {
                    case "Track": repeat = RepeatMode.TRACK; break;
                    case "Playlist": repeat = RepeatMode.QUEUE; break;
                    default: repeat = RepeatMode.OFF; break;
                }
                return true;
            }
        );

        playback.bind_property ("volume", this, "volume", SYNC_CREATE | BIDIRECTIONAL);

        playback.bind_property ("progress", this, "position", SYNC_CREATE,
        (binding, progress, ref position) => {
            position = (int64) progress / 1000;
            return true;
        }
        );
    }

    /* Real */
    public string playback_status { get; set; }

    public string loop_status { owned get; set; }
    public double volume { get; set; }
    public int64 position { get; set; }

    public void next () throws DBusError, IOError { playback.next (); }
    public void previous () throws DBusError, IOError { playback.prev (); }
    public void pause () throws DBusError, IOError { playback.pause (); }
    public void play_pause () throws DBusError, IOError { playback.toggle_playing (); }
    public void stop () throws DBusError, IOError { playback.stop (); }
    public void play () throws DBusError, IOError { playback.play (); }
    public void seek (int64 offset) throws DBusError, IOError { playback.seek (offset / 1000000); }
    public void SetPosition (ObjectPath track_id, int64 position) throws DBusError, IOError { playback.seek_absolute (position * 1000); }

    /* Mock */
    public double minimum_rate { get; default = 1.0; }
    public double maximum_rate { get; default = 1.0; }
    public double rate { get; set; default = 1.0; }
    public bool shuffle { get; set; default = false; }
    public HashTable<string, Variant> metadata { get; private set; default = new HashTable<string, Variant>(str_hash, str_equal); }
    public bool can_control { get; default = true; }
    public bool can_go_next { get; default = true; }
    public bool can_go_previous { get; default = true; }
    public bool can_pause { get; default = true; }
    public bool can_play { get; default = true; }
    public bool can_seek { get; default = true; }

    public void open_uri (string uri) throws DBusError, IOError {}

    private void update_metadata() {
        var new_metadata = new HashTable<string, Variant>(str_hash, str_equal);
        new_metadata["mpris:length"] = playback.duration / 1000;
        new_metadata["xesam:trackNumber"] = playback.current_track;
        new_metadata["xesam:title"] = playback.track_info.title;
        new_metadata["xesam:album"] = playback.track_info.album;
        new_metadata["xesam:artist"] = new string[] {playback.track_info.artist};
        metadata = new_metadata;
    }

    protected override Variant? get_property_value (GLib.ParamSpec pspec) {
        Variant? value = null;
        switch (pspec.name) {
            case "playback-status": value = playback_status; break;
            case "loop-status": value = loop_status; break;
            case "volume": value = volume; break;
            case "position": value = position; break;
            case "minimum-rate": value = minimum_rate; break;
            case "maximum-rate": value = maximum_rate; break;
            case "rate": value = rate; break;
            case "shuffle": value = shuffle; break;
            case "metadata": value = metadata; break;
            case "can-control": value = can_control; break;
            case "can-go-next": value = can_go_next; break;
            case "can-go-previous": value = can_go_previous; break;
            case "can-pause": value = can_pause; break;
            case "can-play": value = can_play; break;
            case "can-seek": value = can_seek; break;
        }
        return value;
    }
}
