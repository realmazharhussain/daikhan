namespace Daikhan.DropTarget {
    public Gtk.DropTarget new () {
        var self = new Gtk.DropTarget (typeof (Gdk.FileList), COPY);
        self.preload = true;
        self.notify["value"].connect (notify_value_cb);
        self.drop.connect (drop_cb);
        return self;
    }

    void notify_value_cb (Object obj, ParamSpec pspec) {
        var self = (Gtk.DropTarget) obj;

        var value = self.get_value ();
        if (value == null) {
            return;
        }

        if (!drop_value_is_acceptable (value)) {
            self.reject ();
        }
    }

    bool drop_value_is_acceptable (Value value) {
        var files = ((Gdk.FileList) value).get_files ();

        foreach (var file in files) {
            if (Daikhan.Utils.is_file_type_supported (file)) {
                return true;
            }
        }

        return false;
    }

    bool drop_cb (Gtk.DropTarget self, Value value, double x, double y) {
        var file_list = ((Gdk.FileList) value).get_files ();
        var file_array = new File[file_list.length ()];

        int i = 0;
        foreach (var file in file_list) {
            file_array[i] = file;
            i++;
        }

        ((Daikhan.AppWindow) self.widget.root).open (file_array);
        return true;
    }
}
