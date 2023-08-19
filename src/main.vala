int main(string[] args) {
    Intl.bindtextdomain("daikhan", Conf.LOCALE_DIR);
    Intl.textdomain("daikhan");
    Intl.setlocale();

    Gst.init(ref args);

    var app = new Daikhan.Application();
    return app.run(args);
}
