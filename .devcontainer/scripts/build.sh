#!/bin/bash

# This script is used to build the coreboot image which is flashed onto the ROM.
# The build process is isolated from the host, since it runs inside a docker
# container. However, the resulting files will be in the /build directory

# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Error: No argument provided"
    echo "Usage: $0 [up-squared|supermicro]"
    exit 1
fi

# Check first argument with separate branches
if [ "$1" = "up-squared" ]; then
    echo "Building UP-squared target inside a docker container"
    docker run -u coreboot -v `pwd`:/home/coreboot/work -w /home/coreboot/work -it coreboot/coreboot-sdk:latest .devcontainer/scripts/build-up-squared.sh

elif [ "$1" = "supermicro" ]; then
    echo "todo"
else
    echo "Error: Invalid argument"
    echo "Argument must be either 'up-squared' or 'supermicro'"
    exit 1
fi






