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
