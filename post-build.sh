#!/usr/bin/env bash

# Script to create users ssh keys

set -euo pipefail

# Set colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}SSH Key Generation Script${NC}"
echo "This script will generate two ed25519 SSH keys:"
echo "1. A builder key with no password"
echo "2. A GitHub key with password protection"
echo ""

# Create .ssh directory if it doesn't exist
SSH_DIR="${HOME}/.ssh"
if [ ! -d "${SSH_DIR}" ]; then
  echo "Creating .ssh directory..."
  mkdir -p "${SSH_DIR}"
  chmod 700 "${SSH_DIR}"
fi

# Generate builder key (no password)
echo -e "\n${YELLOW}Generating builder-key (no password)...${NC}"
ssh-keygen -t ed25519 -f "${SSH_DIR}/builder-key" -N "" -C "build-server-key"

# Generate GitHub key (with password)
echo -e "\n${YELLOW}Generating GitHub key (with password)...${NC}"
echo "Please enter a strong password when prompted:"
ssh-keygen -t ed25519 -f "${SSH_DIR}/github-key" -C "github-key"

# Set permissions
chmod 600 "${SSH_DIR}/builder-key"
chmod 600 "${SSH_DIR}/github-key"
chmod 644 "${SSH_DIR}/builder-key.pub"
chmod 644 "${SSH_DIR}/github-key.pub"

# Display the public keys
echo -e "\n${GREEN}Keys generated successfully!${NC}"
echo -e "\n${YELLOW}Builder Public Key (upload to build server):${NC}"
cat "${SSH_DIR}/builder-key.pub"

echo -e "\n${YELLOW}GitHub Public Key (upload to GitHub):${NC}"
cat "${SSH_DIR}/github-key.pub"
cat "${SSH_DIR}/github-key.pub" >>users/ssh-keys.txt

echo -e "\n${BLUE}Instructions:${NC}"
echo "1. Upload the builder-key.pub to your build server's authorized_keys file"
echo "1.a use https://github.com/tiiuae/ghaf-infra/pull/406 as an example how to do this"
echo "1.b use https://github.com/tiiuae/ghaf-fmo-laptop/pull/57 as an example how to do this"
echo "2. Add the github-key.pub to your GitHub account at https://github.com/settings/keys"

echo -e "\n${YELLOW}Deleting the old config${NC}"
mkdir -p "${HOME}/.old"
sudo mv -f /etc/nixos/configuration.nix "${HOME}/.old/configuration.nix"
sudo mv -f /etc/nixos/hardware-configuration.nix "${HOME}/.old/hardware-configuration.nix"
