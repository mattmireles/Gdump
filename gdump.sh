#!/bin/bash

set -e  # Exit on error

# Default config location
CONFIG_DIR="$HOME/.gdump"
CONFIG_FILE="$CONFIG_DIR/projects.conf"

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

# Function definitions here...
show_help() {
    echo "
🚽 Gdump: Because someone has to clean up after Gemini API

Usage: gdump [command]

Commands:
    (no command)  Run a dump now
    --project <name>  Dump a specific project
    --edit        Add, remove, or edit your GCP projects
    --schedule    Set up automatic dumps (hourly/daily/weekly)
    --show-schedule  Check when dumps are scheduled
    --remove-schedule  Stop automatic dumps
    --version     Show version information
    --help        Show this help message

Example:
    gdump              # Dump all projects
    gdump --project \"My Project\"  # Dump just one project
    gdump --edit       # Fix that project name you typoed

Need more help? Visit: https://github.com/mattmireles/gdump#readme
"
}

show_projects() {
    if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
        echo "😶 No projects configured yet. Nothing to show!"
        return
    fi
    
    echo "🗂️  Your configured projects:"
    echo ""
    local count=1
    while IFS=: read -r project_name api_key; do
        [[ $project_name =~ ^#.*$ ]] && continue
        [[ -z $project_name ]] && continue
        echo "  $count. $project_name"
        echo "     API Key: ${api_key:0:8}...${api_key: -4}"
        ((count++))
    done < "$CONFIG_FILE"
}

setup_cron() {
    echo "🕒 Let's schedule regular dumps to keep Gemini API from getting constipated"
    echo ""
    echo "How often should gdump run?"
    echo "  1. Hourly (for the paranoid)"
    echo "  2. Daily"
    echo "  3. Weekly"
    echo "  4. Monthly"
    echo "  5. Custom schedule"
    echo "  6. Nevermind, I'll run it manually"
    echo ""
    read -p "Enter your choice (1-6): " choice

    case $choice in
        1)  # Hourly
            schedule="0 * * * *"  # Every hour on the hour
            description="every hour"
            ;;
        2)  # Daily
            schedule="0 0 * * *"  # Midnight every day
            description="daily at midnight"
            ;;
        3)  # Weekly
            schedule="0 0 * * 0"  # Midnight every Sunday
            description="weekly on Sunday at midnight"
            ;;
        4)  # Monthly
            schedule="0 0 1 * *"  # Midnight on the 1st of each month
            description="monthly on the 1st at midnight"
            ;;
        5)  # Custom
            echo "Enter your cron schedule (e.g., '0 0 * * *' for daily at midnight):"
            read -p "Schedule: " schedule
            description="on your custom schedule"
            ;;
        6)  # Exit
            echo "👋 No problem! Just run gdump manually when needed"
            return
            ;;
        *)  
            echo "🤨 That wasn't one of the options. Try again with --schedule"
            return
            ;;
    esac

    # Create or update cron job
    (crontab -l 2>/dev/null | grep -v "gdump") | crontab -
    (crontab -l 2>/dev/null; echo "$schedule /usr/local/bin/gdump > $HOME/.gdump/gdump.log 2>&1") | crontab -

    echo ""
    echo "✅ Gdump will now run $description"
    echo "💡 Logs will be saved to: $HOME/.gdump/gdump.log"
}

remove_cron() {
    if crontab -l 2>/dev/null | grep -q "gdump"; then
        (crontab -l 2>/dev/null | grep -v "gdump") | crontab -
        echo "✅ Automatic dumps removed. You'll need to run gdump manually now."
    else
        echo "😶 No scheduled dumps found."
    fi
}

show_cron() {
    if crontab -l 2>/dev/null | grep -q "gdump"; then
        echo "🕒 Current gdump schedule:"
        crontab -l | grep "gdump"
        echo ""
        echo "💡 To change this, run: gdump --schedule"
        echo "   To remove it, run: gdump --remove-schedule"
    else
        echo "😶 No scheduled dumps found."
        echo "💡 To set one up, run: gdump --schedule"
    fi
}

