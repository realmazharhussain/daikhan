namespace Daikhan.DropTarget {
    public Gtk.DropTarget new () {
        var self = new Gtk.DropTarget (typeof (Gdk.FileList), COPY);
        self.drop.connect (drop_cb);
        return self;
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
