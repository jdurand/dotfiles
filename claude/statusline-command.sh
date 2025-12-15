#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')
transcript_path=$(echo "$input" | jq -r '.transcript_path')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

# Try to get actual context usage from transcript file (JSONL format)
actual_context=0
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    # Get the last assistant message's input_tokens (approximates current context)
    # The transcript is JSONL format - one JSON object per line
    # Look for the most recent message with usage.input_tokens
    actual_context=$(tail -50 "$transcript_path" 2>/dev/null | \
        grep -o '"input_tokens":[0-9]*' | \
        tail -1 | \
        grep -o '[0-9]*')

    # Also check for cache_read_input_tokens which contributes to context
    cache_tokens=$(tail -50 "$transcript_path" 2>/dev/null | \
        grep -o '"cache_read_input_tokens":[0-9]*' | \
        tail -1 | \
        grep -o '[0-9]*')

    if [ -n "$cache_tokens" ] && [ "$cache_tokens" -gt 0 ] 2>/dev/null; then
        actual_context=$((actual_context + cache_tokens))
    fi
fi

# Use actual context if found and valid, otherwise fall back to cumulative
if [ -n "$actual_context" ] && [ "$actual_context" -gt 0 ] 2>/dev/null; then
    total_tokens=$actual_context
else
    total_tokens=$((total_input + total_output))
fi

# Calculate percentage
percent_used=$(awk "BEGIN {printf \"%.0f\", ($total_tokens / $context_size) * 100}")

# Cap at 100%
if [ "$percent_used" -gt 100 ]; then
    percent_used=100
fi

# Change directory for git branch detection
cd "$cwd" 2>/dev/null || cd "$HOME"
dir=$(basename "$(pwd)")

# Display directory in cyan
printf '\033[38;5;51m%s\033[0m' "$dir"

# Display git branch if in a git repo
if git rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        printf ' \033[90m%s\033[0m' "$branch"
    fi
fi

# Display model
printf ' \033[38;5;245m🤖\033[0m \033[38;5;245m%s\033[0m\n' "$model"

# Create progress bar with color based on usage
# Bar has 3 sections: used (colored), available (light), buffer/unusable (dark gray)
bar_width=10

# Auto-compact buffer: default to showing buffer (most users have it enabled)
# TODO: Add proper detection of auto-compact status when available
buffer_chars=${CLAUDE_AUTOCOMPACT_BUFFER:-2}
usable_chars=$((bar_width - buffer_chars))

# Calculate filled portion (cap at usable portion)
filled=$(awk "BEGIN {printf \"%.0f\", ($percent_used / 100) * $bar_width}")
if [ "$filled" -gt "$usable_chars" ]; then
    filled=$usable_chars
fi
empty_usable=$((usable_chars - filled))

# Color coding: muted/grayer colors for used portion
if [ "$percent_used" -lt 50 ]; then
    fill_color="38;5;65"   # gray-green/olive
elif [ "$percent_used" -lt 80 ]; then
    fill_color="38;5;136"  # dim yellow/olive
else
    fill_color="38;5;124"  # dim red
fi

# Build progress bar with 3 sections
progress_bar=""
# 1. Filled/used portion (muted colored)
for ((i=0; i<filled; i++)); do progress_bar+="\033[${fill_color}m█"; done
# 2. Empty but usable portion (grayer green)
for ((i=0; i<empty_usable; i++)); do progress_bar+="\033[38;5;23m░"; done
# 3. Buffer/unusable portion (lighter gray - visually distinct)
for ((i=0; i<buffer_chars; i++)); do progress_bar+="\033[38;5;242m░"; done
progress_bar+="\033[0m"

# Display context usage with progress bar
printf '🧠 \033[38;5;242mContext: %s%%\033[0m %b' "$percent_used" "$progress_bar"

# Format numbers with thousands separator
formatted_total=$(printf "%'d" $total_tokens 2>/dev/null || echo $total_tokens)
formatted_input=$(printf "%'d" $total_input 2>/dev/null || echo $total_input)
formatted_output=$(printf "%'d" $total_output 2>/dev/null || echo $total_output)

# Display token counts
printf '  \033[38;5;240mTokens: %s (in: %s out: %s)\033[0m' "$formatted_total" "$formatted_input" "$formatted_output"
