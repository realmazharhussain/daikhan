gschema_files = files(
  'io.gitlab.Envision.MediaPlayer.state.gschema.xml',
)

install_data(gschema_files,
  install_dir: get_option('datadir') / 'glib-2.0/schemas',
)

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
  test(
    'Validate schema files',
    compile_schemas,
    args: ['--strict', '--dry-run', meson.current_source_dir()]
  )
endif
