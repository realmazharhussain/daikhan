public class Daikhan.Queue {
    private File[] data;

    public Queue (File[]? file_array = null) {
        data = file_array ?? new File[0];
    }

    public Queue.from_uri_array (string[] uri_array) {
        data = new File[uri_array.length];

        for (var i = 0; i < uri_array.length; i++) {
            data[i] = File.new_for_uri (uri_array[i]);
        }
    }

    public string[] to_uri_array () {
        var uri_array = new string[data.length];

        for (var i = 0; i < data.length; i++) {
            uri_array[i] = data[i].get_uri ();
        }

        return uri_array;
    }

    public int length {
        get { return data.length; }
    }

    public File get (int index) {
        return data[index];
    }
}
