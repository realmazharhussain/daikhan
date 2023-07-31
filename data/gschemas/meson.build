configure_file(
          input: 'daikhan.gschema.xml.in',
         output: app_id + '.gschema.xml',
        install: true,
    install_dir: get_option('datadir') / 'glib-2.0/schemas',
  configuration: {
    'app_id': app_id,
    'gschema_path': gschema_path,
  },
)

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
  test(
    'Validate schema files',
    compile_schemas,
    args: ['--strict', '--dry-run', meson.current_build_dir()]
  )
endif
