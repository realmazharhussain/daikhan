public class Daikhan.TrackInfo : Object {
    public string title { get; private set; }
    public string album { get; private set; }
    public string artist { get; private set; }
    public File? image { get; private set; }

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
        delete_image_file.begin ();
    }

    void tag_cb (Gst.Bus bus, Gst.Message msg) {
        Gst.TagList tag_list ;
        msg.parse_tag (out tag_list);

        string artist, album, title;
        Gst.Sample sample;

        if (tag_list.get_string (Gst.Tags.ARTIST, out artist)) {
            this.artist = artist;
        }

        if (tag_list.get_string (Gst.Tags.ALBUM, out album)) {
            this.album = album;
        }

        if (tag_list.get_string (Gst.Tags.TITLE, out title)) {
            this.title = title;
        }

        if (tag_list.get_sample (Gst.Tags.IMAGE, out sample)) {
            save_image_to_file.begin (sample);
        }
    }

    private async void save_image_to_file (Gst.Sample sample) {
        try {
            yield delete_image_file ();
            GLib.FileIOStream file_io;
            var file = yield File.new_tmp_async (null, Priority.DEFAULT, null, out file_io);
            var file_out = file_io.output_stream;
            var buffer = sample.get_buffer ();
            var array_buffer = new uint8[0];
            size_t offset = 0, size = 16 * 1024;
            do {
                buffer.extract_dup (offset, size, out array_buffer);
                yield file_out.write_async (array_buffer);
                offset += array_buffer.length;
            } while (size == array_buffer.length);
            image = file;
        } catch (Error err) {
            warning ("%s", err.message);
        }
    }

    private async void delete_image_file () {
        var file = image;
        if (file == null) return;

        try {
            yield file.delete_async ();
        } catch (IOError.NOT_FOUND err) {
            // ignore error
        } catch (Error err) {
            warning ("%s:%s:%s", err.domain.to_string (), err.code.to_string (), err.message);
        } finally {
            image = null;
        }
    }
}
