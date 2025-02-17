#!/bin/bash

echo "todo, consolidate all into one repo"

flashrom -p serprog:dev=/dev/ttyACM0:115200,spispeed=12M -c W25Q128.W -r test_flash_readout.rom -V --progress

