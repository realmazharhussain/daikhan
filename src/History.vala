public class Daikhan.HistoryRecord {
    public string uri_hash;
    public string content_id;
    public int64 progress;
    public int audio_track;
    public int text_track;
    public int video_track;

    public Daikhan.HistoryRecord.with_uri (string uri) {
        this.uri_hash = XXH.v3_128bits (uri.data).to_string ();

        if (uri.has_prefix ("file://")) {
            try {
                this.content_id = ContentId.for_uri (uri);
            } catch (Error e) {
                warning ("Error calculating content-id: %s", e.message);
            }
        }
    }
}

internal unowned Daikhan.History? default_instance;

public class Daikhan.History {
    SList<Daikhan.HistoryRecord> data;
    File file;

    private History() {
        var statedir = Environment.get_user_state_dir () + "/daikhan";
        var path = statedir + "/history";
        file = File.new_for_path (path);
    }

    public static History get_default () {
        default_instance = default_instance ?? new History ();
        return default_instance;
    }

    public void load () throws Error {
        const int LENGTH_OF_HASH_STRING = 32;
        data = new SList<Daikhan.HistoryRecord>();
        DataInputStream istream;

        try {
            var base_stream = file.read ();
            istream = new DataInputStream (base_stream);
        } catch (IOError.NOT_FOUND err) {
            return;
        }

        string line;
        int i;
        for (i = 0; i < 1000; i++) {
            line = istream.read_line ();
            if (line == null) {
                break;
            }

            var parts = line.split (",");
            var record = new Daikhan.HistoryRecord();

            var id_parts =  parts[0].split (":");
            if (id_parts[0].length == LENGTH_OF_HASH_STRING) {
                record.uri_hash = id_parts[0];
                record.content_id = id_parts[1];
            } else {
                record.uri_hash = XXH.v3_128bits (unescape_str (parts[0]).data).to_string ();
                record.content_id = "";
            }

            record.progress = int64.parse (parts[1]);
            record.audio_track = int.parse (parts[2]);
            record.text_track = int.parse (parts[3]);
            record.video_track = int.parse (parts[4]);

            data.prepend (record);
        }

        data.reverse ();
    }

    public Daikhan.HistoryRecord? find (string uri) {
        Daikhan.HistoryRecord? record = null;
        string? content_id = null;

        if (uri.has_prefix ("file://")) {
            try {
                content_id = ContentId.for_uri (uri);
            } catch (Error e) {
                warning ("Error occured calculating content-id: %s", e.message);
            }
        }

        if (content_id != null) {
            record = find_by_content_id (content_id);
        }

        if (record == null) {
            var uri_hash = XXH.v3_128bits (uri.data).to_string ();
            record = find_by_uri_hash (uri_hash);
        }

        return record;
    }

    private Daikhan.HistoryRecord? find_by_content_id (string content_id) {
        foreach (var record in data) {
            if (record.content_id == content_id) {
                return record;
            }
        }

        return null;
    }

    private Daikhan.HistoryRecord? find_by_uri_hash (string uri_hash) {
        foreach (var record in data) {
            if (record.uri_hash == uri_hash) {
                return record;
            }
        }

        return null;
    }

    public void update (Daikhan.HistoryRecord current) {
        var previous = find_by_content_id (current.content_id)
                       ?? find_by_uri_hash (current.uri_hash);

        if (previous != null && previous.uri_hash == current.uri_hash &&
            (previous.content_id == "" || previous.content_id == current.content_id))
        {
            data.remove (previous);
        }

        data.prepend (current);
    }

    public void save () throws Error {
        FileOutputStream ostream;

        try {
            ostream = file.replace (null, false, NONE);
        } catch (IOError.NOT_FOUND err) {
            file.get_parent ().make_directory_with_parents ();
            ostream = file.replace (null, false, NONE);
        }

        foreach (var record in data) {
            var id = record.uri_hash + ":" + record.content_id;
            var progress = record.progress.to_string ();
            var audio_track = record.audio_track.to_string ();
            var text_track = record.text_track.to_string ();
            var video_track = record.video_track.to_string ();

            var line = string.join (",", id, progress, audio_track, text_track, video_track) + "\n";
            ostream.write (line.data);
        }

        ostream.close ();
    }

    string unescape_str (string input) {
        return input.replace ("%2C", ",");
    }
}
