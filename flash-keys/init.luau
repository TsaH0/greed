-- Flash Keys: an editing style without modes. Ctrl does a thing, alt its
-- opposite, shift selects, ctrl-space keeps selecting until pressed again,
-- and plain keys type. See docs/README.md for every key.
--
-- Switch to it with `:style flash`, or start in it from
-- ~/.config/greed/init.luau:
--
--     require("@greed").option.set("editing-style", "flash")

local greed = require("@greed")
local core = require("@core")

local selection = require("@self/selection")
require("@self/motions")
local find = require("@self/find")
require("@self/objects")
local jump = require("@self/jump")
local edit = require("@self/edit")
require("@self/lines")
local keymap = require("@self/keymap")

greed.keymap.bind("flash", keymap.keys)

core.modeless.define({
	name = "flash",
	doc = "No modes: ctrl does, alt undoes, shift selects (Emacs, Helix, Vim and Neovim keys)",
	-- ctrl-space toggles the selection here, so the leader is on alt-space.
	leader = "alt-space",
	label = "flash",
	pairs = true,
})

return {
	selection = selection,
	find = find,
	jump = jump,
	edit = edit,
	keys = keymap.keys,
}
