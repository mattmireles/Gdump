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
    echo "🔧 Let's configure gdump to work with your Google Cloud Project(s)"
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
    echo "✅ Configuration complete! You can now run 'gdump' to clean up files from all projects"
    echo "To reconfigure at any time, run: gdump --configure"
    exit 0
fi

# Check if config file exists and has entries
if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
    echo "No projects configured. Please run: gdump --configure"
    exit 1
fi

echo "🧹 Starting Gemini API file cleanup..."

# Get the list of files and delete them for a single project
cleanup_project() {
    local project_name=$1
    local api_key=$2
    
    echo ""
    echo "📁 Processing project: $project_name"
    
    local response=$(curl -s "https://generativelanguage.googleapis.com/v1beta/files?key=$api_key")
    
    # Check for API errors
    if echo "$response" | grep -q "error"; then
        echo "❌ Error: Invalid API key or API request failed for project $project_name"
        return 1
    }
    
    # Extract and delete files
    local files_deleted=0
    echo "$response" | grep -o '"name": *"[^"]*"' | cut -d'"' -f4 | while read -r file; do
        if [ ! -z "$file" ]; then
            echo "🗑️  Deleting $file..."
            curl -X DELETE "https://generativelanguage.googleapis.com/v1beta/$file?key=$api_key"
            ((files_deleted++))
        fi
    done
    
    # Handle pagination
    local next_page_token=$(echo "$response" | grep -o '"nextPageToken": *"[^"]*"' | cut -d'"' -f4)
    
    while [ ! -z "$next_page_token" ]; do
        response=$(curl -s "https://generativelanguage.googleapis.com/v1beta/files?key=$api_key&pageToken=$next_page_token")
        
        echo "$response" | grep -o '"name": *"[^"]*"' | cut -d'"' -f4 | while read -r file; do
            if [ ! -z "$file" ]; then
                echo "🗑️  Deleting $file..."
                curl -X DELETE "https://generativelanguage.googleapis.com/v1beta/$file?key=$api_key"
                ((files_deleted++))
            fi
        done
        
        next_page_token=$(echo "$response" | grep -o '"nextPageToken": *"[^"]*"' | cut -d'"' -f4)
    done
    
    echo "✨ Cleaned up $files_deleted files from $project_name"
}

# Process all configured projects
while IFS=: read -r project_name api_key; do
    # Skip comments and empty lines
    [[ $project_name =~ ^#.*$ ]] && continue
    [[ -z $project_name ]] && continue
    
    cleanup_project "$project_name" "$api_key"
done < "$CONFIG_FILE"

echo ""
echo "🎉 All projects processed!" 