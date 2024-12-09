TERMUX_PKG_HOMEPAGE=https://www.qemu.org
TERMUX_PKG_DESCRIPTION="QEMU Android linux_user termux package (modified from qemu-system-x86_64-headless)"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=1:stable-9.1
TERMUX_PKG_SRCURL=https://download.qemu.org/qemu-${TERMUX_PKG_VERSION:2}.tar.xz
TERMUX_PKG_SRCURL=https://github.com/cnRrex/qemu/archive/refs/heads/android/${TERMUX_PKG_VERSION:2}.tar.gz
TERMUX_PKG_SHA256=89f2eb4ecf966bbbcbfa3f7c5661f4d88d7253d67be2afead0c597e9be716961
TERMUX_PKG_DEPENDS="dtc, glib, libbz2, libcurl, libgmp, libgnutls, libiconv, libjpeg-turbo, liblzo, libnettle, libnfs, libpixman, libpng, libslirp, libspice-server, libssh, libusb, libusbredir, ncurses, pulseaudio, resolv-conf, zlib, zstd, capstone"

# Required by configuration script, but I can't find any binary that uses it.
TERMUX_PKG_BUILD_DEPENDS="libtasn1"

TERMUX_PKG_CONFLICTS="qemu-android-user-test"
TERMUX_PKG_REPLACES="qemu-android-user-test"
TERMUX_PKG_PROVIDES="qemu-android-user-test"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
	# Workaround for https://github.com/termux/termux-packages/issues/12261.
	if [ $TERMUX_ARCH = "aarch64" ]; then
		rm -f $TERMUX_PKG_BUILDDIR/_lib
		mkdir -p $TERMUX_PKG_BUILDDIR/_lib

		cd $TERMUX_PKG_BUILDDIR
		mkdir -p _setjmp-aarch64
		pushd _setjmp-aarch64
		mkdir -p private
		local s
		for s in $TERMUX_PKG_BUILDER_DIR/setjmp-aarch64/{setjmp.S,private-*.h}; do
			local f=$(basename ${s})
			cp ${s} ./${f/-//}
		done
		$CC $CFLAGS $CPPFLAGS -I. setjmp.S -c
		$AR cru $TERMUX_PKG_BUILDDIR/_lib/libandroid-setjmp.a setjmp.o
		popd

		LDFLAGS+=" -L$TERMUX_PKG_BUILDDIR/_lib -l:libandroid-setjmp.a"
	fi
}

termux_step_configure() {
	termux_setup_ninja

	if [ "$TERMUX_ARCH" = "i686" ]; then
		LDFLAGS+=" -latomic"
	fi

	local QEMU_TARGETS=""

	# User mode emulation.
	QEMU_TARGETS+="aarch64-linux-user,"
	QEMU_TARGETS+="arm-linux-user,"
	QEMU_TARGETS+="i386-linux-user,"
	QEMU_TARGETS+="m68k-linux-user,"
	QEMU_TARGETS+="ppc64-linux-user,"
	QEMU_TARGETS+="ppc-linux-user,"
	QEMU_TARGETS+="mips64-linux-user,"
	QEMU_TARGETS+="mips-linux-user,"
	QEMU_TARGETS+="riscv32-linux-user,"
	QEMU_TARGETS+="riscv64-linux-user,"
	QEMU_TARGETS+="x86_64-linux-user"

	CFLAGS+=" $CPPFLAGS"
	CXXFLAGS+=" $CPPFLAGS"
	# defalut: link dynamically. These libs should bring to termux_libs:
	# files: libandroid-shmem.so, libandroid-support.so, libcapstone.so, libglib-2.0.so, libgmodule-2.0.so, libiconv.so, libpcre2-8.so, libz.so.1
	#LDFLAGS+=" -landroid-shmem"

	# partial static: we cant build static with bionic as there has issue with memmove etc.
	# NOTE: if we need multi-target then dont static link them to save disk usage (libs will be put to termux_libs)
	LDFLAGS+=" -l:libandroid-shmem.a -l:libglib-2.0.a -l:libcapstone.a -l:libgmodule-2.0.a -l:libz.a -l:libiconv.a"

	# Note: using --disable-stack-protector since stack protector
	# flags already passed by build scripts but we do not want to
	# override them with what QEMU configure provides.
	./configure \
		--prefix="$TERMUX_PREFIX" \
		--cross-prefix="${TERMUX_HOST_PLATFORM}-" \
		--host-cc="gcc" \
		--cc="$CC" \
		--cxx="$CXX" \
		--objcc="$CC" \
		--disable-stack-protector \
		--disable-system \
		--smbd="$TERMUX_PREFIX/bin/smbd" \
		--enable-coroutine-pool \
		--audio-drv-list=pa \
		--enable-trace-backends=nop \
		--disable-guest-agent \
		--disable-gnutls \
		--disable-nettle \
		--disable-sdl \
		--disable-sdl-image \
		--disable-gtk \
		--disable-vte \
		--enable-curses \
		--enable-iconv \
		--disable-vnc \
		--disable-vnc-sasl \
		--disable-vnc-jpeg \
		--disable-png \
		--disable-xen \
		--disable-xen-pci-passthrough \
		--disable-virtfs \
		--disable-curl \
		--disable-fdt \
		--disable-kvm \
		--disable-hvf \
		--disable-whpx \
		--disable-libnfs \
		--disable-lzo \
		--disable-snappy \
		--disable-bzip2 \
		--disable-lzfse \
		--disable-seccomp \
		--disable-libssh \
		--disable-bochs \
		--disable-cloop \
		--disable-dmg \
		--disable-parallels \
		--disable-qed \
		--disable-slirp \
		--disable-spice \
		--disable-libusb \
		--disable-usb-redir \
		--disable-vhost-user \
		--disable-vhost-user-blk-server \
		--disable-tools \
		--disable-docs \
		--disable-install-blobs \
		--enable-capstone \
		--disable-strip \
		--enable-debug-info \
		--target-list="$QEMU_TARGETS"
}

termux_step_post_make_install() {
	local i
	for i in aarch64 arm i386 m68k ppc ppc64 riscv32 riscv64 x86_64; do
		ln -sfr \
			"${TERMUX_PREFIX}"/share/man/man1/qemu.1 \
			"${TERMUX_PREFIX}"/share/man/man1/qemu-system-${i}.1
	done
}
