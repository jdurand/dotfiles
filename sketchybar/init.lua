-- Require the sketchybar module
SketchyBar = require("sketchybar")

-- Set the bar name, if you are using another bar instance than sketchybar
-- SketchyBar.set_bar_name("bottom_bar")

-- Bundle the entire initial configuration into a single message to sketchybar
SketchyBar.begin_config()
require("bar")
require("default")
require("items")
SketchyBar.end_config()

-- Run the event loop of the sketchybar module (without this there will be no
-- callback functions executed in the lua module)
SketchyBar.event_loop()
