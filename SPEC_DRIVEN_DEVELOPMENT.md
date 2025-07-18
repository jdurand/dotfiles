# Spec-Driven Development with Neovim

A comprehensive workflow for implementing features using specification-driven development with Claude AI integration.

## Overview

This system implements Kiro's spec-driven development approach with automation hooks, enabling you to:
1. Create detailed feature specifications
2. Generate implementation tasks from specs using Claude
3. Generate code from individual tasks using Claude
4. Automatically run linting and testing on save
5. Track progress through integrated tools

## Directory Structure

```
your-project/
├── features/
│   ├── user-authentication/
│   │   ├── spec.md           # Feature specification
│   │   ├── tasks.md          # Implementation tasks
│   │   ├── design.md         # Architectural notes
│   │   ├── user_auth.rb      # Implementation files
│   │   └── user_auth_spec.rb # Test files
│   ├── payment-processing/
│   │   ├── spec.md
│   │   ├── tasks.md
│   │   ├── design.md
│   │   └── payment.js
│   └── ...
├── spec/                     # Global tests
├── lib/                      # Shared libraries
└── config/                   # Configuration files
```

## Key Bindings

### Feature Management
- `<leader>fn` - Create new feature
- `<leader>fo` - Open all feature files in tabs
- `<leader>fs` - Open feature spec.md
- `<leader>ft` - Open feature tasks.md
- `<leader>fd` - Open feature design.md

### Claude Integration
- `<leader>st` - Generate tasks from spec (spec → tasks)
- `<leader>tc` - Generate code from current task (task → code)

### Testing
- `<leader>tt` - Run nearest test
- `<leader>tf` - Run current file tests
- `<leader>ta` - Run all tests
- `<leader>ts` - Toggle test summary
- `<leader>to` - Open test output

### Formatting
- `<leader>cf` - Format current buffer

### Git Integration
- `<leader>gg` - Open Neogit
- `<leader>gc` - Git commit
- `<leader>gp` - Git push

## Commands

- `:CreateFeature [name]` - Create new feature structure
- `:SpecToTasks` - Generate tasks from current spec
- `:TaskToCode` - Generate code from current task
- `:OpenFeature` - Open all feature files

## Workflow

### 1. Create Feature
```bash
# In Neovim
:CreateFeature user-authentication
# Or use keybinding: <leader>fn
```

This creates:
- `features/user-authentication/spec.md` - Feature specification
- `features/user-authentication/tasks.md` - Empty tasks file
- `features/user-authentication/design.md` - Empty design file

### 2. Write Specification
Edit `spec.md` with:
- Overview of the feature
- Detailed requirements
- Acceptance criteria
- Technical notes
- Dependencies

### 3. Generate Tasks
With `spec.md` open, press `<leader>st` to generate `tasks.md` from the specification using Claude.

### 4. Implement Tasks
1. Open `tasks.md`
2. Position cursor on any task line
3. Press `<leader>tc` to generate code for that task
4. Choose file extension (rb, js, ts, py)
5. Claude generates implementation code

### 5. Auto-Testing & Linting
When you save any source file (`.rb`, `.js`, `.ts`, `.py`):
- Automatic linting runs
- Tests run in background
- Results displayed in status line

## Setup Requirements

### Environment Variables
```bash
# Required for Claude integration
export ANTHROPIC_API_KEY="your-api-key-here"
```

### Dependencies
Install language-specific tools:

```bash
# Ruby
gem install rubocop rspec

# JavaScript/TypeScript
npm install -g eslint prettier jest

# Python
pip install flake8 black isort pytest
```

## Configuration

The system is configured in `lua/plugins/spec-driven-dev.lua`:

```lua
-- Custom configuration options
spec_driven.setup({
  features_dir = "features",        -- Directory for features
  
  linters = {
    ruby = "bundle exec rubocop",
    javascript = "npx eslint",
    typescript = "npx eslint",
    python = "flake8",
  },
  
  test_runners = {
    ruby = "bundle exec rspec",
    javascript = "npm test",
    typescript = "npm test", 
    python = "pytest",
  },
  
  claude_model = "claude-3-5-sonnet-20241022",
  max_tokens = 4000,
})
```

## Claude Prompting Tips

### For Spec-to-Tasks
Claude is prompted with:
- The complete feature specification
- Instructions to create actionable, ordered tasks
- Request for markdown checkbox format
- Emphasis on measurable, specific tasks

### For Task-to-Code
Claude receives:
- The current task being implemented
- The complete feature specification
- All generated tasks for context
- Any existing code in the target file
- Instructions for clean, production-ready code

### Best Practices
1. **Detailed Specs**: More detailed specs generate better tasks
2. **Clear Tasks**: Specific tasks generate better code
3. **Iterative Approach**: Generate code for one task at a time
4. **Review Generated Code**: Always review and refine generated code
5. **Update Tasks**: Mark tasks as complete and add new ones as needed

## Automation Features

### Auto-Save
- Automatically saves when switching between feature files
- Prevents losing work during rapid context switching

### Auto-Format
- Formats code on save using language-specific formatters
- Organizes tasks.md (moves completed items to bottom)

### Auto-Test
- Runs tests in background when saving source files
- Displays test results in status line
- Only runs for files in `features/` directory

### Visual Indicators
- Highlights TODO/FIXME/NOTE comments in markdown files
- Shows current feature name in status line
- Test status indicators in gutter

## Troubleshooting

### Claude Integration Issues
1. Verify `ANTHROPIC_API_KEY` is set
2. Check internet connection
3. Ensure curl is installed
4. Try reducing spec/task complexity

### Test Runner Issues
1. Verify test commands are correct for your project
2. Check that test files exist and are properly named
3. Ensure dependencies are installed

### Linting Issues
1. Install language-specific linters
2. Configure linter rules in project config files
3. Check file paths and permissions

## Example Project Structure

See `example-spec-driven-project/` for a complete example featuring:
- User authentication feature
- Complete spec, tasks, and design files
- Sample Ruby implementation
- Test files and configuration