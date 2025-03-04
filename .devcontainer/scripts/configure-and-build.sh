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
    ./util/scripts/config --set-str CONFIG_IFD_BIN_PATH "extracted/supermicro/flashregion_0_flashdescriptor.bin"
    ./util/scripts/config --enable CONFIG_BOARD_SUPERMICRO_X11SSH_F
    ./util/scripts/config --enable CONFIG_HAVE_ME_BIN
    ./util/scripts/config --set-str CONFIG_ME_BIN_PATH "extracted/supermicro/flashregion_2_intel_me.bin"

    # Console related tests
    ./util/scripts/config --enable CONFIG_DEFAULT_CONSOLE_LOGLEVEL_7
    
    # CONFIG_UART_FOR_CONSOLE 0 is for COM1, COM2 doesn't work :(
    ./util/scripts/config --set-val CONFIG_UART_FOR_CONSOLE 0

    # We ask to load coreboot, but in bs_payload_load we take over execution
    ./util/scripts/config --enable CONFIG_PAYLOAD_ELF
    ./util/scripts/config --set-str CONFIG_PAYLOAD_FILE "payloads/coreinfo/build/coreinfo.elf"

    # SeaBios Payload - didn't work
    # ./util/scripts/config --enable CONFIG_PAYLOAD_SEABIOS
    # ./util/scripts/config --enable CONFIG_PAYLOAD_BUILD_SEABIOS
    # ./util/scripts/config --enable CONFIG_COMPRESSED_PAYLOAD_LZMA
    # ./util/scripts/config --enable CONFIG_COMPRESS_SECONDARY_PAYLOAD
    # ./util/scripts/config --enable CONFIG_SEABIOS_THREAD_OPTIONROMS
    # ./util/scripts/config --set-str CONFIG_PAYLOAD_FILE "payloads/external/SeaBIOS/seabios/out/bios.bin.elf"

    # TianoCore EDK2 - didn't work
    # ./util/scripts/config --enable CONFIG_WANT_LINEAR_FRAMEBUFFER
    # ./util/scripts/config --enable CONFIG_GENERIC_LINEAR_FRAMEBUFFER
    # ./util/scripts/config --enable CONFIG_LINEAR_FRAMEBUFFER
    # ./util/scripts/config --enable CONFIG_PAYLOAD_EDK2
    # ./util/scripts/config --enable CONFIG_EDK2_RELEASE
    # ./util/scripts/config --enable CONFIG_EDK2_FULL_SCREEN_SETUP
    # ./util/scripts/config --enable CONFIG_EDK2_HAVE_EFI_SHELL
    # ./util/scripts/config --enable CONFIG_EDK2_PRIORITIZE_INTERNAL
    # ./util/scripts/config --enable CONFIG_EDK2_PS2_SUPPORT
    # ./util/scripts/config --enable CONFIG_EDK2_UEFIPAYLOAD
    # ./util/scripts/config --enable CONFIG_EDK2_REPO_MRCHROMEBOX
    # ./util/scripts/config --set-str CONFIG_PAYLOAD_FILE "build/UEFIPAYLOAD.fd"
    # ./util/scripts/config --set-str CONFIG_EDK2_REPOSITORY "https://github.com/mrchromebox/edk2"
    # ./util/scripts/config --set-str CONFIG_EDK2_TAG_OR_REV "origin/uefipayload_202309"
    # ./util/scripts/config --set-str CONFIG_EDK2_BOOTSPLASH_FILE "Documentation/coreboot_logo.bmp"
    # ./util/scripts/config --set-str CONFIG_EDK2_CUSTOM_BUILD_PARAMS ""
    # ./util/scripts/config --set-val CONFIG_EDK2_BOOT_TIMEOUT 2
    # ./util/scripts/config --set-val CONFIG_EDK2_SD_MMC_TIMEOUT 10

    make olddefconfig

    # Run test
    # qemu-system-x86_64 -bios build/coreboot.rom -serial stdio
}


function build() {
    echo ">>> Building coreboot for Supermicro"
    make
}


if [[ "$1" == "qemu" ]]; then
    first_time_init
    configure_qemu
    build
elif [[ "$1" == "upsquared" ]]; then
    first_time_init
    configure_upsquared
    build
elif [[ "$1" == "supermicro" ]]; then
    first_time_init
    configure_supermicro
    build
else
    # Help: Any other argument passed
    echo "Usage: $(basename $0) [--init|upsquared|supermicro]"
    echo "  upsquared:    config for UP Squared hardware"
    echo "  supermicro:   config for Supermicro hardware"
    echo "  qemu:         config for QEMU example"
    exit 1
fi