cleanup_project() {
    local project_name=$1
    local api_key=$2
    local files_deleted=0
    local tmp_file=$(mktemp)
    
    echo ""
    echo "📁 Checking what the Gemini API's been storing in $project_name..."
    
    local response=$(curl -s "https://generativelanguage.googleapis.com/v1beta/files?key=$api_key")
    
    # Check for API errors
    if echo "$response" | grep -q "error"; then
        echo "❌ Hmm. Either that API key is wrong or Gemini is having a moment. Check $project_name and try again."
        rm -f "$tmp_file"
        return 1
    fi
    
    # Function to process and delete files
    process_files() {
        local resp=$1
        # Extract file names to temp file
        echo "$resp" | grep -o '"name": *"[^"]*"' | cut -d'"' -f4 > "$tmp_file"
        
        # Process each file
        while read -r file; do
            if [ ! -z "$file" ]; then
                ((files_deleted++))
                echo "☁️💩 Dumping $file... ($files_deleted files dumped)"
                curl -s -X DELETE "https://generativelanguage.googleapis.com/v1beta/$file?key=$api_key" > /dev/null
            fi
        done < "$tmp_file"
    }
    
    # Process initial batch
    process_files "$response"
    
    # Handle pagination
    local next_page_token=$(echo "$response" | grep -o '"nextPageToken": *"[^"]*"' | cut -d'"' -f4)
    
    while [ ! -z "$next_page_token" ]; do
        response=$(curl -s "https://generativelanguage.googleapis.com/v1beta/files?key=$api_key&pageToken=$next_page_token")
        process_files "$response"
        next_page_token=$(echo "$response" | grep -o '"nextPageToken": *"[^"]*"' | cut -d'"' -f4)
    done
    
    rm -f "$tmp_file"
    echo "✨💨 Successfully deleted $files_deleted files you never knew you had in $project_name"
}

get_version() {
    # Try to get version from git tag
    if command -v git >/dev/null 2>&1 && [ -d "$(dirname "$0")/.git" ]; then
        git describe --tags 2>/dev/null || echo "dev"
    else
        # Fallback if not in git repo or git not available
        echo "unknown"
    fi
}

# Handle all command arguments first
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    show_help
    exit 0
fi

