sources = [config_file] + content_id_file + files(
  'main.vala',
  'Application.vala',
)

deps = [
  dep_gio,
  dep_xxhash,
]

executable('daikhan-content-id', sources,
           dependencies: deps,
           win_subsystem: 'windows',
           install: true)
