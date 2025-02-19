#!/bin/bash

echo "todo, consolidate all into one repo"

# This script is used to write the custom coreboot image to the the connected 
# eeprom chip.

# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Error: No argument provided"
    echo "Usage: $0 [coreboot.rom]"
    exit 1
fi


# Write command
# flashrom -p serprog:dev=/dev/ttyACM0:115200,spispeed=12M -c W25Q128.W -w $1 -V --progress

# Read command for UPSquared chip
# flashrom -p serprog:dev=/dev/ttyACM0:115200,spispeed=12M -c W25Q128.W -r up_squared_readout.rom -V --progress

# Read command for SuperMicro chip
# flashrom -p serprog:dev=/dev/ttyACM0:115200,spispeed=12M -c W25Q128.V -r supermicro_readout.rom -V --progress


# Scan
# flashrom -p serprog:dev=/dev/ttyACM0:115200,spispeed=12M -V




