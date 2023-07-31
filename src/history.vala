public class HistoryRecord {
    public string uri;
    public int64 progress;
    public int audio_track;
    public int text_track;
    public int video_track;

    public HistoryRecord.with_uri (string? uri = null) {
        this.uri = uri;
    }
}

internal unowned PlaybackHistory? default_instance;

public class PlaybackHistory {
    SList<HistoryRecord> data;
    File file;

    private PlaybackHistory() {
        var statedir = Environment.get_user_state_dir () + "/envision";
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
            if (line == null)
                break;

            var parts = line.split (",");
            var record = new HistoryRecord();

            record.uri = unescape_str (parts[0]);
            record.progress = int64.parse (parts[1]);
            record.audio_track = int.parse (parts[2]);
            record.text_track = int.parse (parts[3]);
            record.video_track = int.parse (parts[4]);

            data.prepend (record);
        }

        data.reverse ();
    }

    public HistoryRecord? find (string uri) {
        foreach (var record in data) {
            if (record.uri == uri) {
                return record;
            }
        }

        return null;
    }

    public void update (HistoryRecord record) {
        var existing_record = find (record.uri);
        if (existing_record != null) {
            data.remove (existing_record);
        }
        data.prepend (record);
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
            var uri = escape_str (record.uri);
            var progress = record.progress.to_string ();
            var audio_track = record.audio_track.to_string ();
            var text_track = record.text_track.to_string ();
            var video_track = record.video_track.to_string ();

            var line = string.join (",", uri, progress, audio_track, text_track, video_track) + "\n";
            ostream.write (line.data);
        }

        ostream.close ();
    }

    string escape_str (string input) {
        return input.replace (",", "%2C");
    }

    string unescape_str (string input) {
        return input.replace ("%2C", ",");
    }
}
