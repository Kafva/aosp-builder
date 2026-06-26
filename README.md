# aosp-builder
Wrapper scripts to build and package AOSP system images, mainly for userdebug/eng emulator.

## Building
The following targets are supported:

- `aosp` (stock Android from Google)
- `grapheneos`

To fetch the AOSP source code:
```bash
make TARGET=... sync
```

To start the build:
```bash
make TARGET=... build
```

### System requirements
* OS: Linux or macOS (the build is done in a container, either Docker or Apple Container).
* RAM: *At least* 64 GB.
* Disk: *At least* 256 GB of *free* space.

Building with less RAM can work but requires a lot of swap space (~32 GB) and
the job count can not be too high. The initial makefile / blueprint parsing is
one of the most RAM intensive stages, `SOONG_ONLY=true` reduces the required
RAM a bit.

## Running emulator builds
The build output is saved in a tar archive under `out`. To run the emulator with this
build follow the steps below (replacing grapheneos-15 etc. with values applicable to you).

1. Unpack the AVD archive on your host
```bash
tar -xf ./grapheneos-15-x86_64-system-images.tar.xz -C ~/.android/avd/
# => ~/.android/avd/grapheneos-15.avd
```
2. Create an AVD config for it:
```bash
cat << EOF > ~/.android/avd/grapheneos-15.ini
avd.ini.encoding=UTF-8
path.rel=avd/grapheneos-15.avd
target=android-35
EOF
```
3. Start the emulator
```bash
emulator @grapheneos-15
```

Some prebuilt archives are available under [releases on
Github](https://github.com/Kafva/aosp-builder/releases).

## Tips
* To debug the build system you can use `make shell` and `get_build_var <VARNAME>`.
* Patches can placed under `./patches` and be applied / reverted with `make patch` / `make unpatch`.
* If you are looking for the `emulator` sources, these are usually not part of
  the aosp checkout, they can be found [here](https://android.googlesource.com/platform/external/qemu).
