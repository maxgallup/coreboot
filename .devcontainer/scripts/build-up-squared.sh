#!/bin/bash


# Coreboot 
echo ">>> Clone git submoduels"
git submodule sync
git submodule update --init --recursive --remote

echo ">>> Building cross-compiler toolchain"
make crossgcc-i386 CPUS=`nproc`

echo ">>> Building extractor tool"
make -C ./util/ifdtool

echo ">>> Extracting vendor files"
mkdir -p ./extracted
pushd ./extracted
../util/ifdtool/ifdtool -x ../blobs_libmicro/coreboot.rom
popd

echo ">>> Configuring UP Squared with Red Unlock"
make distclean
touch .config
./util/scripts/config --enable VENDOR_UP
./util/scripts/config --enable BOARD_UP_SQUARED
./util/scripts/config --enable NEED_IFWI
./util/scripts/config --enable HAVE_IFD_BIN
./util/scripts/config --set-str IFWI_FILE_NAME "extracted/flashregion_1_bios.bin"
./util/scripts/config --set-str IFD_BIN_PATH "extracted/flashregion_0_flashdescriptor.bin"
./util/scripts/config --enable RED_UNLOCK
./util/scripts/config --disable "DEFAULT_CONSOLE_LOGLEVEL_$(./util/scripts/config --state DEFAULT_CONSOLE_LOGLEVEL)"
./util/scripts/config --enable DEFAULT_CONSOLE_LOGLEVEL_0
make olddefconfig

echo ">>> Building coreboot for up-squared"
make



# Run test
# qemu-system-x86_64 -bios build/coreboot.rom -serial stdio
