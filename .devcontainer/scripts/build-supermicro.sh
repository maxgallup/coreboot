#!/bin/bash

# The following script builds the custom flash for the Supermicro X11SSH-LN4F board.
# After physically connecting, it can be flashed.


# Make sure all submodules are present
echo ">>> Clone git submodules"
git submodule sync
git submodule update --init --recursive --remote

# Build the cross compiler toolchain, coreboot recommends this over native toolchains
echo ">>> Building cross-compiler toolchain"
make crossgcc-i386 CPUS=`nproc`


# Build the idftool utility
echo ">>> Building extractor tool"
make -C ./util/ifdtool




# This step extracts the existing firmware blobs from the flash image that the motherboard came 
# with. This step assumes that the original firmware has been read into roms/original_supermicro.rom
echo ">>> Extracting vendor files"
mkdir -p ./extracted/supermicro
pushd ./extracted/supermicro
../../util/ifdtool/ifdtool --platform sklkbl --extract ../../roms/original_supermicro.rom
popd


# Instead of extracting the vedor files, and compiling them in, we might also be able to
# just flash the bios and leave other regions like ME untouched. To do this we can get the
# layout and then pass the layout file to flashrom and specify the region we want to write.
# echo ">>> Creating layout file"
# ./util/ifdtool/ifdtool -f ./roms/orginal_supermicro.layout ./roms/original_supermicro.rom --platform sklkbl


echo ">>> Configuring Supermicro"
make distclean
touch .config
./util/scripts/config --enable CONFIG_VENDOR_SUPERMICRO
./util/scripts/config --enable CONFIG_BOARD_SUPERMICRO_X11SSH_F
./util/scripts/config --enable CONFIG_PAYLOAD_ELF
./util/scripts/config --set-str CONFIG_PAYLOAD_FILE "payloads/coreinfo/build/coreinfo.elf"

# WRONG:
# ./util/scripts/config --set-str IFWI_FILE_NAME "extracted/supermicro/flashregion_1_bios.bin"
# ./util/scripts/config --set-str IFD_BIN_PATH "extracted/supermicro/flashregion_0_flashdescriptor.bin"
# make olddefconfig

# echo ">>> Building coreboot for Supermicro"
# make


# Run test
# qemu-system-x86_64 -bios build/coreboot.rom -serial stdio
