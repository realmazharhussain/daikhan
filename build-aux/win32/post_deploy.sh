#!/usr/bin/bash
export GDK_PIXBUF_MODULEDIR=lib/gdk-pixbuf-2.0/2.10.0/loaders
gdk-pixbuf-query-loaders > lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