if [ "$1" == "--edit" ]; then
    echo "🔧 Time to fix those fat-finger moments..."
    show_projects
    
    # Backup the config file
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
    
    echo ""
    echo "How can Gdump make your life better?"
    echo "  1. Add a new GCP project"
    echo "  2. Remove a GCP project"
    echo "  3. Edit a GCP project"
    echo "  4. Start over with a clean slate"
    echo "  5. Nevermind, get me out of here"
    echo ""
    read -p "Enter your choice (1-5): " choice
    
    case $choice in
        1)  # Add new project
            echo ""
            read -p "Enter Google Cloud Project name: " project_name
            read -p "Enter API key for $project_name: " api_key
            echo "${project_name}:${api_key}" >> "$CONFIG_FILE"
            echo "✅ Added $project_name to the party!"
            ;;
            
        2)  # Remove project
            echo ""
            read -p "Enter the number of the project to remove: " number
            sed -i.tmp "${number}d" "$CONFIG_FILE"
            rm "${CONFIG_FILE}.tmp"
            echo "🗑️  Poof! That project is gone."
            ;;
            
        3)  # Edit project
            echo ""
            read -p "Enter the number of the project to edit: " number
            read -p "New project name (or press Enter to keep existing): " new_name
            read -p "New API key (or press Enter to keep existing): " new_key
            
            # Get existing values
            line=$(sed "${number}!d" "$CONFIG_FILE")
            old_name=$(echo "$line" | cut -d: -f1)
            old_key=$(echo "$line" | cut -d: -f2)
            
            # Use new values or fall back to old ones
            final_name=${new_name:-$old_name}
            final_key=${new_key:-$old_key}
            
            sed -i.tmp "${number}c\\${final_name}:${final_key}" "$CONFIG_FILE"
            rm "${CONFIG_FILE}.tmp"
            echo "✨ Updated! Let's hope you typed it right this time..."
            ;;
            
        4)  # Start fresh
            echo "🧹 Clearing the slate..."
            echo "# Format: project_name:api_key" > "$CONFIG_FILE"
            chmod 600 "$CONFIG_FILE"
            
            while true; do
                echo ""
                read -p "Enter Google Cloud Project name: " project_name
                read -p "Enter API key for $project_name: " api_key
                
                echo "${project_name}:${api_key}" >> "$CONFIG_FILE"
                
                echo ""
                read -p "Got another project? (y/n): " more_projects
                case $more_projects in
                    [Nn]* ) break;;
                    * ) continue;;
                esac
            done
            ;;
            
        5)  # Exit without changes
            echo "👋 Alright, leaving everything as is!"
            mv "${CONFIG_FILE}.bak" "$CONFIG_FILE"
            exit 0
            ;;
            
        *)  echo "🤨 That wasn't one of the options. Try again with --edit"
            mv "${CONFIG_FILE}.bak" "$CONFIG_FILE"
            exit 1
            ;;
    esac
    
    echo ""
    echo "Here's your updated GCP project list:"
    show_projects
    echo ""
    echo "💡 Pro tip: Run 'gdump --edit' anytime you need to make changes"
    exit 0
fi

if [ "$1" == "--schedule" ]; then
    setup_cron
    exit 0
fi

if [ "$1" == "--remove-schedule" ]; then
    remove_cron
    exit 0
fi

if [ "$1" == "--show-schedule" ]; then
    show_cron
    exit 0
fi

if [ "$1" == "--version" ]; then
    echo "gdump $(get_version)"
    exit 0
fi

# Add to argument handling (before the main dump logic)
if [ "$1" == "--project" ]; then
    if [ -z "$2" ]; then
        echo "❌ Project name required. Usage: gdump --project \"My Project\""
        echo "💡 Not sure of your project names? Run: gdump --edit to see them"
        exit 1
    fi

    # Check if config file exists and has entries
    if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
        echo "😶 No projects configured yet. Run: gdump --edit"
        echo "   We'll help you set up your Google Cloud Project(s)"
        exit 1
    fi

    echo "🧹 Finding files in project: $2"
    
    # Find and process the specific project
    found=0
    while IFS=: read -r project_name api_key; do
        # Skip comments and empty lines
        [[ $project_name =~ ^#.*$ ]] && continue
        [[ -z $project_name ]] && continue
        
        if [ "$project_name" == "$2" ]; then
            cleanup_project "$project_name" "$api_key"
            found=1
            break
        fi
    done < "$CONFIG_FILE"

    if [ $found -eq 0 ]; then
        echo "❌ Project \"$2\" not found. Run 'gdump --edit' to see your projects"
        exit 1
    fi

    echo ""
    echo "💩🎉 Dump complete for $2. Ahh, that feels better."
    exit 0
fi

# Now handle the main dump functionality (no arguments)
# Check if config file exists and has entries
if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
    echo "😶 No projects configured yet. Run: gdump --edit"
    echo "   We'll help you set up your Google Cloud Project(s)"
    exit 1
fi

echo "🧹 Finding all those files Gemini API didn't tell you about..."

# Process all configured projects
while IFS=: read -r project_name api_key; do
    # Skip comments and empty lines
    [[ $project_name =~ ^#.*$ ]] && continue
    [[ -z $project_name ]] && continue
    
    cleanup_project "$project_name" "$api_key"
done < "$CONFIG_FILE"

echo ""
echo "💩🎉 Dump complete. Gemini API's 20GB limit is now someone else's problem. Ahh, that feels better." 
