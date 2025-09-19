# Omarchy-Compatible Hyprland Configuration

This is an Omarchy-compatible configuration system for Hyprland that preserves your custom
settings while providing the benefits of Omarchy's update system and organization.

## Structure

```
omarchy/
├── config/           # Your custom configurations (user-editable)
│   ├── monitors.conf
│   ├── input.conf
│   ├── bindings.conf
│   ├── envs.conf
│   ├── looknfeel.conf
│   ├── autostart.conf
│   └── windows.conf
├── default/          # Omarchy defaults (don't edit)
│   └── hypr/
│       ├── envs.conf
│       ├── autostart.conf
│       ├── looknfeel.conf
│       ├── input.conf
│       ├── windows.conf
│       └── bindings/
│           ├── media.conf
│           ├── tiling.conf
│           ├── utilities.conf
│           └── workspaces.conf
├── themes/           # Theme configurations
│   ├── current/      # Symlink to active theme
│   ├── tokyo-night/
│   ├── catppuccin/
│   ├── nord/
│   └── dracula/
├── bin/              # Omarchy utility scripts
│   ├── omarchy-activate
│   ├── omarchy-update
│   ├── omarchy-migrate
│   └── omarchy-theme-set
└── migrations/       # Configuration migration scripts
```

## Activation

To activate the Omarchy configuration system:

```bash
~/.dotfiles/hypr/omarchy/bin/omarchy-activate
```

This will:
1. Backup your current configuration
2. Set up the Omarchy configuration system
3. Preserve all your custom settings
4. Make Omarchy commands available

## Usage

### Customizing Your Configuration

Edit files in `~/.dotfiles/hypr/omarchy/config/` to customize your setup:

- **monitors.conf** - Display configuration
- **bindings.conf** - Custom keybindings
- **envs.conf** - Environment variables
- **autostart.conf** - Startup applications
- **windows.conf** - Window rules
- **looknfeel.conf** - Visual settings
- **input.conf** - Input device settings

Your changes override the defaults and are preserved during updates.

### Switching Themes

```bash
# List available themes
omarchy-theme-set

# Switch to a theme
omarchy-theme-set tokyo-night
```

### Updating

```bash
# Update Omarchy configuration
omarchy-update
```

This preserves your custom configurations while updating the base system.

### Creating New Themes

1. Create a new directory in `themes/`
2. Add a `hyprland.conf` file with theme-specific settings
3. Optionally add configs for other applications (kitty.conf, waybar.css, etc.)

## Configuration Hierarchy

1. **Defaults** (managed by Omarchy)
2. **Theme** (current theme settings)
3. **User Overrides** (your custom configs)

Later configurations override earlier ones, ensuring your settings take precedence.

## Reverting

If you want to revert to your original configuration:

1. Check the backup location shown during activation
2. Copy the backup over your current config:
   ```bash
   cp ~/.dotfiles/hypr/omarchy-backups/hyprland.conf.<timestamp> ~/.config/hypr/hyprland.conf
   ```
3. Reload Hyprland

## Benefits

- **Organized Configuration** - Clear separation between defaults, themes, and custom settings
- **Update System** - Safely update base configuration without losing customizations
- **Theme Management** - Easy theme switching and customization
- **Migration System** - Automatic configuration updates when needed
- **Backup System** - Automatic backups before changes

## Compatibility

This setup is compatible with your existing:
- Custom scripts (wallpaper-picker, screenrecord, etc.)
- Monitor detection system
- Application preferences (zen-browser, kitty, albert)
- Custom keybindings
- NVIDIA-specific settings
