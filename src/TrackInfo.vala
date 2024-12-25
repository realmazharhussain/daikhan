public class Daikhan.TrackInfo : Object {
    public string title { get; private set; }
    public string album { get; private set; }
    public string artist { get; private set; }
    public File? image { get; private set; }
    public File? image_square { get; private set; }

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
        delete_images.begin ();
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
            string? orientation;
            tag_list.get_string (Gst.Tags.IMAGE_ORIENTATION, out orientation);

            save_album_art.begin (sample, orientation);
        }
    }

    private bool saving_album_art = false;
    private async void save_album_art (Gst.Sample sample, string? orientation) {
        // make sure only one instance of this method is doing work at a time
        while (saving_album_art) { yield; }
        saving_album_art = true;
        try {
            yield delete_images ();
            var file = yield save_sample_to_tmp (sample);

            var rotated_pixbuf = get_rotated_image (file, orientation);
            image = yield save_pixbuf_to_tmp (rotated_pixbuf);

            var cropped_pixbuf = get_cropped_image (rotated_pixbuf);
            image_square = yield save_pixbuf_to_tmp (cropped_pixbuf);

            yield delete_file (file);
        } catch (Error err) {
            warning ("%s", err.message);
        }
        saving_album_art = false;
    }

    private async File save_sample_to_tmp (Gst.Sample sample) throws Error {
        FileIOStream file_io;
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
        return file;
    }

    private Gdk.Pixbuf get_rotated_image (File file, string? orientation) throws Error {
        var pixbuf = new Gdk.Pixbuf.from_file (file.get_path ());

        if (orientation == null || orientation.length == 0) {
            return pixbuf;
        }

        var flip = orientation.has_prefix ("flip-");
        var rotation_start = flip ? "flip-rotate-".length : "rotate-".length;
        var rotation = int.parse (orientation[rotation_start:]);

        if (flip) {
            pixbuf = pixbuf.flip (true);
        }

        switch (rotation) {
            case 90: pixbuf = pixbuf.rotate_simple (COUNTERCLOCKWISE); break;
            case 180: pixbuf = pixbuf.rotate_simple (UPSIDEDOWN); break;
            case 270: pixbuf = pixbuf.rotate_simple (CLOCKWISE); break;
        }

        return pixbuf;
    }

    private Gdk.Pixbuf get_cropped_image (Gdk.Pixbuf pixbuf) {
        var width = pixbuf.width;
        var height = pixbuf.height;

        if (width == height) {
            return pixbuf;
        }

        var x_offset = 0;
        var y_offset = 0;
        var min_side = int.min (width, height);

        if (width > height) {
            x_offset = (width - height) / 2;
        } else {
            y_offset = (height - width) / 2;
        }

        return new Gdk.Pixbuf.subpixbuf (pixbuf, x_offset, y_offset, min_side, min_side);
    }

    private async File save_pixbuf_to_tmp (Gdk.Pixbuf pixbuf) throws Error {
        FileIOStream file_io;
        var file = yield File.new_tmp_async (null, Priority.DEFAULT, null, out file_io);
        yield pixbuf.save_to_stream_async (file_io.output_stream, "jpeg", null, "quality", "80", null);
        return file;
    }

    private async void delete_images () {
        yield delete_file (image);
        image = null;
        yield delete_file (image_square);
        image_square = null;
    }

    private async void delete_file (File? file) {
        if (file == null) return;

        try {
            yield file.delete_async ();
        } catch (IOError.NOT_FOUND err) {
            // ignore error
        } catch (Error err) {
            warning ("%s:%s:%s", err.domain.to_string (), err.code.to_string (), err.message);
        }
    }
}
