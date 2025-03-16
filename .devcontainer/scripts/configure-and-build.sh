#!/bin/bash

# The following script builds the custom flash for the Supermicro X11SSH-LN4F board.
# After physically connecting, it can be flashed.




function first_time_init() {
    # Make sure all submodules are present
    echo ">>> Clone git submodules"
    git submodule init
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

    echo ">>> Extracting vendor files"
    mkdir -p ./extracted/up-squared
    pushd ./extracted/up-squared
    ../../util/ifdtool/ifdtool --extract ../../blobs_libmicro/coreboot.rom
    popd

    # Instead of extracting the vedor files, and compiling them in, we might also be able to
    # just flash the bios and leave other regions like ME untouched. To do this we can get the
    # layout and then pass the layout file to flashrom and specify the region we want to write.
    # echo ">>> Creating layout file"
    # ./util/ifdtool/ifdtool -f ./roms/orginal_supermicro.layout ./roms/original_supermicro.rom --platform sklkbl
}



function configure_qemu() {
    echo ">>> Configuring Qemu-example"
    make distclean
    touch .config

    # grub
    ./util/scripts/config --enable CONFIG_PAYLOAD_GRUB2
    ./util/scripts/config --enable CONFIG_PAYLOAD_BUILD_GRUB2
    ./util/scripts/config --enable CONFIG_GRUB2_STABLE
    ./util/scripts/config --enable CONFIG_PROBE_RAM
    ./util/scripts/config --set-str CONFIG_PAYLOAD_FILE "payloads/external/GRUB2/grub2/build/default_payload.elf"
    ./util/scripts/config --set-str CONFIG_GRUB2_EXTRA_MODULES ""

    # coreinfo payload
    # ./util/scripts/config --enable CONFIG_PAYLOAD_ELF
    # ./util/scripts/config --set-str CONFIG_PAYLOAD_FILE "payloads/coreinfo/build/coreinfo.elf"

    make olddefconfig
}


function configure_upsquared() {
    echo ">>> Configuring UP Squared with Red Unlock"
    make distclean
    touch .config
    ./util/scripts/config --enable VENDOR_UP
    ./util/scripts/config --enable BOARD_UP_SQUARED
    ./util/scripts/config --enable NEED_IFWI
    ./util/scripts/config --enable HAVE_IFD_BIN
    ./util/scripts/config --set-str IFWI_FILE_NAME "extracted/up-squared/flashregion_1_bios.bin"
    ./util/scripts/config --set-str IFD_BIN_PATH "extracted/up-squared/flashregion_0_flashdescriptor.bin"
    ./util/scripts/config --enable RED_UNLOCK
    ./util/scripts/config --disable "DEFAULT_CONSOLE_LOGLEVEL_$(./util/scripts/config --state DEFAULT_CONSOLE_LOGLEVEL)"
    ./util/scripts/config --enable DEFAULT_CONSOLE_LOGLEVEL_0
    make olddefconfig

    echo ">>> Building coreboot for up-squared"
    make
}


function configure_supermicro() {
    echo ">>> Configuring Supermicro"
    make distclean
    touch .config

    ./util/scripts/config --enable CONFIG_VENDOR_SUPERMICRO
    ./util/scripts/config --enable CONFIG_USE_LEGACY_8254_TIMER
    ./util/scripts/config --enable CONFIG_HAVE_IFD_BIN
    ./util/scripts/config --enable CONFIG_BOARD_SUPERMICRO_X11SSH_F
    ./util/scripts/config --enable CONFIG_HAVE_ME_BIN
    ./util/scripts/config --set-str CONFIG_IFD_BIN_PATH "extracted/supermicro/flashregion_0_flashdescriptor.bin"
    ./util/scripts/config --set-str CONFIG_ME_BIN_PATH "extracted/supermicro/flashregion_2_intel_me.bin"

    ./util/scripts/config --enable  CONFIG_ONBOARD_VGA_IS_PRIMARY
    ./util/scripts/config --enable  CONFIG_HAVE_VGA_TEXT_FRAMEBUFFER
    ./util/scripts/config --enable  CONFIG_VGA_TEXT_FRAMEBUFFER
    ./util/scripts/config --enable  CONFIG_VGA

    # Coreinfo Payload
    ./util/scripts/config --enable CONFIG_PAYLOAD_ELF
    ./util/scripts/config --set-str CONFIG_PAYLOAD_FILE "payloads/coreinfo/build/coreinfo.elf"

    make olddefconfig
}


function build() {
    echo ">>> Building coreboot"
    make
}

if [[ "$2" == "--init" ]]; then
    first_time_init
fi

if [[ "$1" == "qemu" ]]; then
    configure_qemu
elif [[ "$1" == "upsquared" ]]; then
    configure_upsquared
elif [[ "$1" == "supermicro" ]]; then
    configure_supermicro
else
    # Help: Any other argument passed
    echo "Usage: $(basename $0) [qemu|upsquared|supermicro] [--init]"
    echo "  upsquared:    config for UP Squared hardware"
    echo "  supermicro:   config for Supermicro hardware"
    echo "  qemu:         config for QEMU example"
    exit 1
fi

build

echo "Done building: coreboot/build/coreboot.rom"
