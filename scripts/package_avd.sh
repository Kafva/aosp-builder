#!/usr/bin/env bash
set -e

echox () { echo "+ $*" && $@; }
die() { printf "$(basename $0): $1\n" >&2 && exit 1; }
getprop() { awk -F= "/$1=/{print \$2}" "$AVD_TMP/$AVD_NAME.avd/build.prop"; }
usage() {
    cat << EOF >&2
usage: $(basename $0) [OPTIONS]

Package a sdk-repo-linux-system-images.zip into an AVD.

OPTIONS:
    -i <system-images.zip>       Path to emu_img.zip for import
    -o <images.tar.xz>           Output AVD archive path.
    -n <name>                    Name of AVD to create

EOF
    exit 1
}

while getopts ":i:n:o:" opt; do
    case $opt in
    i) EMU_IMG_ZIP=$OPTARG ;;
    o) OUT_IMGS=$OPTARG ;;
    n) AVD_NAME=$OPTARG ;;
    *) usage ;;
    esac
done

shift $((OPTIND - 1))

if [[ -z "$AVD_NAME" || ! -f "$EMU_IMG_ZIP" || -z "$OUT_IMGS" ]]; then
    usage
fi

################################################################################

AVD_TMP=$(mktemp -d)

echox unzip -q $EMU_IMG_ZIP -d $AVD_TMP

# The system-images.zip has a leading folder with the architecture name.
mv $AVD_TMP/* "$AVD_TMP/$AVD_NAME.avd"

cat << EOF > "$AVD_TMP/$AVD_NAME.avd/config.ini"
AvdId = $AVD_NAME
image.sysdir.1 = .
avd.ini.encoding = UTF-8
disk.dataPartition.size = 6G
fastboot.forceColdBoot = yes
PlayStore.enabled = false

hw.accelerometer = yes
hw.cpu.arch = $(getprop ro.product.cpu.abi)
# Disable audio
hw.audioInput = no
hw.audioOutput = no
hw.battery = yes
# The emulator tries to talk with port 1970 on the host when the
# 'multitouch' (the default) is set.
hw.screen = touch
hw.camera.back = emulated
hw.camera.front = emulated
hw.dPad = no
hw.gps = yes
hw.gpu.enabled = yes
hw.gpu.mode = auto
hw.cpu.ncore = 4
hw.gsmModem = true
hw.gyroscope = true
hw.initialOrientation = Portrait
hw.keyboard = yes
hw.ramSize = 4096
# Display size
hw.lcd.width = 600
hw.lcd.height = 1180
hw.lcd.density = 320
EOF

cat << EOF > "$AVD_TMP/$AVD_NAME.ini"
avd.ini.encoding=UTF-8
path.rel=avd/$AVD_NAME.avd
target=android-$(getprop ro.build.version.sdk)
EOF

mkdir -p $(dirname $OUT_IMGS)
echox tar -C $AVD_TMP -cJf $OUT_IMGS .

rm -rf $AVD_TMP
