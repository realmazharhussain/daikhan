conf_data = {
  'app_id': app_id,
  'locale_dir': get_option('prefix') / get_option('localedir'),
  'gschema_path': gschema_path,
}

config_file = configure_file(
  input: 'Conf.vala.in',
  output: 'Conf.vala',
  configuration: conf_data,
)

blp_sources = files('AppWindow.blp',
                    'AppMenuButton.blp',
                    'MediaControls.blp',
                    'PlayerView.blp',
                    'PreferencesWindow.blp',
                    'Shortcuts.blp',
                    'VideoArea.blp',
                    'VolumeButton.blp',
                    'WelcomeView.blp',
                    )

blueprints = custom_target('blueprints',
  input: blp_sources,
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

resources = gnome.compile_resources('daikhan-ui', 'daikhan.gresource.xml',
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
  'DurationLabel.vala',
  'History.vala',
  'MediaControls.vala',
  'Playback.vala',
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
  'VideoArea.vala',
  'VolumeButton.vala',
  'WelcomeView.vala',
)

executable(meson.project_name(), sources,
           dependencies: deps,
           c_args: ['-DGETTEXT_PACKAGE="daikhan"'],
           vala_args: ['--gresourcesdir', meson.current_build_dir(),
                       '--vapidir', meson.source_root() / 'vapi',
                       ],
           win_subsystem: 'windows',
           install: true)
