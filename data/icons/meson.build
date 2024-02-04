hicolor_dir = get_option('datadir') / 'icons/hicolor'

regular_svg = 'daikhan.svg'
symbolic_svg = 'daikhan-symbolic.svg'

if profile == 'devel'
  regular_svg = 'daikhan.devel.svg'
endif

install_data(regular_svg,
  install_dir: hicolor_dir/'scalable/apps',
  rename: app_id + '.svg',
)

install_data(symbolic_svg,
  install_dir: hicolor_dir/'symbolic/apps',
  rename:  app_id + '-symbolic.svg',
)

if host_machine.system() == 'windows'
  find_program('rsvg-convert', required: true)  # Needed by svg2ico
  find_program('icotool', required: true)       # Needed by svg2ico

  svg2ico = find_program(meson.project_source_root() / 'build-aux/win32/svg2ico.sh')
  daikhan_ico = custom_target('daikhan_ico',
    command: [svg2ico, '@OUTPUT@', '@INPUT@', '16', '24', '32', '48', '256'],
    input: regular_svg,
    output: 'daikhan.ico',
  )

  ico_src = import('windows').compile_resources('ico.rc', depends: daikhan_ico)
endif
