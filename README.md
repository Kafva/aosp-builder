# aosp-builder

Wrapper repository to build and package AOSP system images, mainly for userdebug/eng emulator.

## Building
The following targets are supported:

- `aosp` (stock Android from Google)
- `grapheneos`

The build is done in a container (either Docker or Apple Container).

```bash
make TARGET=... build
```

*At least* 64 GB of RAM is recommended to build, building with less can work
but requires a lot of swap space (~32 GB) and the job count can not be too
high. The initial makefile / blueprint parsing is one of the most RAM intensive
stages, `SOONG_ONLY=true` reduces the required RAM a bit.

## Install builds
To install an emu_img_zip build as an AVD:

```bash
./scripts/install.sh -n $AVD_NAME -i $EMU_IMG_ZIP_PATH
```

Some prebuilts are available under [releases on Github](https://github.com/Kafva/aosp-builder/releases).

## Tips
* To debug the build system you can use `make shell` and `get_build_var <VARNAME>`.
* Patches can placed under `./patches` and be applied / reverted with `make patch` / `make unpatch`.
* If you are looking for the `emulator` sources, these are usually not part of
  the aosp checkout, they can be found [here](https://android.googlesource.com/platform/external/qemu).
