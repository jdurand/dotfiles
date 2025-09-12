local Terminal = {}

-- Convenience function that returns a click_script path for SketchyBar widgets
function Terminal.get_floating_tui_click_script(command, options)
  return Terminal.create_persistent_tui_script(command, options)
end

-- Create a permanent script file for a TUI app (better than temp files)
function Terminal.create_persistent_tui_script(command, options)
  options = options or {}

  local width_cols = options.width_cols or "140c"
  local height_rows = options.height_rows or "40c"
  local title = options.title or "floating-tui"
  local args = options.args or ""

  -- Handle command with arguments
  local base_command = command
  local command_args = ""
  if command:find(" ") then
    base_command = command:match("^(%S+)")
    command_args = command:match("^%S+%s+(.*)") or ""
  end

  -- If args is provided in options, use that instead
  if args ~= "" then
    command_args = args
  end

  -- Create script in SketchyBar scripts directory
  local script_name = "launch_" .. base_command:gsub("[^%w%-]", "_") .. ".sh"
  local script_dir = os.getenv("TMPDIR") .. "/scripts"
  local script_path = script_dir .. "/" .. script_name

  -- Ensure scripts directory exists
  os.execute("mkdir -p " .. script_dir)

  -- Generate the shell script content using string concatenation to avoid bracket conflicts
  local script_content = "#!/bin/bash\n\n"
  script_content = script_content .. "# Find " .. base_command .. " executable\n"
  script_content = script_content .. "COMMAND_PATH=\"\"\n"
  script_content = script_content .. "for path in /opt/homebrew/bin/" .. base_command .. " /usr/local/bin/" .. base_command .. " /usr/bin/" .. base_command .. " $(which " .. base_command .. " 2>/dev/null); do\n"
  script_content = script_content .. "  if [ -x \"$path\" ]; then\n"
  script_content = script_content .. "    COMMAND_PATH=\"$path\"\n"
  script_content = script_content .. "    break\n"
  script_content = script_content .. "  fi\n"
  script_content = script_content .. "done\n\n"
  script_content = script_content .. "if [ -z \"$COMMAND_PATH\" ]; then\n"
  script_content = script_content .. "  echo \"" .. base_command .. " not found\"\n"
  script_content = script_content .. "  exit 1\n"
  script_content = script_content .. "fi\n\n"
  script_content = script_content .. "# Launch Kitty with " .. base_command .. " in a floating window\n"
  script_content = script_content .. "# Use -n flag to force a new instance instead of reusing existing window\n"
  script_content = script_content .. "open -n -a kitty --args \\\n"
  script_content = script_content .. "   --config /Users/jdurand/.config/kitty/tui.conf \\\n"
  script_content = script_content .. "  --title=\"" .. title .. "\" \\\n"
  script_content = script_content .. "  --override remember_window_size=no \\\n"
  script_content = script_content .. "  --override initial_window_width=" .. width_cols .. " \\\n"
  script_content = script_content .. "  --override initial_window_height=" .. height_rows .. " \\\n"
  script_content = script_content .. "  \"$COMMAND_PATH\""

  if command_args ~= "" then
    script_content = script_content .. " " .. command_args
  end

  script_content = script_content .. "\n"

  -- Write the script
  local file = io.open(script_path, "w")
  if file then
    file:write(script_content)
    file:close()

    -- Make executable
    os.execute("chmod +x " .. script_path)
    Logger:info("Created persistent TUI script: " .. script_path)
    return "$TMPDIR/scripts/" .. script_name
  else
    Logger:error("Failed to create persistent TUI launch script")
    return nil
  end
end

return Terminal
