#!/bin/bash

# Initial Omarchy setup migration
# This migration sets up the initial Omarchy configuration

echo "  → Setting up initial Omarchy configuration..."

# Ensure all necessary directories exist
mkdir -p ~/.local/state/omarchy/migrations
mkdir -p ~/.dotfiles/hypr/omarchy-backups

# Copy existing scripts to Omarchy bin if they don't exist
if [ ! -L ~/.dotfiles/hypr/scripts ]; then
    cp -n ~/.dotfiles/hypr/scripts/* ~/.dotfiles/hypr/omarchy/bin/ 2>/dev/null || true
fi

echo "  → Initial setup complete"