namespace Daikhan.Utils {
    public T[] list_model_to_array <T> (ListModel model) {
        var array = new T[model.get_n_items ()];

        for (int i = 0; i < array.length; i++) {
            array[i] = (T) model.get_item (i);
        }

        return array;
    }
}
