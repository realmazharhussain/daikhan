/* A compatible re-implementation of GstPlayFlags since they are not exposed.
 * Note: Some names in this implementation differ from the original names for
 * the purpose of being more descriptive.
 */

[Flags]
public enum Daikhan.PlayFlags {
    VIDEO,
    AUDIO,
    SUBTITLES,
    VISUALISATION,
    SOFTWARE_VOLUME,
    NATIVE_AUDIO_ONLY,
    NATIVE_VIDEO_ONLY,
    PROGRESSIVE_DOWNLOADING,
    BUFFER_PARSED_DATA,
    DEINTERLACE,
    SOFTWARE_COLORBALANCE,
    FORCE_APPLY_FILTERS,
    FORCE_SOFTWARE_DECODERS,
}