class Daikhan.Database : LibDB.Database {
    private const string db_filename = "database";
    private new const int db_version = 1;
    private LibDB.Migration[] migrations = {
        { 1, {
            """
            CREATE TABLE IF NOT EXISTS History(
                row_id INTEGER PRIMARY KEY NOT NULL,
                content_id TEXT NOT NULL,
                uri_hash TEXT NOT NULL,
                progress INTEGER NOT NULL,
                audio_track INTEGER NOT NULL,
                text_track INTEGER NOT NULL,
                video_track INTEGER NOT NULL
            );
            """
        }},
    };

    public Database() throws LibDB.DatabaseError {
        var data_dir = Application.get_data_dir ();
        var db_file = data_dir.get_child (db_filename);

        base(db_file, db_version);

        perform_migrations (migrations);
    }

    public bool save_record (HistoryRecord record) {
        var values = @"NULL, '$(record.content_id)', '$(record.uri_hash)', $(record.progress), $(record.audio_track), $(record.text_track), $(record.video_track)";
        try {
            query (@"INSERT OR REPLACE INTO History VALUES($values);").complete ();
            return true;
        } catch (LibDB.DatabaseError.QUERY err) {
            warning ("DatabaseError: %s", err.message);
            return false;
        }
    }

    public void remove_records (string content_id, string uri_hash) {
        try {
            if (content_id != "") {
                query (@"UPDATE History SET content_id = '' WHERE content_id = '$content_id';").complete();
            }
            if (uri_hash != "") {
                query (@"UPDATE History SET uri_hash = '' WHERE uri_hash = '$uri_hash';").complete();
            }
            query (@"DELETE FROM History WHERE content_id = '' AND uri_hash = '';").complete();
        } catch (LibDB.DatabaseError.QUERY err) {
            warning ("DatabaseError: %s", err.message);
        }
    }

    public HistoryRecord? find_record_by_content_id (string content_id) {
        try {
            var iter = query (@"SELECT * FROM History WHERE content_id = '$content_id';");
            return record_iter_to_history_record (iter);
        } catch (LibDB.DatabaseError.QUERY err) {
            warning ("DatabaseError: %s", err.message);
            return null;
        }
    }

    public HistoryRecord? find_record_by_uri_hash (string uri_hash) {
        try {
            var iter = query (@"SELECT * FROM History WHERE uri_hash = '$uri_hash';");
            return record_iter_to_history_record (iter);
        } catch (LibDB.DatabaseError.QUERY err) {
            warning ("DatabaseError: %s", err.message);
            return null;
        }
    }

    private HistoryRecord? record_iter_to_history_record (RecordIterator iter) throws LibDB.DatabaseError.QUERY {
        if (!iter.next ()) {
            return null;
        }

        var record = iter.get ();
        var history_record = new HistoryRecord ();
        foreach (var attr in record) {
            switch (attr.name) {
                case "content_id":
                    history_record.content_id = attr.value.get_string ();
                    break;
                case "uri_hash":
                    history_record.uri_hash = attr.value.get_string ();
                    break;
                case "progress":
                    history_record.progress = attr.value.get_int64 ();
                    break;
                case "audio_track":
                    history_record.audio_track = (int) attr.value.get_int64 ();
                    break;
                case "text_track":
                    history_record.text_track = (int) attr.value.get_int64 ();
                    break;
                case "video_track":
                    history_record.video_track = (int) attr.value.get_int64 ();
                    break;
            }
        }
        return history_record;
    }
}
