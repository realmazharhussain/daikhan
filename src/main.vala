int main(string[] args) {
    Gst.init(ref args);
    var app = new MediaPlayer();
    return app.run(args);
}
