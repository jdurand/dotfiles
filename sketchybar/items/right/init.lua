-- Right side items - order matters for positioning
-- Calendar goes first to be far right
require("items.right.calendar")
-- System widgets go next (left of calendar)
require("items.right.widgets")
-- Note: Spotify is positioned dynamically by Screen service
