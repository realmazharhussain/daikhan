project('daikhan', 'vala',
        version: '0.1.alpha')

profile = get_option('profile')

app_id = 'io.gitlab.daikhan.player'
gschema_path = '/io/gitlab/daikhan/player/'

if profile != 'stable'
  app_id += '.' + profile
  gschema_path += profile + '/'
endif

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
