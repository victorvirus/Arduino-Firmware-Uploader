#!/bin/bash

# Configuration
CONFIG_PATH=/data/options.json

# Extract values from the configuration file using jq
PC_IP=$(jq -r '.pc_ip' $CONFIG_PATH)  # Name of PC in local network or its IP
SHARED_FOLDER_NAME=$(jq -r '.shared_folder_name' $CONFIG_PATH)  # Root folder with sketch which was shared over SMB
USERNAME=$(jq -r '.username' $CONFIG_PATH)  # Replace with your actual username
PASSWORD=$(jq -r '.password' $CONFIG_PATH)  # Replace with your actual password
REMOTE_FILE=$(jq -r '.remote_file' $CONFIG_PATH)  # The file to download
FIRMWARE_FILE="/tmp/$REMOTE_FILE"  # The path to save it inside the container

MCU=$(jq -r '.mcu' $CONFIG_PATH)  # For Arduino Mega 2560 (or other MCU model)
PROGRAMMER=$(jq -r '.programmer' $CONFIG_PATH)  # Method of upload (e.g., wiring)
BAUD=$(jq -r '.baud' $CONFIG_PATH)  # Baud rate for serial communication
PORT=$(jq -r '.port' $CONFIG_PATH)  # Usb port number (e.g., /dev/ttyUSB0)

# Check if jq is installed
echo "Checking if jq is installed..."
if command -v jq >/dev/null 2>&1; then
    echo "✅ jq is installed!"
else
    echo "❌ jq is not installed!"
    exit 1
fi

# Check if smbclient is installed
echo "Checking if smbclient is installed..."
if command -v smbclient >/dev/null 2>&1; then
    echo "✅ smbclient is installed!"
else
    echo "❌ smbclient is not installed!"
    exit 1
fi

# Check if avrdude is installed
echo "Checking if avrdude is installed..."
if command -v avrdude >/dev/null 2>&1; then
    echo "✅ avrdude is installed!"
else
    echo "❌ avrdude is NOT installed!"
fi

# Retry logic for downloading firmware (up to 3 attempts)
MAX_RETRIES=3
SLEEP_TIME=5
RETRY_COUNT=0
SUCCESS=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "Attempting to download firmware from //$PC_IP/$SHARED_FOLDER_NAME/$REMOTE_FILE... (Attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES)"
    smbclient "//$PC_IP/$SHARED_FOLDER_NAME" -U "$USERNAME%$PASSWORD" -c "get $REMOTE_FILE $FIRMWARE_FILE"
    
    # Check if the file was downloaded successfully
    if [ -f "$FIRMWARE_FILE" ]; then
        echo "✅ Firmware downloaded successfully!"
        SUCCESS=1
        break
    else
        echo "❌ Failed to download the firmware. Retrying..."
    fi
    
    # Increment the retry count
    RETRY_COUNT=$((RETRY_COUNT + 1))
    
    # Wait before retrying (optional)
    sleep $SLEEP_TIME
done

# If downloading failed after all retries, exit the script
if [ $SUCCESS -eq 0 ]; then
    echo "❌ Failed to download the firmware after $MAX_RETRIES attempts!"
    exit 1
fi

# Check if arduino is connected to provided port

if [ -z "$PORT" ]; then
    echo "Arduino not found on any USB port!"
    exit 1
else
    echo "Found Arduino on $PORT"
fi

# Check if the user has read/write permissions to the port
if [ -r "$PORT" ] && [ -w "$PORT" ]; then
    # If permissions are granted
    echo "✅ Arduino Access: You have access to $PORT. Proceeding with firmware flash."
else
    # If permissions are denied
    echo "❌ Error: You do not have permission to access $PORT."
    exit 1
fi

# Flash the firmware using avrdude
echo "Flashing firmware to $MCU ..."
avrdude -v -p$MCU -c$PROGRAMMER -P$PORT -b$BAUD -D -Uflash:w:$FIRMWARE_FILE:i

# Check if flashing was successful
if [ $? -eq 0 ]; then
    echo "✅ Firmware flash successful!"
else
    echo "❌ Firmware flash failed!"
fi


# Remove the downloaded file after use
echo "Attempting to remove the downloaded file..."
rm "$FIRMWARE_FILE"

# Check if the file was removed successfully
if [ ! -f "$FIRMWARE_FILE" ]; then
    echo "✅ Firmware file removed successfully!"
else
    echo "❌ Failed to remove the firmware file!"
    exit 1
fi