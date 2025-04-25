#!/bin/bash

# This script launches meld to compare corresponding files between two directories

# Check if meld is installed
if ! command -v meld &> /dev/null; then
    echo "Meld is not installed. Please install it with:"
    echo "  sudo apt install meld    # for Debian/Ubuntu"
    echo "  sudo pacman -S meld      # for Arch Linux"
    echo "  brew install meld        # for macOS with Homebrew"
    exit 1
fi

# Check if two directory arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <directory1> <directory2>"
    echo "Example: $0 bar-charts scatter-charts"
    exit 1
fi

# Get the directories from command line arguments
DIR1="$1"
DIR2="$2"

# Check if both directories exist
if [ ! -d "$DIR1" ]; then
    echo "Error: Directory '$DIR1' does not exist"
    exit 1
fi

if [ ! -d "$DIR2" ]; then
    echo "Error: Directory '$DIR2' does not exist"
    exit 1
fi

# Function to launch meld for a comparison
launch_meld() {
    local file1="$1"
    local file2="$2"
    local filename=$(basename "$file1")
    
    # Check if both files exist
    if [[ -f "$file1" && -f "$file2" ]]; then
        echo "Launching meld comparison for $filename"
        meld "$file1" "$file2" &
        sleep 1  # Small delay to prevent overwhelming the system
    else
        echo "Error: One or both files don't exist for $filename"
        [[ ! -f "$file1" ]] && echo "Missing: $file1"
        [[ ! -f "$file2" ]] && echo "Missing: $file2"
    fi
}

# Get list of files in first directory
echo "Launching meld comparisons..."
for file1 in "$DIR1"/*; do
    if [ -f "$file1" ]; then
        filename=$(basename "$file1")
        file2="$DIR2/$filename"
        
        # If corresponding file exists in the second directory, compare them
        if [ -f "$file2" ]; then
            launch_meld "$file1" "$file2"
        else
            echo "Warning: No corresponding file '$filename' found in '$DIR2'"
        fi
    fi
done

echo "All comparisons launched. Close meld windows when finished." 