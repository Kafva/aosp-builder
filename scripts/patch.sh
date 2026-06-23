#!/usr/bin/env bash
set -e

AOSP=$1

if [ ! -d "$1" ]; then
    echo "$0: <aosp>"
    exit 1
fi

while read -r f; do
    (cd $AOSP/$(dirname ${f##./patches/}) && git apply -v -C100 $f)
done < <(find ./patches -type f -name '*.diff')


