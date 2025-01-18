#!/bin/bash

set -e  # Exit on error

# Define paths
SCRIPT_NAME="gdump.sh"
DESTINATION="/usr/local/bin/gdump"
GITHUB_RAW_URL="https://raw.githubusercontent.com/mattmireles/gdump/main/$SCRIPT_NAME"

echo "
📦 Installing gdump...
"

# Check if /usr/local/bin exists and is writable
if [ ! -d "/usr/local/bin" ]; then
    echo "Creating /usr/local/bin directory..."
    sudo mkdir -p /usr/local/bin
    sudo chown $(whoami):admin /usr/local/bin
fi

# Download the script
echo "Downloading gdump..."
if ! curl -fsSL "$GITHUB_RAW_URL" -o "/tmp/$SCRIPT_NAME"; then
    echo "❌ Download failed. Please check your internet connection and try again."
    exit 1
fi

# Make the script executable and move it to destination
chmod +x "/tmp/$SCRIPT_NAME"
if ! sudo mv "/tmp/$SCRIPT_NAME" "$DESTINATION"; then
    echo "❌ Failed to install gdump. Do you have sudo access?"
    exit 1
fi

sudo chown $(whoami):admin "$DESTINATION"
sudo chmod 755 "$DESTINATION"

echo "
✅ gdump installed successfully! Time to fix your Gemini problems.

🚀 What's next:

    1. Open a new terminal window
    2. Type:  gdump --configure
    3. Have your API keys ready (yeah, you need those 🙄)

💡 Need API keys? Check out: https://github.com/mattmireles/gdump#setup
   (Don't worry, we explain where to find them)
"