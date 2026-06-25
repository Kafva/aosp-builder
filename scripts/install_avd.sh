#!/usr/bin/env bash
set -e

die() { printf "$(basename $0): $1\n" >&2 && exit 1; }
getprop() { awk -F= "/$1=/{print \$2}" $AVD_DIR/build.prop; }
usage() {
    cat << EOF >&2
usage: $(basename $0) [OPTIONS]

Import a emu_img_zip as an AVD.

OPTIONS:
    -i <images>       Path to emu_img.zip for import
    -n <name>         Name of AVD to create

EOF
    exit 1
}

while getopts ":i:n:" opt; do
    case $opt in
    i) EMU_IMG_ZIP=$OPTARG ;;
    n) AVD=$OPTARG ;;
    *) usage ;;
    esac
done

shift $((OPTIND - 1))

command -v awk &> /dev/null || die "missing awk"
command -v unzip &> /dev/null || die "missing unzip"

if [[ -z "$AVD" || ! -f "$EMU_IMG_ZIP" ]]; then
    usage
fi

AVD_DIR=$HOME/.android/avd/${AVD}.avd
AVD_INI=$HOME/.android/avd/${AVD}.ini

################################################################################

rm -rf $AVD_DIR
mkdir -p $AVD_DIR
unzip $EMU_IMG_ZIP -d $AVD_DIR

# Place everything directly under $AVD_DIR
if [ -d "$AVD_DIR/$(uname -m)" ]; then
    mv $AVD_DIR/$(uname -m)/* $AVD_DIR/
    rmdir $AVD_DIR/$(uname -m)
elif [ -d "$AVD_DIR/arm64-v8a" ]; then
    mv $AVD_DIR/arm64-v8a/* $AVD_DIR/
    rmdir $AVD_DIR/arm64-v8a
else
    die "Unexpected emu_img_zip layout"
fi

cat << EOF > $AVD_INI
avd.ini.encoding=UTF-8
path=$AVD_DIR
path.rel=avd/${AVD}.avd
target=android-$(getprop ro.build.version.sdk)
EOF

cat << EOF > $AVD_DIR/config.ini
AvdId = $AVD
image.sysdir.1 = $AVD_DIR
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

cat << EOF
Path to AVD:         $AVD_DIR
Launch command:      emulator @$AVD
EOF
