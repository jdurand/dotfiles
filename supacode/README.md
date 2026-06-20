# Supacode

Config for [Supacode](https://supacode.app) (`app.supabit.supacode`), the
git-worktree / coding-agent app. The whole `~/.supacode` directory is a symlink
to this folder so that Supacode's atomic writes land back inside the repo (a
file-level symlink would get replaced on the first save).

The goal of this config is to make Supacode feel like the ghostty + tmux setup:
a keyboard-driven, dark, low-chrome workspace where worktrees stand in for tmux
sessions.

## How it maps to ghostty / tmux

Supacode embeds its own Ghostty (libghostty, statically linked) for the terminal
surfaces and runs `zmx` inside each one for session persistence. A few
consequences:

- It does **not** read `~/.config/ghostty/config`; terminal appearance is driven
  by the app (`appearanceMode` + `terminalThemeSyncEnabled`), not the ghostty
  dotfile.
- `zmx` is dtach-style persistence (attach/detach/run/send) — **not** tmux. It
  has no prefix key, panes, or windows. Panes/tabs/worktrees are Supacode's
  native UI.
- App shortcuts are **single chords only** (a macOS `KeyboardShortcut`), so there
  is no tmux-style `prefix → key` sequence. The stand-in is a consistent
  modifier: **⌃⌥ (control+option) is the "supacode prefix-modifier"** across the
  whole map. It is collision-free against the terminal layers — `ctrl` alone is
  pane-nav, `alt` alone is ghostty escapes, and `C-a` is the tmux prefix.

### Splits (panes) are remapped via the Ghostty config, not settings.json

Split/focus actions (`new_split:*`, `goto_split:*`) are **Ghostty** keybinds, not
Supacode app shortcuts — they are absent from `shortcutOverrides` and the
Settings → Shortcuts UI (a `global.ghosttyShortcuts` map is silently stripped on
launch). But Supacode embeds Ghostty and **reads the standard Ghostty config**:
`GhosttyRuntime.loadConfig()` calls `ghostty_config_load_default_files()` and
does not set `XDG_CONFIG_HOME`, so it loads the same `~/.config/ghostty/config`
as standalone Ghostty, and routes bound keys to Ghostty before the app (see the
Supacode source `AGENTS.md` → "Ghostty Keybindings Handling").

There is no way to point Supacode at a *separate* config without breaking the
terminals: it never sets `XDG_CONFIG_HOME` (and surfaces launch with `login -p`,
inheriting the app env, so setting it would break fish/nvim/starship inside the
terminals), and the argv handed to `ghostty_init` is synthesized — real
`--config-file` args are dropped. So the split bindings live in the shared
`../ghostty/config`. Navigation reuses **⌃HJKL** (the same key as the tmux/nvim
pane-nav muscle memory) via Ghostty's `performable:` prefix: Ghostty only
consumes the key when the action actually moves focus (a split exists in that
direction); otherwise it falls through to the running program. Standalone
Ghostty is almost always a single pane (tmux does the splitting), so ⌃HJKL still
reaches tmux/nvim there. Splits use **⌃⇧HJKL**, unused everywhere. Vim layout,
h/j/k/l = left/down/up/right:

| Shortcut       | Action                   | tmux analogue          |
| -------------- | ------------------------ | ---------------------- |
| ⌃H/J/K/L       | focus split (navigate)   | pane nav (`C-hjkl`)    |
| ⌃⇧H/J/K/L      | new split (left/down/up/right) | `split-window`   |

Conceptual mapping:

| tmux            | Supacode  | key                  |
| --------------- | --------- | -------------------- |
| session         | worktree  | ⌃⇧U / ⌃⇧I            |
| window          | tab       | (native tab bar)     |
| pane            | surface   | ⌃HJKL nav, ⌃⇧HJKL split |
| prefix (`C-a`)  | ⌃⌥ chord  | —                    |

## Files

- `settings.json` — the tracked config. Only the `global` block is portable; the
  machine-specific `repositories`, `repositoryRoots`, and `pinnedWorktreeIDs` are
  stripped from the committed blob by the `clean-settings` git filter (see
  `.gitattributes`). The working copy Supacode reads keeps the real values.
- `layouts.json`, `sidebar.json` — pure machine/runtime state, git-ignored.
- `clean-settings` — the git clean filter.

## Shortcut map

`modifiers` in `settings.json` is a **custom Supacode bitmask** — NOT SwiftUI's
`EventModifiers`. Verified from in-app writes (⌘P → 1, ⌃⌥S → 12):

    command = 1,  shift = 2,  control = 4,  option = 8

so `⌃⌥` = 12, `⌃⇧` = 6, `⌃⌥⇧` = 14, `⌥` = 8. `keyCode` is a macOS virtual key
code (e.g. H=4, J=38, K=40, L=37).

Worktree navigation uses **⌃⇧** (matching the tmux window keys); the command
palette is **⌘P**; everything else uses the **⌃⌥** prefix-modifier.

| Shortcut                  | Action                    | tmux analogue          |
| ------------------------- | ------------------------- | ---------------------- |
| ⌃⇧U / ⌃⇧I                 | previous / next worktree  | `C-u` / `M-i` window   |
| ⌃⌥[ / ⌃⌥]                 | worktree history back/fwd | `<` / `>` window       |
| ⌃⌥N                       | new worktree              | new session            |
| ⌘P                        | command palette           | session manager popup  |
| ⌃⌥S                       | toggle left sidebar       | choose-tree            |
| ⌃⌥R                       | refresh worktrees         | source-file (reload)   |
| ⌃⌥⌫ (delete) / ⌃⌥A        | delete / archive worktree | kill-session           |
| ⌃⌥F                       | reveal in Finder          | yazi popup             |
| ⌃⌥Y                       | copy path                 | tmux-yank              |
| ⌃⌥G                       | open pull request         | lazygit popup          |
| ⌃⌥U                       | jump to latest unread     | —                      |
| ⌃⌥↩ (return) / ⌃⌥⇧↩       | run / stop run script     | run / stop             |
| ⌃⌥O                       | open repository           | —                      |

Shortcuts are edited in Settings → Shortcuts; because `~/.supacode` is symlinked
into this repo, any change you make in the UI is captured in git automatically.
