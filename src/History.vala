
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
                this.content_id = Daikhan.ContentId.for_uri (uri);
            } catch (Error e) {
                warning ("Error calculating content-id: %s", e.message);
            }
        }
    }
}

internal unowned Daikhan.History? default_history;

public class Daikhan.History {
    Database db;

    private History () {
        try {
            db = new Database ();
        } catch (Error err) {
            warning(err.message);
        }
    }

    public static History get_default () {
        default_history = default_history ?? new History ();
        return default_history;
    }

    public void load () throws Error {
        if (db.db_version_previous == 0) {
            migrate_from_text_file_to_db ();
        }
    }

    public void migrate_from_text_file_to_db () throws Error {
        const int LENGTH_OF_HASH_STRING = 32;
        DataInputStream istream;

        var data = new SList<Daikhan.HistoryRecord> ();
        var statedir = Environment.get_user_state_dir () + "/daikhan";
        var path = statedir + "/history";
        var file = File.new_for_path (path);

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
            var record = new Daikhan.HistoryRecord ();

            var id_parts = parts[0].split (":");
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

        foreach (var record in data) {
            db.save_record (record);
        }

        file.delete ();
    }

    public Daikhan.HistoryRecord? find (string uri) {
        Daikhan.HistoryRecord? record = null;
        string? content_id = null;

        if (uri.has_prefix ("file://")) {
            try {
                content_id = Daikhan.ContentId.for_uri (uri);
            } catch (Error e) {
                warning ("Error occured calculating content-id: %s", e.message);
            }
        }

        if (content_id != null) {
            record = db.find_record_by_content_id (content_id);
        }

        if (record == null) {
            var uri_hash = XXH.v3_128bits (uri.data).to_string ();
            record = db.find_record_by_uri_hash (uri_hash);
        }

        return record;
    }

    public void update (Daikhan.HistoryRecord current) {
        db.remove_records (current.content_id, current.uri_hash);
        db.save_record (current);
    }

    string unescape_str (string input) {
        return input.replace ("%2C", ",");
    }
}
