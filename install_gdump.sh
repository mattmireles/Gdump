#!/bin/bash

set -e  # Exit on error

# Define paths
SCRIPT_NAME="gdump.sh"
DESTINATION="/usr/local/bin/gdump"
GITHUB_RAW_URL="https://raw.githubusercontent.com/mattmireles/gdump/main/$SCRIPT_NAME"

echo "Installing gdump..."

# Check if /usr/local/bin exists and is writable
if [ ! -d "/usr/local/bin" ]; then
    echo "Creating /usr/local/bin directory..."
    sudo mkdir -p /usr/local/bin
    # Ensure proper ownership on macOS
    sudo chown $(whoami):admin /usr/local/bin
fi

# Ensure /usr/local/bin is in PATH
if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
    echo "Adding /usr/local/bin to PATH..."
    echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
    source ~/.zshrc
fi

# Download the gdump script
echo "Downloading gdump..."
if ! curl -fsSL "$GITHUB_RAW_URL" -o "/tmp/$SCRIPT_NAME"; then
    # Fallback to local copy if download fails
    if [ -f "$SCRIPT_NAME" ]; then
        cp "$SCRIPT_NAME" "/tmp/$SCRIPT_NAME"
    else
        echo "Error: Failed to get gdump script"
        exit 1
    fi
fi

# Make the script executable
chmod +x "/tmp/$SCRIPT_NAME"

# Move the script to /usr/local/bin with proper permissions
echo "Installing gdump to $DESTINATION..."
if sudo mv "/tmp/$SCRIPT_NAME" "$DESTINATION" && \
   sudo chown $(whoami):admin "$DESTINATION" && \
   sudo chmod 755 "$DESTINATION"; then
    echo "✅ gdump has been installed successfully!"
    echo ""
    echo "Let's configure your projects now!"
    # Use full path to ensure it's found
    /usr/local/bin/gdump --configure
else
    echo "Error: Failed to install gdump"
    rm -f "/tmp/$SCRIPT_NAME"
    exit 1
fi