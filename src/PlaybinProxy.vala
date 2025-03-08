/* A helper class to make using GstPlayBin easier */
public class Daikhan.PlaybinProxy : Object {
    public enum State {
        STOPPED,
        INITIALIZING,
        BUFFERING,
        PAUSED,
        PLAYING,
    }

    public enum TargetState {
        STOPPED = State.STOPPED,
        PAUSED = State.PAUSED,
        PLAYING = State.PLAYING;

        public State to_state () {
            return (State) this;
        }

        public Gst.State to_gst_state () {
            switch (this) {
                case STOPPED: return Gst.State.READY;
                case PAUSED: return Gst.State.PAUSED;
                case PLAYING: return Gst.State.PLAYING;
            }
            return_val_if_reached (Gst.State.NULL);
        }
    }

    public dynamic Gst.Pipeline pipeline { get; private construct; }
    public dynamic Gdk.Paintable paintable { get; private construct; }
    public Daikhan.TrackInfo track_info { get; private construct; }
    public Daikhan.HistoryRecord? current_record { get; private set; default = null; }
    public TargetState target_state { get; set; default = STOPPED; }
    public State state { get; private set; default = STOPPED; }
    public string? filename { get; private set; default = null; }
    public int64 progress { get; private set; default = -1; }
    public int64 duration { get; private set; default = -1; }
    public Daikhan.PlayFlags flags { get; set; }
    public double volume { get; set; }

    public signal void unsupported_file ();
    public virtual signal void end_of_stream () {}
    public signal void unsupported_codec (string debug_info);
    public signal void pipeline_error (Gst.Object source, Error error, string debug_info);

    Settings settings;

    construct {
        settings = new Settings (Conf.APP_ID);
        dynamic var gtksink = Gst.ElementFactory.make ("gtk4paintablesink", null);

        pipeline = Gst.ElementFactory.make ("playbin", null) as Gst.Pipeline;
        paintable = gtksink.paintable;

        if (paintable.gl_context != null) {
            dynamic var glsink = Gst.ElementFactory.make ("glsinkbin", null);
            glsink.sink = gtksink;
            pipeline.video_sink = glsink;
        } else {
            pipeline.video_sink = gtksink;
        }

        track_info = new Daikhan.TrackInfo (pipeline);

        pipeline.bus.add_signal_watch ();
        pipeline.bus.message["eos"].connect (pipeline_eos_cb);
        pipeline.bus.message["error"].connect (pipeline_error_cb);
        pipeline.bus.message["state-changed"].connect (pipeline_state_changed_cb);

        pipeline.bind_property ("flags", this, "flags", SYNC_CREATE | BIDIRECTIONAL);

        pipeline.bind_property ("volume", this, "volume", SYNC_CREATE | BIDIRECTIONAL,
            (binding, linear, ref cubic) => {
                cubic = Gst.Audio.StreamVolume.convert_volume (LINEAR, CUBIC, (double) linear);
                return true;
            },
            (binding, cubic, ref linear) => {
                linear = Gst.Audio.StreamVolume.convert_volume (CUBIC, LINEAR, (double) cubic);
                return true;
            }
        );

        notify["target-state"].connect (decide_on_progress_tracking);
        notify["state"].connect (decide_on_progress_tracking);

        notify["target-state"].connect (target_state_cb);
    }

    public void reset () {
        target_state = STOPPED;
        track_info.reset ();
        current_record = null;
        filename = null;
        progress = -1;
        duration = -1;
    }

