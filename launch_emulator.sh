#!/bin/bash

# Set Android SDK paths
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# List available AVDs
echo "Available AVDs:"
$ANDROID_HOME/emulator/emulator -list-avds

# Check if an AVD name was provided as an argument
if [ $# -eq 0 ]; then
    echo "No AVD specified. Usage: ./launch_emulator.sh <AVD_NAME>"
    echo "Available options:"
    echo "  - OPTION_Driver_Pixel8"
    echo "  - OPTION_Passenger_Pixel8"
    echo "  - OPTION_Third_Pixel8"
    echo "  - Pixel_8_API_34"
    echo "  - Pixel_8_API_35"
    exit 1
fi

# Launch the emulator with the specified AVD
echo "Launching emulator with AVD: $1"
$ANDROID_HOME/emulator/emulator -avd $1 &
echo "Emulator launched successfully! Please wait for it to fully boot."