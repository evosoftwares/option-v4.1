#!/bin/bash
echo "🛑 Parando todos os emuladores OPTION..."
adb devices | grep "emulator" | cut -f1 | while read -r device; do
    echo "Parando $device..."
    adb -s "$device" emu kill
done
rm -f /tmp/option_emulator_*.pid
echo "✅ Todos os emuladores parados!"
