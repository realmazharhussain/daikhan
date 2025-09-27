conf_data = {
  'app_id': app_id,
  'locale_dir': get_option('prefix') / get_option('localedir'),
  'gschema_path': gschema_path,
  'version': meson.project_version(),
  'gettext_domain': exe_name,
  'profile': profile,
}

config_file = configure_file(
  input: 'Conf.vala.in',
  output: 'Conf.vala',
  configuration: conf_data,
)

blp_sources = files('AppWindow.blp',
                    'AppMenuButton.blp',
                    'ErrorDialog.blp',
                    'MediaControls.blp',
                    'PillButton.blp',
                    'PlayerView.blp',
                    'PreferencesWindow.blp',
                    'shortcuts-dialog.blp',
                    'VolumeButton.blp',
                    'WelcomeView.blp',
                    )

blueprints = custom_target('blueprints',
  input: blp_sources,
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

gresource_xml = configure_file(
  input: 'daikhan.gresource.xml.in',
  output: 'daikhan.gresource.xml',
  configuration: {
    'app_id': app_id,
  },
)

resources = gnome.compile_resources('daikhan-ui', gresource_xml,
  dependencies: blueprints,
)

sources = [config_file] + blueprints + resources + files(
  'main.vala',
  'ActionDialog.vala',
  'Application.vala',
  'AppMenuButton.vala',
  'AppWindow.vala',
  'ComboRow.vala',
  'ContentId.vala',
  'Database.vala',
  'DurationLabel.vala',
  'DropTarget.vala',
  'ErrorDialog.vala',
  'GestureDragWindow.vala',
  'History.vala',
  'LibDB.vala',
  'MediaControls.vala',
  'MPRIS.vala',
  'PillButton.vala',
  'Player.vala',
  'PlaybinProxy.vala',
  'PlayButton.vala',
  'PlayerView.vala',
  'PlayFlags.vala',
  'PreferencesWindow.vala',
  'ProgressBar.vala',
  'ProgressLabel.vala',
  'Queue.vala',
  'RepeatMode.vala',
  'StreamMenuBuilder.vala',
  'TimeLabel.vala',
  'Title.vala',
  'TrackInfo.vala',
  'Utils.vala',
  'VolumeButton.vala',
  'WelcomeView.vala',
)

if host_machine.system() == 'windows'
  sources += ico_src
endif

deps = [
  dep_adw,
  dep_gdk_pixbuf,
  dep_gee,
  dep_gst,
  dep_gst_audio,
  dep_gst_tag,
  dep_sqlte3,
  dep_xxhash
]

executable(exe_name, sources,
           dependencies: deps,
           vala_args: ['--gresourcesdir', meson.current_build_dir()],
           win_subsystem: 'windows',
           install: true)

content_id_file = files(
  'ContentId.vala'
)

subdir('daikhan-content-id')
