class Choice : Object {
    public string id { get; set; }
    public string label { get; set; }
}

class Daikhan.ComboRow : Adw.ComboRow {
    [CCode (notify = false)]
    public string selected_id {
        get {
            return ((Choice) selected_item).id;
        }

        set {
            selected = find (value);
        }
    }

    construct {
        model = new ListStore (typeof (Choice));
        expression = new Gtk.PropertyExpression (typeof (Choice), null, "label");

        notify["selected-item"].connect (() => { notify_property ("selected-id"); });
    }

    public uint find (string id) {
        for (var i = 0; i < model.get_n_items (); i++) {
            if (((Choice) model.get_item (i)).id == id) {
                return i;
            }
        }

        return Gtk.INVALID_LIST_POSITION;
    }

    public void append (string id, string label) {
        var model = (ListStore) this.model;
        var new_choice = new Choice () { id = id, label = label };
        model.append (new_choice);
    }
}
