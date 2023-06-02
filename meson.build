project('envision', 'vala',
        version: '0.1.alpha')

gnome = import('gnome')
cc = meson.get_compiler('c')

deps = [
  dependency('libadwaita-1'),
  dependency('gstreamer-1.0'),
  dependency('gstreamer-tag-1.0'),
  cc.find_library('m', required: false),
]

dependency('gstgtk4')   # Has no header or vaapi file

subdir('data')
subdir('src')

gnome.post_install(
     glib_compile_schemas: true,
    gtk_update_icon_cache: true,
  update_desktop_database: true,
)
