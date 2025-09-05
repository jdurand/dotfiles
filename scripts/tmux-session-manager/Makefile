# Makefile for tmux-session-manager Rust rewrite

.PHONY: build build-release clean install uninstall test doctor info watch dev help

# Default target
build: build-release

# Build in release mode (optimized)
build-release:
	@echo "Building tmux-session-manager in release mode..."
	cargo build --release
	@mkdir -p bin
	cp target/release/tmux-session-manager bin/
	@echo "✓ Built: bin/tmux-session-manager"

# Build in debug mode (faster compilation)
build-debug:
	@echo "Building tmux-session-manager in debug mode..."
	cargo build
	@mkdir -p bin
	cp target/debug/tmux-session-manager bin/
	@echo "✓ Built: bin/tmux-session-manager (debug)"

# Clean build artifacts
clean:
	cargo clean
	rm -rf bin/

# Install to system (requires admin privileges)
install: build-release
	@echo "Installing tmux-session-manager to /usr/local/bin..."
	sudo cp bin/tmux-session-manager /usr/local/bin/
	sudo chmod +x /usr/local/bin/tmux-session-manager
	@echo "✓ Installed to /usr/local/bin/tmux-session-manager"

# Uninstall from system
uninstall:
	@echo "Removing tmux-session-manager from /usr/local/bin..."
	sudo rm -f /usr/local/bin/tmux-session-manager
	@echo "✓ Uninstalled"

# Run tests
test:
	cargo test

# Run doctor command
doctor: build-release
	./bin/tmux-session-manager --doctor

# Run info command
info: build-release
	./bin/tmux-session-manager --info

# Development: watch for changes and rebuild
watch:
	@command -v cargo-watch >/dev/null 2>&1 || (echo "Installing cargo-watch..." && cargo install cargo-watch)
	cargo watch -x 'build --release' -s 'mkdir -p bin && cp target/release/tmux-session-manager bin/'

# Watch and run
dev:
	@command -v cargo-watch >/dev/null 2>&1 || (echo "Installing cargo-watch..." && cargo install cargo-watch)
	cargo watch -x 'run --'

# Check code formatting and linting
check:
	cargo fmt --check
	cargo clippy -- -D warnings

# Format code
format:
	cargo fmt

# Run the built binary
run: build-release
	./bin/tmux-session-manager

# Create a dynamic plugin template
plugin-template:
	@mkdir -p plugins/example
	@cat > plugins/example/Cargo.toml << 'EOF'
[package]
name = "example-plugin"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
tmux-session-manager = { path = "../.." }
anyhow = "1.0"
async-trait = "0.1"
EOF
	@cat > plugins/example/src/lib.rs << 'EOF'
use anyhow::Result;
use async_trait::async_trait;
use tmux_session_manager::core::session::{SessionContext, SessionItem, SessionMetadata};
use tmux_session_manager::plugins::{DynamicPlugin, PluginMetadata, SessionPlugin};
use tmux_session_manager::register_plugin;

pub struct ExamplePlugin;

impl ExamplePlugin {
    pub fn new() -> Self {
        Self
    }
}

#[async_trait]
impl SessionPlugin for ExamplePlugin {
    fn name(&self) -> &str { "example" }
    fn description(&self) -> &str { "Example dynamic plugin" }
    fn priority(&self) -> u32 { 100 }

    async fn discover(&self, _context: &SessionContext) -> Result<Vec<SessionItem>> {
        Ok(Vec::new())
    }

    async fn resolve(&self, _session_name: &str, _context: &SessionContext) -> Result<SessionMetadata> {
        Ok(SessionMetadata::new("example".to_string()))
    }

    async fn switch(&self, _session_name: &str, _metadata: &SessionMetadata) -> Result<()> {
        Ok(())
    }
}

impl DynamicPlugin for ExamplePlugin {
    fn metadata(&self) -> PluginMetadata {
        PluginMetadata {
            name: "example".to_string(),
            description: "Example dynamic plugin".to_string(),
            version: "0.1.0".to_string(),
            priority: 100,
            dependencies: vec![],
            author: Some("Your Name".to_string()),
            homepage: None,
        }
    }
}

register_plugin!(ExamplePlugin);
EOF
	@echo "✓ Created plugin template in plugins/example/"
	@echo "  Edit plugins/example/src/lib.rs and run 'make build-plugins' to build"

# Build dynamic plugins
build-plugins:
	@echo "Building dynamic plugins..."
	@for plugin_dir in plugins/*/; do \
		if [ -f "$$plugin_dir/Cargo.toml" ]; then \
			echo "Building plugin: $$plugin_dir"; \
			cd "$$plugin_dir" && cargo build --release; \
			cd ../..; \
		fi; \
	done
	@echo "✓ Plugins built in plugins/*/target/release/"

# Help message
help:
	@echo "tmux-session-manager Rust Build System"
	@echo "======================================"
	@echo ""
	@echo "Targets:"
	@echo "  build          - Build optimized release version (default)"
	@echo "  build-debug    - Build debug version (faster compilation)"
	@echo "  clean          - Clean all build artifacts"
	@echo "  install        - Install to /usr/local/bin (requires sudo)"
	@echo "  uninstall      - Remove from /usr/local/bin"
	@echo "  test           - Run test suite"
	@echo "  doctor         - Run built-in health check"
	@echo "  info           - Show session manager info"
	@echo "  watch          - Watch for changes and rebuild"
	@echo "  check          - Check code formatting and linting"
	@echo "  format         - Format code with rustfmt"
	@echo "  run            - Build and run the session manager"
	@echo "  plugin-template - Create example dynamic plugin template"
	@echo "  build-plugins  - Build all dynamic plugins"
	@echo "  help           - Show this help message"
	@echo ""
	@echo "Quick start:"
	@echo "  make           # Build the session manager"
	@echo "  make run       # Build and run interactively"
	@echo "  make doctor    # Check system health"