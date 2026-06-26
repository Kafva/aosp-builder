#!/usr/bin/env bash
set -e

while read -r f; do
    git -C "$1/$(dirname ${f##./patches/})" apply -v -C100 $PWD/$f
done < <(find ./patches -type f -name '*.diff')
