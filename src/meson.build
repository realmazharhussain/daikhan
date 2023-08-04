conf_data = {
  'app_id': app_id,
  'gschema_path': gschema_path,
}

config_file = configure_file(
  input: 'Conf.vala.in',
  output: 'Conf.vala',
  configuration: conf_data,
)

blp_sources = files('window.blp',
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
  'MediaPlayer.vala',
  'Video.vala',
  'PlayerWindow.vala',
  'PlaybackHistory.vala',
  'Playback.vala',
  'TimeLabels.vala',
  'Title.vala',
  'VideoArea.vala',
  'PreferencesWindow.vala',
  'StreamMenuBuilder.vala',
  'ActionDialog.vala',
  'MediaControls.vala',
  'media-controls/PlayButton.vala',
  'media-controls/ProgressBar.vala',
  'media-controls/VolumeButton.vala',
)

executable(meson.project_name(), sources,
           dependencies: deps,
           vala_args: ['--gresourcesdir', meson.current_build_dir()],
           win_subsystem: 'windows',
           install: true)
