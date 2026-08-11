local alert = require("hs.alert")
local pathwatcher = require("hs.pathwatcher")

local configDirectory = hs.configdir
local reload = hs.reload

local M = {}
local watcher

local function isLuaFile(path)
  return path:match("%.lua$") ~= nil
end

local function reloadConfig(changedFiles)
  for _, path in ipairs(changedFiles) do
    if isLuaFile(path) then
      reload()
      return
    end
  end
end

function M.start()
  if watcher then
    return
  end

  -- Path watchers are recursive, so this includes every config subdirectory.
  watcher = pathwatcher.new(configDirectory, reloadConfig):start()
  alert.show("Config loaded")
end

return M
