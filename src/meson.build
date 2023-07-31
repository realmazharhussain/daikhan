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

sources = [config_file] + files(
  'main.vala',
  'about.vala',
  'app.vala',
  'video.vala',
  'window.vala',
  'history.vala',
  'playback.vala',
  'time-labels.vala',
  'title.vala',
  'video-area.vala',
  'stream-selector.vala',
  'action-dialog.vala',
  'media-controls.vala',
  'media-controls/play-button.vala',
  'media-controls/progress-bar.vala',
  'media-controls/volume-button.vala',
) + resources

executable(meson.project_name(), sources,
           dependencies: deps,
           vala_args: ['--gresourcesdir', meson.current_build_dir()],
           win_subsystem: 'windows',
           install: true)
