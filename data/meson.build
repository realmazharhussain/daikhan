conf_data = {
  'app_id': app_id,
  'bindir': get_option('prefix') / get_option('bindir'),
}


desktop_file = configure_file(
          input: 'daikhan.desktop.in',
         output: app_id + '.desktop',
        install: true,
    install_dir: get_option('datadir') / 'applications',
  configuration: conf_data,
)

desktop_utils = find_program('desktop-file-validate', required: false)
if desktop_utils.found()
  test(
    'Validate desktop file',
    desktop_utils,
    args: [desktop_file]
  )
endif


metainfo_file = configure_file(
          input: 'daikhan.metainfo.xml.in',
         output: app_id + '.metainfo.xml',
        install: true,
    install_dir: get_option('datadir') / 'metainfo',
  configuration: conf_data,
)

appstreamcli = find_program('appstreamcli', required: false)
if appstreamcli.found()
  test(
    'Validate metainfo (with appstreamcli)',
    appstreamcli,
    args: ['validate', '--no-net', metainfo_file]
  )
endif

appstream_util = find_program('appstream-util', required: false)
if appstream_util.found()
  test(
    'Validate metainfo (with appstream-util)',
    appstream_util,
    args: ['validate', '--nonet', metainfo_file]
  )
endif


configure_file(
          input: 'daikhan.service.in',
         output: app_id + '.service',
        install: true,
    install_dir: get_option('datadir') / 'dbus-1/services',
  configuration: conf_data,
)

subdir('icons')
subdir('gschemas')
