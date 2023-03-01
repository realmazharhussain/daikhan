public class AudioVolume : Object {
    public double linear { get; set; default = 0; }
    public double logarithmic { get; set; default = 0; }

    construct {
        bind_property("linear", this, "logarithmic",
                      BindingFlags.SYNC_CREATE|BindingFlags.BIDIRECTIONAL,
                      linear_to_logarithmic,
                      logarithmic_to_linear);
    }

    bool linear_to_logarithmic (Binding binding, Value linear, ref Value logarithmic) {
        logarithmic = Math.cbrt((double)linear);
        return true;
    }

    bool logarithmic_to_linear (Binding binding, Value logarithmic, ref Value linear) {
        linear = Math.pow((double)logarithmic, 3);
        return true;
    }
}
