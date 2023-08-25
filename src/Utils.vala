namespace Daikhan.Utils {
    public bool is_file_type_supported (File file) {
        string mimetype;

        try {
            mimetype = file.query_info ("standard::", NONE).get_content_type ();
        } catch (Error err) {
            return false;
        }

        return mimetype.has_prefix ("video/") || mimetype.has_prefix ("audio/");
    }
}
