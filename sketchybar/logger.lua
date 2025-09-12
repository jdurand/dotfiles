-- Logger configuration
return {
  -- Log levels (higher number = more verbose)
  LEVELS = {
    ERROR = 1,
    WARN = 2,
    INFO = 3,
    DEBUG = 4
  },

  -- Current log level - change this to control verbosity
  current_level = 2, -- DEBUG level (shows all logs)

  -- Log file location
  file = "/tmp/sketchybar.log", -- tail -f /tmp/sketchybar.log

  -- Internal logging function
  _log = function(self, level, level_name, message)
    if level <= self.current_level then
      local timestamp = os.date("%Y-%m-%d %H:%M:%S")
      local formatted = "[" .. timestamp .. "] " .. level_name .. ": " .. message
      os.execute("echo '" .. formatted .. "' >> " .. self.file)
    end
  end,

  -- Log level methods
  error = function(self, message) self:_log(self.LEVELS.ERROR, "ERROR", message) end,
  warn = function(self, message) self:_log(self.LEVELS.WARN, "WARN", message) end,
  info = function(self, message) self:_log(self.LEVELS.INFO, "INFO", message) end,
  debug = function(self, message) self:_log(self.LEVELS.DEBUG, "DEBUG", message) end,

  -- Table logging function
  debug_table = function(self, title, tbl)
    if self.LEVELS.DEBUG <= self.current_level then
      local debug_file = io.open(self.file, "a")
      if debug_file then
        debug_file:write("=== " .. title .. " ===\n")
        debug_file:write("Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
        for k, v in pairs(tbl) do
          debug_file:write(tostring(k) .. " = " .. tostring(v) .. "\n")
        end
        debug_file:write("========================\n\n")
        debug_file:close()
      end
    end
  end
}
