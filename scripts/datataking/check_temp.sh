# Run this script when ssh'ed to PACMAN

TEMP_FILE="/sys/bus/iio/devices/iio:device0/in_temp0_raw"
TEMP_RAW=$(cat "$TEMP_FILE")
TEMP_C=$(awk "BEGIN {printf \"%.2f", $TEMP_RAW / 8.127 - 273.15}"
echo "The CPU temperature is ${TEMP_RAW}C, should see between 50C and 60C during normal operation")
