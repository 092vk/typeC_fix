#!/bin/bash

DEVICE1="6-0022"
DEVICE0="1-0022"
DRIVER_PATH="/sys/bus/i2c/drivers/typec_fusb302"
DP0_NAME="DP-1"
DP1_NAME="DP-2"

# Cooldown period in seconds
COOLDOWN=10

# Initialize last reset timestamps to 0
LAST_RESET0=0
LAST_RESET1=0

# --- Function to handle the Reset Logic ---
perform_reset() {
    local dev=$1
    local dp_out=$2
    local timestamp=$(date '+%F %T')

    echo "$timestamp Log Trigger: Resetting $dev ($dp_out)"

    # Driver Rebind
    echo "$dev" > "$DRIVER_PATH/unbind"
    sleep 1
    echo "$dev" > "$DRIVER_PATH/bind"

    # Display Toggle
    sleep 2
    xrandr --output "$dp_out" --off
    sleep 1
    xrandr --output "$dp_out" --auto
}

# --- Background Listener for dmesg ---

(
dmesg -w | stdbuf -oL grep --line-buffered "DP Alt Mode activating on" | while read -r line; do
    CURRENT_TIME=$(date +%s)

    if [[ "$line" == *"$DEVICE0"* ]]; then
        # Check if enough time has passed since the last reset for DEVICE0
        if (( CURRENT_TIME - LAST_RESET0 > COOLDOWN )); then
            echo "Condition met for $DEVICE0. Performing reset..."
            perform_reset "$DEVICE0" "$DP0_NAME"
            LAST_RESET0=$(date +%s) # Update the timestamp after reset
        else
            echo "Skipping $DEVICE0 reset: Cooldown active ($(expr $COOLDOWN - $((CURRENT_TIME - LAST_RESET0)))s remaining)"
        fi

    elif [[ "$line" == *"$DEVICE1"* ]]; then
        # Check if enough time has passed since the last reset for DEVICE1
        if (( CURRENT_TIME - LAST_RESET1 > COOLDOWN )); then
            echo "Condition met for $DEVICE1. Performing reset..."
            perform_reset "$DEVICE1" "$DP1_NAME"
            LAST_RESET1=$(date +%s) # Update the timestamp after reset
        else
            echo "Skipping $DEVICE1 reset: Cooldown active ($(expr $COOLDOWN - $((CURRENT_TIME - LAST_RESET1)))s remaining)"
        fi
    fi
done
)&

# ---  Polling Logic for SINK devices ---
while true; do
    VAL1=$(i2cget -f -y 6 0x22 0x42)
    TIMESTAMP1=$(date '+%F %T')
    VAL0=$(i2cget -f -y 1 0x22 0x42)
    TIMESTAMP0=$(date '+%F %T')

    echo "$TIMESTAMP1 Polling Port 1: $VAL1"
    echo "$TIMESTAMP0 Polling Port 0: $VAL0"

    if [ "$VAL1" = "0x20" ]; then
        echo "$TIMESTAMP1 Detected 0x20 (Port 1) - Polling Triggered Reset"
        perform_reset "$DEVICE1" "$DP1_NAME"
    fi

    if [ "$VAL0" = "0x20" ]; then
        echo "$TIMESTAMP0 Detected 0x20 (Port 0) - Polling Triggered Reset"
        perform_reset "$DEVICE0" "$DP0_NAME"
    fi

    sleep 1
done
