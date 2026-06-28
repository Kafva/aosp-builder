#!/usr/bin/env bash
set -e

#
# The emu_img_zip target in the build system creates images that are meant to be
# placed under $ANDROID_HOME/system-images and used by avdmanager.
# The avdmanager program will not recognize entries unless they have a
# package.xml, the package.xml does not appear to be automatically generated
# from the build system, so we do it here..
#

echox () { echo "+ $*" && $@; }
die() { printf "$(basename $0): $1\n" >&2 && exit 1; }
get_build_prop() { awk -F= "/$1=/{print \$2}" "$AVD_TMP/$ARCH/build.prop"; }
get_source_prop() { awk -F= "/$1=/{print \$2}" "$AVD_TMP/$ARCH/source.properties"; }
usage() {
    cat << EOF >&2
usage: [TARGET=] $(basename $0) [OPTIONS]

Package a sdk-repo-linux-system-images.zip into an archive recognizable by avdmanager.
	
OPTIONS:
    -i <system-images.zip>       Path to emu_img.zip for import
    -o <images.tar.xz>           Output AVD archive path.

EOF
    exit 1
}

while getopts ":i:o:" opt; do
    case $opt in
    i) EMU_IMG_ZIP=$OPTARG ;;
    o) OUT_IMGS=$OPTARG ;;
    *) usage ;;
    esac
done

shift $((OPTIND - 1))

if [[ -z "$TARGET" || ! -f "$EMU_IMG_ZIP" || -z "$OUT_IMGS" ]]; then
    usage
fi

################################################################################

AVD_TMP=$(mktemp -d)

echox unzip -q $EMU_IMG_ZIP -d $AVD_TMP
ARCH=$(ls -1 $AVD_TMP)
API_LEVEL=$(get_build_prop ro.build.version.sdk)

cat << EOF > "$AVD_TMP/$ARCH/package.xml"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ns2:repository xmlns:ns2="http://schemas.android.com/repository/android/common/02" xmlns:ns3="http://schemas.android.com/repository/android/common/01" xmlns:ns4="http://schemas.android.com/repository/android/generic/01" xmlns:ns5="http://schemas.android.com/repository/android/generic/02" xmlns:ns6="http://schemas.android.com/sdk/android/repo/addon2/01" xmlns:ns7="http://schemas.android.com/sdk/android/repo/addon2/02" xmlns:ns8="http://schemas.android.com/sdk/android/repo/addon2/03" xmlns:ns9="http://schemas.android.com/sdk/android/repo/repository2/01" xmlns:ns10="http://schemas.android.com/sdk/android/repo/repository2/02" xmlns:ns11="http://schemas.android.com/sdk/android/repo/repository2/03" xmlns:ns12="http://schemas.android.com/sdk/android/repo/sys-img2/04" xmlns:ns13="http://schemas.android.com/sdk/android/repo/sys-img2/03" xmlns:ns14="http://schemas.android.com/sdk/android/repo/sys-img2/02" xmlns:ns15="http://schemas.android.com/sdk/android/repo/sys-img2/01">
  <localPackage path="system-images;android-$API_LEVEL;$TARGET;$ARCH" obsolete="false">
    <type-details
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="ns12:sysImgDetailsType">
      <api-level>$API_LEVEL</api-level>
      <extension-level>$(get_source_prop AndroidVersion.ExtensionLevel)</extension-level>
      <base-extension>true</base-extension>
      <tag>
        <id>$TARGET</id>
        <display>$TARGET</display>
      </tag>
      <vendor>
        <id>$TARGET</id>
        <display>$TARGET</display>
      </vendor>
      <abi>$ARCH</abi>
      <abis>$ARCH</abis>
    </type-details>
    <revision>
      <major>$(get_source_prop Pkg.Revision)</major>
    </revision>
    <display-name>$TARGET</display-name>
    <dependencies>
      <dependency path="emulator">
        <min-revision>
          <major>$(get_source_prop Pkg.Dependencies | cut -d. -f1 | grep -oE "[0-9]+")</major>
          <minor>$(get_source_prop Pkg.Dependencies | cut -d. -f2)</minor>
          <micro>$(get_source_prop Pkg.Dependencies | cut -d. -f3)</micro>
        </min-revision>
      </dependency>
    </dependencies>
  </localPackage>
</ns2:repository>
EOF

mkdir -p $(dirname $OUT_IMGS)
echox tar -C $AVD_TMP -cJf $OUT_IMGS .

rm -rf $AVD_TMP
