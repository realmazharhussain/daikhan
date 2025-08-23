class Daikhan.Database : LibDB.Database {
    private const string db_filename = "database";
    private new const int db_version = 1;

    public Database() throws LibDB.DatabaseError {
        var data_dir = Application.get_data_dir ();
        var db_file = data_dir.get_child (db_filename);

        base(db_file, db_version);
    }

}
