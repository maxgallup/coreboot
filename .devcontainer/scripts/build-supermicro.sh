#!/bin/bash


# Coreboot 
echo ">>> Clone git submoduels"
git submodule sync
git submodule update --init --recursive --remote

echo ">>> Building cross-compiler toolchain"
make crossgcc-i386 CPUS=`nproc`


echo ">>> Configuring UP Squared with Red Unlock"
make distclean
touch .config
./util/scripts/config --enable CONFIG_VENDOR_SUPERMICRO
./util/scripts/config --enable CONFIG_BOARD_SUPERMICRO_X11SSH_F
./util/scripts/config --enable CONFIG_PAYLOAD_ELF
./util/scripts/config --set-str CONFIG_PAYLOAD_FILE "payloads/coreinfo/build/coreinfo.elf"
make olddefconfig

echo ">>> Building coreboot for up-squared"
make



# Run test
# qemu-system-x86_64 -bios build/coreboot.rom -serial stdio
