# tmux-session-manager

A plugin-based tmux session manager with fast performance and modular architecture.

## Structure

```
tmux-session-manager/
├── tmux-session-manager  # Main script
├── tests                 # Test suite  
├── core/                 # Core plugin directory
│   ├── active.sh         # Active tmux sessions (core functionality)
│   └── recent.sh         # Most recent session (priority 1)
├── plugins/              # Regular plugin directory
│   ├── scratch.sh        # Scratch/temporary sessions  
│   ├── tmuxinator.sh     # Tmuxinator configurations
│   └── worktree.sh       # Git worktree sessions
└── README.md             # This file
```

## Usage

```bash
# Run the session manager
./scripts/tmux-session-manager/tmux-session-manager

# Run tests
./scripts/tmux-session-manager/tests

# Check plugin health
./scripts/tmux-session-manager/tmux-session-manager --doctor

# Show session info and troubleshooting
./scripts/tmux-session-manager/tmux-session-manager --info
```

## Plugin Priority

Plugins load and display sessions in priority order (lower number = higher priority):

1. **recent** (1) - Most recently active session (core)
2. **worktree** (5) - Git worktree sessions
3. **active** (10) - Currently active tmux sessions (core)
4. **tmuxinator** (50) - Tmuxinator configuration files
5. **scratch** (999) - Scratch/temporary sessions

## Core vs Regular Plugins

**Core Plugins** (`core/` directory):
- Essential functionality that behaves like plugins but is always loaded
- `active.sh` - Manages active tmux sessions with standard priority (10)
- `recent.sh` - Handles most recent session with highest priority (1)

**Regular Plugins** (`plugins/` directory):
- Optional functionality that can be added/removed
- Loaded after core plugins but follow same priority system
- Can override core plugins with priorities 0-4 if needed
