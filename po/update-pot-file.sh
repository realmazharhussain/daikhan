#!/bin/bash
po_dir=$(dirname "$(realpath "$0")")

if test -z "$PACKAGE_VERSION" || test -z "$SOURCE_ROOT"; then
    echo "Do not run this script directly. Instead, run" \
         "'meson compile -C <buiddir> pot_file'." >&2
    exit 1
fi

cd "$SOURCE_ROOT"

options=(
  -f "$po_dir"/POTFILES.in
  -o "$po_dir"/daikhan.pot
  --add-comments=Translators
  --keyword=_
  --keyword=C_:1c,2
  --from-code=UTF-8

  --package-name="daikhan"
  --package-version="$PACKAGE_VERSION"
  --msgid-bugs-address="realmazharhussain@gmail.com"
)

output=$(xgettext "${options[@]}" 2>&1)
status=$?

while read line
do
  if [[ "$line" != *"extension 'blp' is unknown; will try C" ]]; then
    echo "$line" >&2
  fi
done <<< "$output"

exit $status
