hicolor_dir = get_option('datadir') / 'icons/hicolor'

profile = get_option('profile')
if profile == 'devel'
  install_data('io.gitlab.Envision.MediaPlayer.Devel.svg',
    install_dir: hicolor_dir/'scalable/apps',
         rename: 'io.gitlab.Envision.MediaPlayer.svg'
  )
elif profile == 'beta'
  install_data('io.gitlab.Envision.MediaPlayer.Beta.svg',
    install_dir: hicolor_dir/'scalable/apps',
         rename: 'io.gitlab.Envision.MediaPlayer.svg'
  )
else
  install_data('io.gitlab.Envision.MediaPlayer.svg',
    install_dir: hicolor_dir/'scalable/apps',
  )
endif

install_data('io.gitlab.Envision.MediaPlayer-symbolic.svg',
  install_dir: hicolor_dir/'symbolic/apps',
)
