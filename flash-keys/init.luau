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
require("@self/surround")
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

-- After the style, which the lsp plugin makes the completion menu's mode from.
require("@self/completion")

-- The cursor is a block by default, in typing and in the completion menu
-- alike; "bar" with the flash-cursor option. core.modeless.define makes
-- the style's mode a bar, and the menu's mode copies it, so this comes
-- after both, and again whenever the option changes.
greed.option.define({
	name = "flash-cursor",
	doc = 'The flash style\'s cursor: "block" or "bar"',
	default = "block",
	choices = { "block", "bar" },
})

local function cursor()
	local shape = greed.option.get("flash-cursor") :: string
	greed.mode.set_cursor("flash", shape)
	greed.mode.set_cursor("completion-flash", shape)
end

cursor()
greed.on("option.changed", function(event: greed.OptionChanged)
	if event.name == "flash-cursor" then
		cursor()
	end
end)

return {
	selection = selection,
	find = find,
	jump = jump,
	edit = edit,
	keys = keymap.keys,
}
