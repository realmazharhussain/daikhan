conf_data = {
  'app_id': app_id,
  'bindir': get_option('prefix') / get_option('bindir'),
  'gschema_path': gschema_path,
}

configure_file(
          input: 'daikhan.gschema.xml.in',
         output: app_id + '.gschema.xml',
        install: true,
    install_dir: get_option('datadir') / 'glib-2.0/schemas',
  configuration: conf_data,
)

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
  test('Validate schema files', compile_schemas,
    args: ['--strict', '--dry-run', meson.current_build_dir()],
  )
endif

if host_machine.system() != 'windows'
  desktop_file_in = configure_file(
            input: 'daikhan.desktop.in',
           output: app_id + '.desktop.in',
          install: false,
    configuration: conf_data,
  )

  desktop_file = i18n.merge_file(
             type: 'desktop',
            input: desktop_file_in,
           output: app_id + '.desktop',
           po_dir: meson.source_root() / 'po',
          install: true,
      install_dir: get_option('datadir') / 'applications',
  )

  metainfo_file_in = configure_file(
            input: 'daikhan.metainfo.xml.in',
           output: app_id + '.metainfo.xml.in',
          install: false,
    configuration: conf_data,
  )

  metainfo_file = i18n.merge_file(
            input: metainfo_file_in,
           output: app_id + '.metainfo.xml',
           po_dir: meson.source_root() / 'po',
          install: true,
      install_dir: get_option('datadir') / 'metainfo',
  )

  configure_file(
            input: 'daikhan.service.in',
           output: app_id + '.service',
          install: true,
      install_dir: get_option('datadir') / 'dbus-1/services',
    configuration: conf_data,
  )

  desktop_utils = find_program('desktop-file-validate', required: false)
  appstreamcli = find_program('appstreamcli', required: false)
  appstream_util = find_program('appstream-util', required: false)

  if desktop_utils.found()
    test('Validate desktop file', desktop_utils,
      args: [desktop_file],
    )
  endif

  if appstreamcli.found()
    test('Validate metainfo (with appstreamcli)', appstreamcli,
      args: ['validate', '--no-net', metainfo_file],
    )
  endif

  if appstream_util.found()
    test( 'Validate metainfo (with appstream-util)', appstream_util,
      args: ['validate', '--nonet', metainfo_file],
    )
  endif
endif

subdir('icons')
