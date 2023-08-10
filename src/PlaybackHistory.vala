public class HistoryRecord {
    public uint uri_hash;
    public uint content_id;
    public int64 progress;
    public int audio_track;
    public int text_track;
    public int video_track;

    public HistoryRecord.with_uri (string uri) {
        this.uri_hash = uri.hash ();

        if (uri.has_prefix ("file://")) {
            try {
                this.content_id = ContentId.for_uri (uri);
            } catch (Error e) {
                warning ("Error calculating content-id: %s", e.message);
            }
        }
    }
}

internal unowned PlaybackHistory? default_instance;

public class PlaybackHistory {
    SList<HistoryRecord> data;
    File file;

    private PlaybackHistory() {
        var statedir = Environment.get_user_state_dir () + "/daikhan";
        var path = statedir + "/history";
        file = File.new_for_path (path);
    }

    public static PlaybackHistory get_default () {
        default_instance = default_instance ?? new PlaybackHistory ();
        return default_instance;
    }

    public void load () throws Error {
        data = new SList<HistoryRecord>();
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
            var record = new HistoryRecord();

            var id_parts =  parts[0].split (":");
            if (uint.try_parse (id_parts[0], out record.uri_hash)) {
                uint.try_parse (id_parts[1], out record.content_id);
            } else {
                record.uri_hash = unescape_str (parts[0]).hash ();
                record.content_id = ContentId.NONE;
            }

            record.progress = int64.parse (parts[1]);
            record.audio_track = int.parse (parts[2]);
            record.text_track = int.parse (parts[3]);
            record.video_track = int.parse (parts[4]);

            data.prepend (record);
        }

        data.reverse ();
    }

    public HistoryRecord? find (string uri) {
        HistoryRecord? record = null;
        uint content_id = ContentId.NONE;

        if (uri.has_prefix ("file://")) {
            try {
                content_id = ContentId.for_uri (uri);
            } catch (Error e) {
                warning ("Error occured calculating content-id: %s", e.message);
            }
        }

        if (content_id != ContentId.NONE) {
            record = find_by_content_id (content_id);
        }

        if (record == null) {
            record = find_by_uri_hash (uri.hash ());
        }

        return record;
    }

    private HistoryRecord? find_by_content_id (uint content_id) {
        foreach (var record in data) {
            if (record.content_id == content_id) {
                return record;
            }
        }

        return null;
    }

    private HistoryRecord? find_by_uri_hash (uint uri_hash) {
        foreach (var record in data) {
            if (record.uri_hash == uri_hash) {
                return record;
            }
        }

        return null;
    }

    public void update (HistoryRecord current) {
        var previous = find_by_content_id (current.content_id)
                       ?? find_by_uri_hash (current.uri_hash);

        if (previous != null && previous.uri_hash == current.uri_hash &&
            (previous.content_id == current.content_id || previous.content_id == ContentId.NONE))
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
            var id = record.uri_hash.to_string () + ":" + record.content_id.to_string ();
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
