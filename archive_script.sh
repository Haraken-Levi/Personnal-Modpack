#!/bin/bash

# Set the paths
CURRENT_DIR=$(dirname "$0")
SECONDARY_DIR="D:/Games/steamapps/workshop/content/784080"
ONEDRIVE_DIR="E:/OneDrive/partage/MechWarriors 5"

echo "Starting script at $(date)"

# Check if the directories exist
for DIR in $CURRENT_DIR $SECONDARY_DIR $ONEDRIVE_DIR; do
  if [[ ! -d $DIR ]]; then
    echo "Directory $DIR does not exist. Please check the paths."
    exit 1
  else
    echo "Directory $DIR exists"
  fi
done

# Check write permissions in OneDrive directory
if [[ ! -w $ONEDRIVE_DIR ]]; then
  echo "No permission to write files in $ONEDRIVE_DIR"
  exit 1
fi

# Exclude these files and directories
EXCLUDES=('.git' '.gitignore' '.gitattributes' 'archive_script.sh')

# Archive command with multi-threading
ARCHIVE_CMD='7z a -tzip -mx=1 -mmt=16'

# Archive all files, folders, and subfolders excluding specified files and directories
for EXCLUDE in ${EXCLUDES[@]}; do
  ARCHIVE_CMD+=" -xr!'$EXCLUDE'"
done

# Get the highest semver present and increment the patch number
# This segment finds the existing version, extracts the patch version, and increments it to form a new version
VERSION=$(ls "$ONEDRIVE_DIR/MW5 mods - v"*.zip | sed -r 's/.*v([0-9]+)_([0-9]+)_([0-9]+).*/\1.\2.\3/' | sort -V | tail -n1)
PATCH_VERSION=$(echo $VERSION | cut -d. -f3)
NEW_PATCH_VERSION=$((PATCH_VERSION+1))
NEW_VERSION=$(echo $VERSION | sed "s/[0-9]\+$/$NEW_PATCH_VERSION/")

echo "Starting archive creation at $(date)"
# Archive files in the current directory and the secondary directory
if eval "$ARCHIVE_CMD \"$ONEDRIVE_DIR/MW5 mods - v${NEW_VERSION//./_}.zip\" \"$CURRENT_DIR\"/* \"$SECONDARY_DIR\"/*"; then
  echo "Archive creation successful"
else
  echo "Archive creation failed"
  exit 1
fi
echo "Finished archive creation at $(date)"

# Test the archive
if 7z t "$ONEDRIVE_DIR/MW5 mods - v${NEW_VERSION//./_}.zip"; then
  echo "Archive test passed"
  # List the contents of the archive
  7z l "$ONEDRIVE_DIR/MW5 mods - v${NEW_VERSION//./_}.zip"

  # Ask the user whether to delete older archives
  # This segment lists and deletes the older archives, keeping the three newest ones
  read -p "Do you want to delete older archives? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting deletion of older archives at $(date)"
    OLD_ARCHIVES=$(ls -tp "$ONEDRIVE_DIR/MW5 mods - v"*.zip | grep -v '/$' | tail -n +4)
    echo "Deleting the following archives: $OLD_ARCHIVES"
    echo $OLD_ARCHIVES | xargs -I {} rm -- {}
    echo "Finished deletion of older archives at $(date)"
  fi
else
  echo "Archive test failed. Skipping deletion of older archives."
fi

echo "Finished script at $(date)"

# Wait for user input before closing
read -n 1 -s -r -p "Press any key to continue"
