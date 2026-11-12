-- The completion menu in the flash style: tab and shift-tab (or the arrows)
-- go through it and enter puts the item in. Every other key does what it
-- always does: the menu closes and the command runs, so ctrl-w moves on
-- and ctrl-n searches as they do with no menu.
--
-- While the menu is open the mode is `completion-flash`, which the lsp
-- plugin makes from this style's own and which keeps its keys.

local greed = require("@greed")

local M = {}

--- The mode the menu is open in.
M.MODE = "completion-flash"

-- What keeps the menu open: its own commands, and typing, which narrows
-- what it offers.
local KEEPS = {
	["type-char"] = true,
	["erase-back"] = true,
	["erase-forward"] = true,
	["delete-back"] = true,
	["delete-forward"] = true,
}

--- Closes the completion menu, if one is open, without anything else:
--- the mode goes back to the style's own.
function M.close()
	for _, buffer in greed.buffers() do
		if buffer:kind() == "completion" then
			for _, view in buffer:views() do
				view:close()
			end
		end
	end
end

greed.on("command.run", function(event: greed.CommandRun)
	if greed.mode.get() ~= M.MODE then
		return
	end
	if KEEPS[event.name] or string.sub(event.name, 1, 11) == "completion-" then
		return
	end
	M.close()
end)

-- ctrl-n and ctrl-p are flash's (search, panes) rather than the menu's;
-- tab, shift-tab and the arrows go through the menu.
-- The lsp plugin binds the menu's keys for file buffers too, which come
-- ahead of the mode's own, so these go there as well.
local OURS = {
	["ctrl-n"] = "flash-search-next",
	["ctrl-p"] = "pane-next",
}
greed.keymap.bind(M.MODE, OURS)
greed.keymap.bind({ mode = M.MODE, kind = "file" }, OURS)

return M
