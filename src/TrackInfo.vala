public class Daikhan.TrackInfo : Object {
    public string title { get; private set; }
    public string album { get; private set; }
    public string artist { get; private set; }

    public Gst.Pipeline pipeline { get; construct; }

    construct {
        reset ();
    }

    public TrackInfo (Gst.Pipeline pipeline) {
        Object (pipeline: pipeline);
    }

    public override void constructed () {
        pipeline.bus.message["tag"].connect (tag_cb);
    }

    public void reset () {
        title = "";
        album = "";
        artist = "";
    }

    void tag_cb (Gst.Bus bus, Gst.Message msg) {
        Gst.TagList tag_list ;
        msg.parse_tag (out tag_list);

        string artist, album, title;

        if (tag_list.get_string (Gst.Tags.ARTIST, out artist)) {
            this.artist = artist;
        }

        if (tag_list.get_string (Gst.Tags.ALBUM, out album)) {
            this.album = album;
        }

        if (tag_list.get_string (Gst.Tags.TITLE, out title)) {
            this.title = title;
        }
    }
}
