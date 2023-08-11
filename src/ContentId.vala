internal const int SEGMENT_SIZE = 16 * 1024;    // 16 KiB
internal const int SIZE_OF_FILE_SIZE = (int) sizeof(int64);

namespace ContentId {
    public string for_path (string path) throws Error {
        var file = File.new_for_path (path);
        return for_file (file);
    }

    public string for_uri (string uri) throws Error {
        var file = File.new_for_uri (uri);
        return for_file (file);
    }

    public string for_file (File file) throws Error {
        var info = file.query_info ("standard::size", NONE);
        var file_size = info.get_size ();
        var stream = file.read ();

        var hash_input = new uint8[SEGMENT_SIZE*3 + SIZE_OF_FILE_SIZE];

        if (file_size > SEGMENT_SIZE * 3) {
            unowned var file_start = hash_input[0 : SEGMENT_SIZE];
            stream.read (file_start);

            unowned var file_middle = hash_input[SEGMENT_SIZE : SEGMENT_SIZE * 2];
            stream.seek (file_size / 2, SET);
            stream.read (file_middle);

            unowned var file_end = hash_input[SEGMENT_SIZE * 2 : SEGMENT_SIZE * 3];
            stream.seek (-SEGMENT_SIZE, END);
            stream.read (file_end);
        } else if (file_size > 0){
            unowned var contents = hash_input[0 : file_size];
            stream.read (contents);
            hash_input.resize ((int) file_size + SIZE_OF_FILE_SIZE);
        }

        unowned var size_buffer = hash_input[hash_input.length - SIZE_OF_FILE_SIZE : hash_input.length];
        size_buffer = (uint8[]) file_size;

        return  ((string) hash_input).hash ().to_string ();
    }
}
