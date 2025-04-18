#!/usr/bin/env bash

# Script to read user information and perform find and replace operations across a project

set -euo pipefail

SCRIPT_PATH="$(readlink -f "$0")"

# Read user inputs
read -rp "Enter FULLNAME: " FULLNAME
read -rp "Enter EMAIL: " EMAIL
read -rp "Enter GITHUB_USERNAME: " GITHUB_USERNAME
read -rp "Enter HOSTNAME to set for dev machine: " HOSTNAME

FIRST_NAME=$USERNAME

printf "Thanks! Going to replace variables with these values across the project files:\n"
printf "FIRST_NAME -> %s\n" "$FIRST_NAME"
printf "FULLNAME -> %s\n" "$FULLNAME"
printf "EMAIL -> %s\n" "$EMAIL"
printf "GITHUB_USERNAME -> %s\n" "$GITHUB_USERNAME"
printf "HOSTNAME -> %s\n" "$HOSTNAME"

# Confirm before proceeding
read -rp "Do you want to continue with the replacement? (y/n): " confirmation
if [[ $confirmation != "y" && $confirmation != "Y" ]]; then
  printf "Operation cancelled.\n"
  exit 0
fi

# Define project directory (default is current directory)
PROJECT_DIR="."
read -rp "Enter project directory path (default is current directory): " input_dir
if [ -n "$input_dir" ]; then
  PROJECT_DIR="$input_dir"
fi

# Check if directory exists
if [ ! -d "$PROJECT_DIR" ]; then
  printf "Error: Directory %s does not exist.\n" "$PROJECT_DIR"
  exit 1
fi

printf "Performing replacements in %s and all its subdirectories...\n" "$PROJECT_DIR"

# Function to perform find and replace
perform_replace() {
  local search="$1"
  local replace="$2"
  local count=0

  # Use process substitution to avoid problematic piping with set -e
  # Find ALL files in the project directory AND its subdirectories recursively
  while IFS= read -r file; do

    # Skip the script itself to prevent self-modification
    if [ "$(readlink -f "$file")" = "$SCRIPT_PATH" ]; then
      printf "Skipping script file: %s\n" "$file"
      continue
    fi

    if [ -n "$file" ] && [ -f "$file" ]; then
      # Check if file contains the search string
      if grep -q -- "$search" "$file" 2>/dev/null; then
        # Safely handle each file with proper quoting
        sed -i.bak "s|${search}|${replace}|g" "$file"
        # Remove backup files
        rm "${file}.bak"
        printf "Updated: %s\n" "$file"
        count=$((count + 1))
      fi
    fi
  done < <(find "$PROJECT_DIR" -type f -not -path "*/\.git/*" -not -path "*/\packages/*" 2>/dev/null || true)

  printf "Completed replacement of %s with %s in %d files\n" "$search" "$replace" "$count"
}

printf "Starting replacements (recursively searching all subdirectories)...\n"

# Perform the replacements
perform_replace "FIRST_NAME" "$FIRST_NAME"
perform_replace "FULLNAME" "$FULLNAME"
perform_replace "EMAIL" "$EMAIL"
perform_replace "GITHUB_USERNAME" "$GITHUB_USERNAME"
perform_replace "HOSTNAME" "$HOSTNAME"

printf "Adding all the modified files to git...\n"
git add -A

printf "Renaming hosts/HOSTNAME to hosts/%s...\n" "$HOSTNAME"
git mv hosts/HOSTNAME hosts/"$HOSTNAME"

printf "All replacements completed!\n"

printf "Installing hardware-configuration.nix...\n"
sudo install -m 644 -o "$FIRST_NAME" /etc/nixos/hardware-configuration.nix hosts/"$HOSTNAME"/hardware-configuration.nix

printf "Tracking all the added files\n"
git add -A

printf "\n\nSUCCESS: Please check the changes and commit them.\n"
