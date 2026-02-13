#!/bin/bash
set -e

# Update Function
update_vscode() {
    local TYPE=$1
    local URL=$2
    local PATTERN=$3
    local EXCLUDE_PATTERN=$4

    echo "Checking for $TYPE updates..."

    # Create a temporary directory
    local TEMP_DIR=$(mktemp -d)

    # Download the file to temp directory to inspect the filename
    # We use -L to follow redirects and -J to respect the remote filename
    pushd "$TEMP_DIR" > /dev/null
    curl -L -J -O "$URL"
    
    # Find the downloaded .exe file
    local DOWNLOADED_FILE=$(ls *.exe | head -n 1)
    popd > /dev/null

    if [ -z "$DOWNLOADED_FILE" ]; then
        echo "Error: Failed to download $TYPE or could not determine filename."
        rm -rf "$TEMP_DIR"
        return 1
    fi

    echo "Latest version appears to be: $DOWNLOADED_FILE"

    # Check if this exact file already exists in the repo root
    if [ -f "$DOWNLOADED_FILE" ]; then
        echo "$TYPE is already up to date ($DOWNLOADED_FILE)."
        rm -rf "$TEMP_DIR"
    else
        echo "New $TYPE version found. Updating..."
        
        # Remove old versions matching the pattern but excluding the other type
        if [ -n "$EXCLUDE_PATTERN" ]; then
            find . -maxdepth 1 -name "$PATTERN" ! -name "$EXCLUDE_PATTERN" -delete
        else
            find . -maxdepth 1 -name "$PATTERN" -delete
        fi

        # Move new file into place
        mv "$TEMP_DIR/$DOWNLOADED_FILE" .
        rm -rf "$TEMP_DIR"
        
        echo "Successfully updated $TYPE to $DOWNLOADED_FILE"
    fi
}

# VS Code Stable
# Pattern matches both, so we exclude 'insider' for the stable check
update_vscode "VS Code Stable" \
    "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user" \
    "VSCodeUserSetup-x64-*.exe" \
    "*insider*"

# VS Code Insiders
# Pattern is specific enough to not need exclusion
update_vscode "VS Code Insiders" \
    "https://code.visualstudio.com/sha/download?build=insider&os=win32-x64-user" \
    "*insider.exe" \
    ""