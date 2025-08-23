public abstract class LibDB.Database : Object {
    public int db_version { get; construct; default = 0; }
    public int db_version_previous { get; private set; default = 0; }
    Sqlite.Database sqlite;

    protected Database(File db_file, int db_version) throws DatabaseError {
        Object(db_version: db_version);
        establish_connection(db_file);
        initialize_info();
        db_version_previous = (int) get_version();
    }

    private void establish_connection(File file) throws DatabaseError.OPEN {
        var dir = file.get_parent();

        if (dir == null) {
            throw new DatabaseError.OPEN ("Failed to get parent directory of db_file: %s", file.get_path());
        }

        try {
            dir.make_directory_with_parents ();
        } catch (IOError.EXISTS err) {
            // Nothing to do
        } catch (Error err) {
            throw new DatabaseError.OPEN ("Failed to create directory: %s: %s", err.message, dir.get_path());
        }

        var status = Sqlite.Database.open (file.get_path (), out sqlite);
        if (status != Sqlite.OK) {
            throw new DatabaseError.OPEN ("Can't open database: %d: %s".printf (sqlite.errcode (), sqlite.errmsg ()));
        }
    }

    private void initialize_info() throws DatabaseError.QUERY {
        query(
            """
            CREATE TABLE IF NOT EXISTS Info (
                id INT PRIMARY KEY NOT NULL,
                version INT NOT NULL
            );
            """
        ).complete();

        query("INSERT OR IGNORE INTO Info (id, version) VALUES (0, 0);").complete();
    }

    protected void perform_migrations(Migration[] migrations) throws DatabaseError.QUERY {
        var start_version = get_version();
        var target_version = db_version;
        foreach (var migration in migrations) {
            if (migration.version <= start_version || migration.version > target_version) {
                continue;
            }
            foreach (var sql in migration.queries) {
                query(sql).complete();
            }
            query(@"UPDATE Info SET version = $(migration.version);").complete();
        }
    }

    public RecordIterator query (string sql) throws DatabaseError.QUERY {
        Sqlite.Statement *stmt;
        var status = sqlite.prepare_v2(sql, sql.length, out stmt);
        if (status != Sqlite.OK) {
            throw new DatabaseError.QUERY ("Failed to prepare SQL statement. %d: %s", sqlite.errcode(), sqlite.errmsg());
        }

        return new RecordIterator(sqlite, stmt);
    }

    public int64 get_version() throws DatabaseError.QUERY {
        var results = query("SELECT version FROM Info;");
        return results.get_next().first().value.get_int64();
    }
}

public errordomain LibDB.DatabaseError {
    OPEN, QUERY
}


public struct LibDB.Migration {
    int version;
    string[] queries;
}

public interface List<T> {
    public abstract int size { get; }
    public abstract T get (int index);

    public T first() {
        return get(0);
    }
}

public class Attribute {
    public string name { get; private set; }
    public Value? value { get; private set; }

    public Attribute(string name, Value? value) {
        this.name = name;
        this.value = value;
    }
}

public class Record : List<Attribute> {
    private Gee.List<Attribute> list;

    public Record (Gee.List<Attribute> list) {
        this.list = list;
    }

    int size {
        get { return list.size; }
    }

    Attribute get(int index) {
        return list[index];
    }
}

public class RecordIterator {
    unowned Sqlite.Database db;
    Sqlite.Statement *_stmt;
    Sqlite.Statement stmt { get { return _stmt; } }

    public RecordIterator(Sqlite.Database db, Sqlite.Statement *stmt) {
        this.db = db;
        _stmt = stmt;
    }

    public bool next() throws LibDB.DatabaseError.QUERY {
        var status = stmt.step();
        switch (status) {
            case Sqlite.ROW: return true;
            case Sqlite.DONE: return false;
            default:
                throw new LibDB.DatabaseError.QUERY ("");
        }
    }

    public Record get_next() throws LibDB.DatabaseError.QUERY {
        next();
        return get();
    }

    public Record get() {
        var column_count = stmt.column_count();
        var attrs = new Gee.ArrayList<Attribute>();
        for (var i = 0; i < column_count; i++) {
            attrs.add(get_attr(i));
        }
        return new Record(attrs);
    }

    public void complete() throws LibDB.DatabaseError.QUERY {
        while(next());
    }

    private Attribute get_attr (int index) {
        return new Attribute(stmt.column_name(index), get_attr_value(index));
    }

    private Value? get_attr_value (int index) {
        var type = stmt.column_type(index);
        switch (type) {
            case Sqlite.INTEGER:
                return stmt.column_int64(index);
            case Sqlite.FLOAT:
                return stmt.column_double(index);
            case Sqlite.TEXT:
                return stmt.column_text(index);
            case Sqlite.BLOB:
                return stmt.column_blob(index);
            default:
                return null;
        }
    }

    ~RecordIterator() {
        delete _stmt;
    }
}
