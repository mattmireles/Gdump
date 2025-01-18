#!/bin/bash

# Enable debug mode to see what's happening
set -x
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

# Download the gdump script with better error handling
echo "Downloading gdump..."
if ! curl -v -fsSL "$GITHUB_RAW_URL" -o "/tmp/$SCRIPT_NAME"; then
    echo "Download from GitHub failed. Checking for local copy..."
    # Fallback to local copy if download fails
    if [ -f "$SCRIPT_NAME" ]; then
        echo "Found local copy, using that instead..."
        cp "$SCRIPT_NAME" "/tmp/$SCRIPT_NAME"
    else
        echo "Error: Failed to get gdump script. Neither download nor local copy available."
        exit 1
    fi
fi

# Verify the downloaded file exists and has content
if [ ! -s "/tmp/$SCRIPT_NAME" ]; then
    echo "Error: Downloaded script is empty or missing"
    exit 1
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
    
    # Test if gdump is executable and in PATH
    if ! which gdump > /dev/null; then
        echo "Error: gdump not found in PATH after installation"
        echo "Current PATH: $PATH"
        exit 1
    fi
    
    # Execute configuration with full path and debug output
    echo "Starting configuration..."
    "$DESTINATION" --configure || {
        echo "Error: Configuration failed"
        echo "gdump executable contents:"
        cat "$DESTINATION"
        exit 1
    }
else
    echo "Error: Failed to install gdump"
    rm -f "/tmp/$SCRIPT_NAME"
    exit 1
fi