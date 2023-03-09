gresource_xml = files('envision.gresource.xml')

blp_sources = files('window.blp',
                    'shortcuts.blp',
                    'media-controls.blp',
                    'media-controls/volume-button.blp',
                    )

blueprints = custom_target('blueprints',
  input: blp_sources,
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

resources = gnome.compile_resources('envision-ui', gresource_xml,
  dependencies: blueprints,
)

sources = files(
  'main.vala',
  'about.vala',
  'app.vala',
  'video.vala',
  'window.vala',
  'playback.vala',
  'media-controls.vala',
  'media-controls/play-button.vala',
  'media-controls/progress-scale.vala',
  'media-controls/volume-button.vala',
) + resources

executable(meson.project_name(), sources,
           dependencies: [adw_dep, gst_dep, math_dep],
           vala_args: ['--gresourcesdir', meson.current_build_dir()],
           install: true)
