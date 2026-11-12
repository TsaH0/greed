local greed = require("@greed")
local test = require("@greed/test")
local flash = require("@flash-keys")

test(":style flash switches to it, and the other styles stay as they were", function(t)
	t:buffer("|abc")
	t:run("style", { "flash" })
	t:expect_mode("flash")
	t:keys("x")
	t:expect("x|abc")
	greed.option.set("editing-style", "helix")
	t:expect_mode("helix")
	t:keys("w")
	t:expect("x^abc|")
	greed.option.set("editing-style", "vscode")
	t:expect_mode("vscode")
	assert(greed.keymap.resolve("ctrl-space f") == "pick-file", "vscode keeps its leader")
end)

test("every key is bound to a command that exists", function()
	local known = {}
	for _, command in greed.commands() do
		known[command.name] = true
	end
	for keys, command in flash.keys do
		assert(known[command], `{keys} runs {command}, which doesn't exist`)
	end
end)

test("in flash, its own keys win over the keys bound for every mode", function(t)
	t:buffer("|abc")
	greed.mode.set("flash")
	-- alt-h j k l move between panes everywhere else, alt-space arranges the
	-- tab, alt-= and alt-- resize panes, alt-f toggles floats.
	local mine = {
		["ctrl-space"] = "flash-space",
		["alt-h"] = "flash-char-right",
		["alt-j"] = "flash-line-up",
		["alt-k"] = "flash-line-down",
		["alt-l"] = "flash-char-left",
		["alt-f"] = "flash-find-prev",
		["alt-="] = "font-smaller",
		["alt--"] = "fold-open",
		["alt-n"] = "flash-search-prev",
		["alt-p"] = "flash-pane-prev",
		["alt-w"] = "flash-word-prev",
		["alt-m"] = "flash-jump-back",
		["alt-t alt-r"] = "flash-around-r",
	}
	for keys, command in mine do
		local got = greed.keymap.resolve(keys)
		assert(got == command, `{keys}: {got}`)
	end
	-- What flash leaves to Greed, and the C-x keys for what it takes.
	local kept = {
		["alt-left"] = "pane-left",
		["ctrl-x r"] = "resize-mode",
		["alt-+"] = "pane-grow",
		["alt->"] = "tab-next",
		["ctrl-x p"] = "pane-mode",
		["ctrl-x t"] = "tab-mode",
		["ctrl-x l"] = "layout-next",
		["ctrl-x f"] = "floats-toggle",
		["ctrl-x n"] = "pane-terminal",
	}
	for keys, command in kept do
		local got = greed.keymap.resolve(keys)
		assert(got == command, `{keys}: {got}`)
	end
end)

test("other styles keep the keys flash takes from them", function(t)
	t:buffer("|abc")
	greed.option.set("editing-style", "helix")
	assert(greed.keymap.resolve("alt-j") == "pane-down", tostring(greed.keymap.resolve("alt-j")))
	assert(greed.keymap.resolve("alt-space") ~= "leader", "alt-space stays the layout key")
end)

test("the leader opens with alt-space", function(t)
	t:buffer("|abc")
	greed.mode.set("flash")
	local _, more = greed.keymap.resolve("alt-space")
	assert(more, "alt-space starts the leader")
	assert(greed.keymap.resolve("alt-space f") == "pick-file", "space f finds files")
end)

test("pickers keep their own keys and typing", function(t)
	t:buffer("|abc")
	greed.mode.set("flash")
	t:keys("ctrl-x b")
	assert(greed.view():buffer():kind() == "picker", "buffer picker")
	assert(greed.keymap.resolve("ctrl-n") == "picker-next", tostring(greed.keymap.resolve("ctrl-n")))
	t:type("zz")
	assert(string.find(greed.view():buffer():text(), "zz", 1, true), "typed into the picker")
	t:keys("esc")
	assert(greed.view():buffer():kind() ~= "picker", "esc closes it")
end)

test("the command line takes what's typed and runs it", function(t)
	t:buffer("|abc")
	greed.mode.set("flash")
	t:keys("ctrl-x :")
	t:type("set tab-width 3")
	t:keys("enter")
	assert(greed.option.get("tab-width") == 3, tostring(greed.option.get("tab-width")))
	t:expect_mode("flash")
end)

test("a prompt's typing isn't taken by flash's keys", function(t)
	t:buffer("|a\nb\nc")
	greed.mode.set("flash")
	t:keys("ctrl-g l")
	t:type("2")
	t:keys("enter")
	t:expect("a\n|b\nc")
end)

test("a terminal sends flash's keys to its program", function(t)
	t:buffer("|abc")
	greed.mode.set("flash")
	t:run("terminal", { "cat" })
	t:wait_for(function()
		return greed.mode.get() == "terminal"
	end)
	for _, keys in { "ctrl-w", "alt-h", "ctrl-f", "ctrl-space" } do
		local got = greed.keymap.resolve(keys)
		assert(got == nil or not string.find(got, "^flash%-"), `{keys}: {got}`)
	end
end)

test("ctrl-c n gives the next command a count", function(t)
	t:buffer("|a b c d e")
	greed.mode.set("flash")
	t:keys("ctrl-c n 3 ctrl-w")
	t:expect("^a b c |d e")
	t:keys("ctrl-c n 2 ctrl-W")
	t:expect("^a b c d e|")
end)

test("unloading the plugin takes its style and keys away, and reloading brings them back", function(t)
	t:buffer("|abc")
	local dir = greed.plugin.dirs()["flash-keys"]
	greed.plugin.unload("flash-keys")
	t:wait(0)
	local styles = {}
	for _, style in require("@core").style.list() do
		styles[style.name] = true
	end
	assert(not styles.flash, "style gone")
	assert(#greed.keymap.find("flash-word-next") == 0, "keys gone")
	greed.plugin.load(dir)
	t:wait(0)
	greed.mode.set("flash")
	t:keys("ctrl-W")
	t:expect("^abc|")
end)
