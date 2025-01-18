#!/bin/bash

set -e  # Exit on error

# Default config location
CONFIG_DIR="$HOME/.gdump"
CONFIG_FILE="$CONFIG_DIR/projects.conf"

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

# Handle configuration
if [ "$1" == "--configure" ]; then
    # Create or clear config file
    echo "🔧 Time to tell gdump about your Google Cloud Project(s) and API key(s)."
    echo "# Format: project_name:api_key" > "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    
    while true; do
        echo ""
        read -p "Enter Google Cloud Project name: " project_name
        read -p "Enter API key for $project_name: " api_key
        
        echo "${project_name}:${api_key}" >> "$CONFIG_FILE"
        
        echo ""
        read -p "Do you have another project to add? (y/n): " more_projects
        case $more_projects in
            [Nn]* ) break;;
            * ) continue;;
        esac
    done
    
    echo ""
    echo "✅ Done. Now you can run 'gdump' whenever Gemini API craps out due to file storage limits."
    echo "To reconfigure at any time, run: gdump --configure"
    exit 0
fi

# Check if config file exists and has entries
if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
    echo "No projects configured. Please run: gdump --configure"
    exit 1
fi

echo "🧹 Finding all those files Gemini API didn't tell you about..."

# Get the list of files and delete them for a single project
cleanup_project() {
    local project_name=$1
    local api_key=$2
    
    echo ""
    echo "📁 Checking what Gemini's been storing in $project_name..."
    
    local response=$(curl -s "https://generativelanguage.googleapis.com/v1beta/files?key=$api_key")
    
    # Check for API errors
    if echo "$response" | grep -q "error"; then
        echo "❌ Hmm. Either that API key is wrong or Gemini is having a moment. Check $project_name and try again."
        return 1
    }
    
    # Extract and delete files
    local files_deleted=0
    echo "$response" | grep -o '"name": *"[^"]*"' | cut -d'"' -f4 | while read -r file; do
        if [ ! -z "$file" ]; then
            ((files_deleted++))
            echo "☁️💩 Dumping $file... ($files_deleted dumped)"
            curl -X DELETE "https://generativelanguage.googleapis.com/v1beta/$file?key=$api_key"
        fi
    done
    
    # Handle pagination
    local next_page_token=$(echo "$response" | grep -o '"nextPageToken": *"[^"]*"' | cut -d'"' -f4)
    
    while [ ! -z "$next_page_token" ]; do
        response=$(curl -s "https://generativelanguage.googleapis.com/v1beta/files?key=$api_key&pageToken=$next_page_token")
        
        echo "$response" | grep -o '"name": *"[^"]*"' | cut -d'"' -f4 | while read -r file; do
            if [ ! -z "$file" ]; then
                ((files_deleted++))
                echo "☁️💩 Dumping $file... ($files_deleted dumped)"
                curl -X DELETE "https://generativelanguage.googleapis.com/v1beta/$file?key=$api_key"
            fi
        done
        
        next_page_token=$(echo "$response" | grep -o '"nextPageToken": *"[^"]*"' | cut -d'"' -f4)
    done
    
    echo "✨💨 Successfully deleted $files_deleted files you never knew you had in $project_name"
}

# Process all configured projects
while IFS=: read -r project_name api_key; do
    # Skip comments and empty lines
    [[ $project_name =~ ^#.*$ ]] && continue
    [[ -z $project_name ]] && continue
    
    cleanup_project "$project_name" "$api_key"
done < "$CONFIG_FILE"

echo ""
echo "💩🎉 Dump complete. Gemini API's 20GB limit is now someone else's problem." 
