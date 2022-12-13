gresource_xml = files('envision.gresource.xml')

blp_sources = files('window.blp',
                    'headerbar.blp',
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
  'main.gs',
  'app.gs',
  'window.gs',
  'about.gs',
) + resources

executable(meson.project_name(), sources,
           dependencies: [adw_dep, gst_dep],
           vala_args: ['--gresourcesdir', meson.current_build_dir()],
           install: true)
