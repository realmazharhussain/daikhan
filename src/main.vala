int main (string[] args) {
    Intl.bindtextdomain (Conf.GETTEXT_DOMAIN, Conf.LOCALE_DIR);
    Intl.textdomain (Conf.GETTEXT_DOMAIN);
    Intl.setlocale ();

    Gst.init (ref args);

    var app = new Daikhan.Application ();
    return app.run (args);
}
