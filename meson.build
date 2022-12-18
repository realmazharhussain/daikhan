project('envision', 'vala',
        version: '0.1.alpha')

gnome = import('gnome')
adw_dep = dependency('libadwaita-1')
gst_dep = dependency('gstreamer-1.0')
dependency('gstgtk4')

cc = meson.get_compiler('c')
math_dep = cc.find_library('m', required: false)

subdir('src')

gnome.post_install(
     glib_compile_schemas: true,
    gtk_update_icon_cache: true,
  update_desktop_database: true,
)
