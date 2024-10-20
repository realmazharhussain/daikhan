int main (string[] args) {
    Intl.bindtextdomain ("daikhan", Conf.LOCALE_DIR);
    Intl.textdomain ("daikhan");
    Intl.setlocale ();

    var app = new Daikhan.ContentId.Application ();
    return app.run (args);
}
