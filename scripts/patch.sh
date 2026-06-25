#!/usr/bin/env bash
set -e

while read -r f; do
    (cd $1/$(dirname ${f##./patches/}) && git apply -v -C100 $f)
done < <(find ./patches -type f -name '*.diff')
