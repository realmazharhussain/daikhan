project('daikhan', 'vala',
        version: 'pre-alpha')

profile = get_option('profile')

app_id = 'io.gitlab.daikhan.' + profile
gschema_path = '/io/gitlab/daikhan/' + profile + '/'

i18n = import('i18n')
gnome = import('gnome')
cc = meson.get_compiler('c')

deps = [
  dependency('libadwaita-1', version: '>=1.6.0'),
  dependency('gstreamer-1.0'),
  dependency('gstreamer-audio-1.0'),
  dependency('gstreamer-tag-1.0'),
  dependency('libxxhash'),
  cc.find_library('m', required: false),
]

dependency('gstgtk4')   # Has no header or vaapi file

subdir('po')
subdir('data')
subdir('src')

gnome.post_install(
     glib_compile_schemas: true,
    gtk_update_icon_cache: true,
  update_desktop_database: true,
)
