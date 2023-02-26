desktop_file = files('io.gitlab.Envision.MediaPlayer.desktop')
install_data(desktop_file,
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

subdir('icons')
