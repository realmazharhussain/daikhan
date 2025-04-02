i18n.gettext(exe_name)

custom_target('pot_file',
  output: 'daikhan.pot',
  command: [files('update-pot-file.sh')],
  env: {
    'PACKAGE_VERSION': meson.project_version(),
    'SOURCE_ROOT': meson.project_source_root(),
  },
  build_by_default: false,
)
