# aosp-builder

Wrapper repository to build and package AOSP system images.
The following targets are supported:
- `aosp` (stock Android from Google)
- `grapheneos`

```bash
make TARGET=... source && make TARGET=... build
```


## Tips
* At least 64 GB of RAM is recommended to build, building with less can work
  but requires a lot of swap space (>= 32 GB) and a low job count (<= 6). The
  initial makefile / blueprint parsing is one of the most RAM intensive stages,
  `SOONG_ONLY=true` reduces the required RAM a bit.
* If you are looking for the `emulator` sources, these are usually not part of
  the aosp checkout, they can be found [here](https://android.googlesource.com/platform/external/qemu).
