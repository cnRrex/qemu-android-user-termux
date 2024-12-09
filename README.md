# QEMU android linux_user termux package

This repo is to build qemu linux_user in termux-packages build system, modified from termux-packages/packages/qemu-system-x86-64-headless.
It build the branch with android prefix of [QEMU android](https://github.com/cnRrex/qemu).
The QEMU is patched to support binfmt_misc P flag on Android, uses /system/bin/gnemul/(arch)/linker(64) as default target linker and it can be changed by command line option.
Min android api is 24 (Android 7.0) in termux packages.
If you need to run on lower android version, just build static version with qemu's own build system on linux host.

## Changes
1. Some atches to restore some hardcoded path, includes ndk-toolchain, glib, qemu. Need to check more paths and restore.
2. Add rpath "/system/lib(64)/termux_libs". The libraries that QEMU depends on will be placed here to avoid conflicts.
3. Some other patches. See in termux_packages_patches.

## Build
1. Clone [termux-packages](https://github.com/termux/termux-packages) and `git apply` or `git am` the patches in folder termux_packages_patches.
If meet conflicts, you can checkout to the point when the patches generated (See in `termux_packages_patches_REPO_HEAD.txt`).
2. Copy `qemu-android-user-test` to /path/to/termux-packages/packages/
3. You can change the repositories url in `repo.json` to use faster mirrors. See [termux-packages Mirrors](https://github.com/termux/termux-packages/wiki/Mirrors).
4. Follow the [termux-packages Build-environment](https://github.com/termux/termux-packages/wiki/Build-environment) to run the docker environment.
5. In docker environment, run `./clean.sh` to clean up. Then run `./build-package.sh -a x86_64 -I libandroid-shmem zlib libiconv pcre2 glib capstone qemu-android-user-test` to build x86_64 versions. The arch could be `x86_64`, `i686`, `aarch64`, `arm`. You can add `-d` to build debug non-striped version.
6. This branch is build statically linking to the termux libs (glib etc.). Change the LDFLAGS in build.sh if needed.

## TODO
A new branch to adapt to nb-qemu.
