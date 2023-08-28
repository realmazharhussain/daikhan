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

    public T[] list_model_to_array <T> (ListModel model) {
        var array = new T[model.get_n_items ()];

        for (int i = 0; i < array.length; i++) {
            array[i] = (T) model.get_item (i);
        }

        return array;
    }
}
