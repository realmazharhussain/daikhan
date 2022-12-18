[indent=4]

class AudioVolume: Object
    prop linear: double = 0
    prop logarithmic: double = 0

    init
        bind_property("linear", self, "logarithmic",
                      BindingFlags.SYNC_CREATE|BindingFlags.BIDIRECTIONAL,
                      linear_to_logarithmic,
                      logarithmic_to_linear)

    def private linear_to_logarithmic (binding: Binding, linear: Value, ref logarithmic: Value): bool
        logarithmic = Math.cbrt((double)linear)
        return true

    def private logarithmic_to_linear (binding: Binding, logarithmic: Value, ref linear: Value): bool
        linear = Math.pow((double)logarithmic, 3)
        return true
