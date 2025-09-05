# Tmux Session Manager - Rust Rewrite

High-performance tmux session manager with a hybrid plugin system combining built-in plugins (for speed) with dynamic plugin loading (for extensibility).

## Features

- **Lightning Fast**: Single binary, minimal tmux calls, concurrent operations  
- **Plugin System**: Built-in plugins for core functionality + dynamic loading for extensibility  
- **Session Types**: Active sessions, Git worktrees, Tmuxinator configs, scratch sessions
- **FZF Integration**: Interactive selection with preview and keyboard shortcuts
- **Cross-Platform**: Works inside tmux (popup) or outside tmux (regular fzf)

## Performance Improvements

Compared to the bash version:

- **Single tmux call** instead of multiple subprocess calls per session
- **Concurrent plugin discovery** using Rust's async/await  
- **Structured data** instead of string parsing
- **Compiled efficiency** vs interpreted bash
- **Smart caching** of session metadata

Expected performance: **~5-10x faster** than bash implementation

## Quick Start

### 1. Install Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
```

### 2. Build

```bash
make
# OR
cargo build --release && cp target/release/tmux-session-manager bin/
```

### 3. Run

```bash
# Interactive session selector
./bin/tmux-session-manager

# Check system health  
./bin/tmux-session-manager --doctor

# Show debug info
./bin/tmux-session-manager --info
```

## Build System

The project includes a comprehensive Makefile for easy building:

```bash
make                # Build optimized release version
make build-debug    # Build debug version (faster compilation)  
make run            # Build and run interactively
make doctor         # Run health check
make info           # Show session manager info
make test           # Run test suite
make clean          # Clean build artifacts
make install        # Install to /usr/local/bin (requires sudo)
make watch          # Watch for changes and rebuild
```

## Architecture

### Core Components

- **`core/tmux.rs`**: Async tmux API wrapper
- **`core/session.rs`**: Session data structures  
- **`core/ui.rs`**: FZF integration and interface
- **`plugins/`**: Plugin system and implementations
- **`config.rs`**: Configuration management

### Plugin System

**Built-in Plugins** (compile-time, maximum performance):
- `active`: Currently active tmux sessions
- `worktree`: Git worktree sessions  
- `scratch`: Temporary/scratch sessions
- `tmuxinator`: Tmuxinator configuration sessions

**Dynamic Plugins** (runtime loading):
- Drop `.so`/`.dylib` files in `~/.config/tmux-session-manager/plugins/`
- No recompilation needed for new plugins
- Example template: `make plugin-template`

### Session Priority System

Sessions are ordered by plugin priority (lower number = higher priority):

- **Priority 5**: Worktree sessions (highest priority)
- **Priority 10**: Active tmux sessions  
- **Priority 50**: Tmuxinator configuration sessions
- **Priority 999**: Scratch/temporary sessions (lowest priority)

Within each priority level, sessions are sorted by last-attached timestamp (most recent first).
