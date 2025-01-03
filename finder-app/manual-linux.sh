#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-


if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone  ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi

if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout  ${KERNEL_VERSION}
    git restore './scripts/dtc/dtc-lexer.l'
    sed -i '41d' './scripts/dtc/dtc-lexer.l'


    # TODO: Add your kernel build steps here
    echo "Starting mrproper..."
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- mrproper
    echo "Starting defconfig..."
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- defconfig
    echo "Starting all..."
    make -j4 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- all
    
    echo "Starting modules\nPress any key to continue..."
    #make -j4 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- modules
    echo "Starting dtbs\nPress any key to continue..."
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- dtbs
fi

echo "Adding the Image in outdir"
echo "Copying image to ${OUTDIR}..."
cp  ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}
cp  ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image.gz ${OUTDIR}
echo "Finished building linux image..."


echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"

echo "Deleting rootfs"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
for d in  'bin' 'dev' 'etc' 'lib' 'lib64' 'proc' 'sbin'  'sys' 'tmp' 'usr' 'var' 'root' 'usr/bin'  'usr/lib'  'usr/sbin'  'var/log'; 

	do
		mkdir -p ${OUTDIR}/rootfs/$d
	done


cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make distclean
    make defconfig
else
    cd busybox
fi
echo "Compile busybox and install"
# TODO: Make and install busybox

if [ ! -e ${OUTDIR}/bin/busybox ]; then

	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
	make CONFIG_PREFIX="${OUTDIR}/rootfs" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

fi

cd ${OUTDIR}/rootfs
mkdir -p home

echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
cp ${FINDER_APP_DIR}/lib/libm.so.6  ${OUTDIR}/rootfs/lib64/
cp ${FINDER_APP_DIR}/lib/libresolv.so.2  ${OUTDIR}/rootfs/lib64/
cp ${FINDER_APP_DIR}/lib/libc.so.6  ${OUTDIR}/rootfs/lib64/
cp ${FINDER_APP_DIR}/lib/ld-linux-aarch64.so.1  ${OUTDIR}/rootfs/lib/

# TODO: Make device nodes
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/console c 1 5

# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}
if [ ! -e ./writer ]; then
	# Compile if needed
	make CROSS_COMPILE=${CROSS_COMPILE}
fi

echo "####################################################"
echo "OUTDIR=$OUTDIR"
echo "RUNNING manual-linux.sh"
echo "####################################################"

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs

cp writer "$OUTDIR/rootfs/home"
cp "finder.sh" "$OUTDIR/rootfs/home"
cp "username.txt" "$OUTDIR/rootfs/home"
cp "assignment.txt" "$OUTDIR/rootfs/home"
cp "autorun-qemu.sh" "$OUTDIR/rootfs/home"
cp "finder-test.sh" "$OUTDIR/rootfs/home"
# TODO: Chown the root directory
cd ${OUTDIR}
sudo chown -R root:root ./rootfs

# TODO: Create initramfs.cpio.gz
cd "$OUTDIR/rootfs"
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
cd "$OUTDIR"
gzip -f initramfs.cpio



if [ ! -e "${OUTDIR}/Image" ]; then
echo "ERROR NO IMAGE FOUND!"
exit -1
fi
