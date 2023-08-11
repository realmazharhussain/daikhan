internal string data_to_hex_str (uint8[] data) {
    var hash_string = new GLib.StringBuilder ();
    foreach (var num in  data) {
        hash_string.append_printf ("%02x", num);
    }
    return hash_string.str;
}

[CCode (cheader_filename = "xxhash.h")]
namespace XXH {
    [SimpleType]
    [IntegerType (signed = false, rank = 11)]
    [CCode (cname = "XXH64_hash_t")]
    public struct Hash64 {
        public string to_string () {
            return data_to_hex_str ((uint8[]) this);
        }
    }

    [SimpleType]
    [IntegerType (signed = false, rank = 15)]
    [CCode (cname = "XXH128_hash_t")]
    public struct Hash128 {
        Hash64 low64;
        Hash64 high64;

        public string to_string () {
            return data_to_hex_str ((uint8[]) this);
        }
    }

    [CCode (cname = "XXH3_64bits")]
    public Hash64 v3_64bits(uint8[] data);

    [CCode (cname = "XXH3_128bits")]
    public Hash128 v3_128bits(uint8[] data);
}
