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

blp_sources = files('app-window.blp',
                    'shortcuts.blp',
                    'video-area.blp',
                    'preferences.blp',
                    'media-controls.blp',
                    'media-controls/volume-button.blp',
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
  'Application.vala',
  'AppWindow.vala',
  'ContentId.vala',
  'IdComboRow.vala',
  'History.vala',
  'Playback.vala',
  'TimeLabels.vala',
  'Title.vala',
  'VideoArea.vala',
  'PreferencesWindow.vala',
  'StreamMenuBuilder.vala',
  'ActionDialog.vala',
  'Utils.vala',
  'MediaControls.vala',
  'media-controls/PlayButton.vala',
  'media-controls/ProgressBar.vala',
  'media-controls/VolumeButton.vala',
)

executable(meson.project_name(), sources,
           dependencies: deps,
           c_args: ['-DGETTEXT_PACKAGE="daikhan"'],
           vala_args: ['--gresourcesdir', meson.current_build_dir(),
                       '--vapidir', meson.source_root() / 'vapi',
                       ],
           win_subsystem: 'windows',
           install: true)
