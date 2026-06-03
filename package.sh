#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Extract version from plugin.cfg
if [ ! -f "plugin.cfg" ]; then
    echo "Error: plugin.cfg not found in current directory"
    exit 1
fi

VERSION=$(grep -E '^version="[0-9]+\.[0-9]+\.[0-9]+"' plugin.cfg | sed -E 's/version="([0-9]+\.[0-9]+\.[0-9]+)"/\1/')

if [ -z "$VERSION" ]; then
    echo "Error: Could not find version=\"x.x.x\" in plugin.cfg"
    exit 1
fi

echo "Found version: $VERSION"

# Define the output zip file name
OUTPUT_ZIP="spark-godot-${VERSION}.zip"

# Remove any existing zip files
rm -f spark-*.zip

# Get the script name (without path)
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Create a temporary directory for the addons/spark structure
TEMP_DIR=$(mktemp -d)
mkdir -p "$TEMP_DIR/addons/spark"

# Copy all contents except the script itself and zip archives
echo "Copying files to temporary directory..."
find . -maxdepth 1 -type f ! -name "$SCRIPT_NAME" ! -name "*.zip" -exec cp {} "$TEMP_DIR/addons/spark/" \;
find . -maxdepth 1 -type d ! -name "." ! -name ".." ! -name ".git" -exec cp -r {} "$TEMP_DIR/addons/spark/" \;

# Remove any zip files that might have been copied in subdirectories
find "$TEMP_DIR/addons/spark" -name "*.zip" -type f -delete

# Create the zip file with the required structure
echo "Creating $OUTPUT_ZIP..."
cd "$TEMP_DIR"
zip -r "$SCRIPT_DIR/$OUTPUT_ZIP" addons/

# Clean up temporary directory
cd "$SCRIPT_DIR"
rm -rf "$TEMP_DIR"

echo "Done! Created $OUTPUT_ZIP with structure: addons/spark/(contents)"
