-- Everyday line and clipboard edits that need more than Greed's own
-- command: copying that lets go of the selection, uncommenting only, and
-- joining a line onto the one before it. Each edit is one change to undo.

local greed = require("@greed")
local core = require("@core")
local selection = require("./selection")

local M = {}

greed.command({
	name = "flash-copy",
	doc = "Copy the selections, or the cursors' lines with nothing selected, "
		.. "then collapse to each head and turn persistent selection off",
	run = function(ctx)
		greed.run("copy-or-line")
		selection.collapse(ctx.view, false)
	end,
})

greed.command({
	name = "flash-copy-keep",
	doc = "Copy the selections, or the cursors' lines with nothing selected, keeping the selection",
	run = function()
		greed.run("copy-or-line")
	end,
})

-- The lines the selections touch, each once, in order.
local function lines_of(ctx: greed.Context): { number }
	return core.motions.selected_lines(ctx)
end

greed.command({
	name = "flash-uncomment",
	doc = "Take the line comment off the selected lines that have one; never adds one",
	run = function(ctx)
		local buffer = ctx.buffer
		local token = core.comment.token(buffer:language())
		if token == nil then
			greed.echo("no line comment for this language")
			return
		end
		buffer:edit(function(e)
			for _, line in lines_of(ctx) do
				local text = buffer:line_text(line)
				local lead = #(string.match(text, "^[ \t]*") :: string)
				if string.sub(text, lead + 1, lead + #token) == token then
					local take = #token
					if string.sub(text, lead + #token + 1, lead + #token + 1) == " " then
						take += 1
					end
					local at = buffer:line_start(line) + lead
					e:delete(at, at + take)
				end
			end
		end)
	end,
})

greed.command({
	name = "flash-join-prev",
	doc = "Join each cursor's line onto the line before it, with one space",
	run = function(ctx)
		local buffer = ctx.buffer
		local firsts: { [number]: boolean } = {}
		for _, range in ctx.view:selection().ranges do
			local from = core.text.span(range)
			local line = buffer:line_of(from)
			if line > 0 then
				firsts[line] = true
			end
		end
		buffer:edit(function(e)
			for line in firsts do
				local text = buffer:line_text(line)
				local lead = #(string.match(text, "^[ \t]*") :: string)
				e:replace(buffer:line_end(line - 1), buffer:line_start(line) + lead, " ")
			end
		end)
	end,
})

return M
