desktop_file = files('io.gitlab.Envision.MediaPlayer.desktop')
metainfo_file = files('io.gitlab.Envision.MediaPlayer.metainfo.xml')
install_data(desktop_file, metainfo_file,
  install_dir: get_option('datadir') / 'applications',
)

desktop_utils = find_program('desktop-file-validate', required: false)
if desktop_utils.found()
  test(
    'Validate desktop file',
    desktop_utils,
    args: [desktop_file]
  )
endif

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
          input: 'io.gitlab.Envision.MediaPlayer.service.in',
         output: 'io.gitlab.Envision.MediaPlayer.service',
        install: true,
    install_dir: get_option('datadir') / 'dbus-1/services',
  configuration: configuration_data({
    'bindir': get_option('prefix') / get_option('bindir'),
  }),
)

subdir('icons')
subdir('gschemas')
