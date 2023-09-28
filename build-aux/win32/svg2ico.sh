#!/usr/bin/env bash
tmp_dir=$(mktemp -d)

output=$1
input=$2
shift 2
sizes=($@)

png_files=()
input_basename=$(basename "${input%.*}")
for width in "${sizes[@]}"; do
  png="${tmp_dir}/${input_basename}_${width}.png"
  rsvg-convert "${input}" -w "${width}" -o "${png}"
  png_files+=("$png")
done

icotool -c -o "${output}" "${png_files[@]}"

rm -rf "${tmp_dir}"