    public bool open_file (File file, bool play) {
        try {
            var info = file.query_info ("standard::display-name", NONE);
            filename = info.get_display_name ();
        } catch (Error err) {
            filename = file.get_basename ();
        }

        pipeline["uri"] = file.get_uri ();
        target_state = play ? TargetState.PLAYING : TargetState.PAUSED;

        ulong handler_id = 0;
        handler_id = notify["state"].connect (() => {
            if (pipeline.current_state == target_state.to_gst_state ()) {
                update_duration ();
                update_progress ();
                SignalHandler.disconnect (this, handler_id);
            }
        });

        current_record = new Daikhan.HistoryRecord.with_uri (file.get_uri ());

        if (!(AUDIO in flags)) {
            current_record.audio_track = -1;
        }
        if (!(SUBTITLES in flags)) {
            current_record.text_track = -1;
        }
        if (!(VIDEO in flags)) {
            current_record.video_track = -1;
        }

        return true;
    }

    public void target_state_cb () {
        var new_state = target_state.to_gst_state ();
        if (pipeline.set_state (new_state) == FAILURE) {
            critical (@"Failed to set pipeline state to $(new_state)!");
        }
    }

    public bool seek (int64 seconds) {
        var seek_pos = progress + (seconds * Gst.SECOND);
        return seek_absolute (seek_pos);
    }

    public bool seek_absolute (int64 seek_pos) {
        var seeking_method = settings.get_string ("seeking-method");

        Gst.SeekFlags seek_flags = FLUSH;
        if (seeking_method == "fast") {
            seek_flags |= KEY_UNIT;
        } else if (seeking_method == "accurate") {
            seek_flags |= ACCURATE;
        }

        if (seek_pos < 0) {
            seek_pos = 0;
        } else if (seek_pos > duration > 0) {
            seek_pos = duration;
        }

        if (pipeline.seek_simple (TIME, seek_flags, seek_pos)) {
            progress = seek_pos;
            return true;
        }

        return false;

    }

    bool update_duration () {
        int64 duration;
        if (!pipeline.query_duration (TIME, out duration)) {
            return false;
        }

        this.duration = duration;
        return true;
    }

    bool update_progress () {
        int64 progress;
        if (!pipeline.query_position (TIME, out progress)) {
            warning ("Failed to query playback position");
            return Source.REMOVE;
        }

        this.progress = progress;
        current_record.progress = progress;

        return Source.CONTINUE;
    }

    TimeoutSource? progress_source;

    void ensure_progress_tracking () {
        if (progress_source != null && !progress_source.is_destroyed ()) {
            return;
        }

        if (duration == -1) {
            update_duration ();
        }

        update_progress ();

        progress_source = new TimeoutSource (250);
        progress_source.set_callback (update_progress);
        progress_source.attach ();
    }

    void stop_progress_tracking () {
        if (progress_source == null || progress_source.is_destroyed ()) {
            return;
        }

        var source_id = progress_source.get_id ();
        Source.remove (source_id);
    }

    public void decide_on_progress_tracking () {
        if (target_state == PLAYING && state == PLAYING) {
            ensure_progress_tracking ();
        } else {
            stop_progress_tracking ();
        }
    }

    void pipeline_state_changed_cb () {
        switch (pipeline.current_state) {
            case Gst.State.NULL:
            case Gst.State.READY: {
                if (target_state == STOPPED) {
                    state = STOPPED;
                } else {
                    state = INITIALIZING;
                }
                break;
            }
            case Gst.State.PLAYING: state = PLAYING; break;
            case Gst.State.PAUSED: {
                if (target_state == PLAYING) {
                    state = BUFFERING;
                } else {
                    state = PAUSED;
                }
                break;
            }
            case Gst.State.VOID_PENDING: {
                state = target_state.to_state ();
                return_if_reached ();
            }
        }
    }

    void pipeline_error_cb (Gst.Bus bus, Gst.Message msg) {
        Error err;
        string debug_info;

        msg.parse_error (out err, out debug_info);

        if (err is Gst.CoreError.MISSING_PLUGIN) {
            unsupported_codec (debug_info);
        } else if (err is Gst.StreamError.TYPE_NOT_FOUND) {
            unsupported_file ();
        } else {
            pipeline_error (msg.src, err, debug_info);
        }

        target_state = STOPPED;
    }

    void pipeline_eos_cb () {
        end_of_stream.emit ();
    }
}
