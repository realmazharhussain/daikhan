project('daikhan', 'vala',
        version: '0.1-alpha6')

profile = get_option('profile')

app_id = 'io.gitlab.daikhan.' + profile
gschema_path = '/io/gitlab/daikhan/' + profile + '/'

i18n = import('i18n')
gnome = import('gnome')
cc = meson.get_compiler('c')

add_project_arguments(
  '-DGETTEXT_PACKAGE="daikhan"',
  language: 'c'
)

add_project_arguments(
  '--vapidir', meson.project_source_root() / 'vapi',
  language: 'vala'
)

add_project_dependencies(
  cc.find_library('m', required: false),
  language: ['vala', 'c']
)

dep_adw = dependency('libadwaita-1', version: '>=1.6.0')
dep_gdk_pixbuf = dependency('gdk-pixbuf-2.0')
dep_gee = dependency('gee-0.8')
dep_gio = dependency('gio-2.0')
dep_gst = dependency('gstreamer-1.0')
dep_gst_audio = dependency('gstreamer-audio-1.0')
dep_gst_tag = dependency('gstreamer-tag-1.0')
dep_sqlte3 = dependency('sqlite3')
dep_xxhash = dependency('libxxhash')

dependency('gstgtk4')   # Has no header or vaapi file

profile_suffix = ''
if profile != 'stable'
  profile_suffix = '-' + profile
endif

exe_name = meson.project_name() + profile_suffix

subdir('po')
subdir('data')
subdir('src')

gnome.post_install(
     glib_compile_schemas: true,
    gtk_update_icon_cache: true,
  update_desktop_database: true,
)
