public class Daikhan.PlayButton : Gtk.Button {
    Daikhan.Player player;

    construct {
        add_css_class ("playbutton");

        player = Daikhan.Player.get_default ();
        player.notify["target-state"].connect (update_icon);
        player.notify["queue"].connect (update_sensitivity);

        update_icon ();
        update_sensitivity ();
        clicked.connect (clicked_cb);
    }

    void update_icon () {
        if (player.target_state == PLAYING) {
            icon_name = "media-playback-pause-symbolic";
        } else {
            icon_name = "media-playback-start-symbolic";
        }
    }

    void update_sensitivity () {
        sensitive = player.queue.length > 0;
    }

    void clicked_cb () {
        player.toggle_playing ();
    }
}
