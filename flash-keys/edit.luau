-- Editing commands with no exact match among Greed's own: case changes
-- that take the word at the cursor when nothing is selected, a paste that
-- can be taken back, marks, line prompts, replacing the next match, and
-- the previous match and pane.

local greed = require("@greed")
local core = require("@core")
local panes = require("@panes")
local selection = require("./selection")

local text = core.text

local M = {}

--- The word the cursor is in or touches, for a cursor between characters:
--- the one after it, or else the one it's just after. Nil in blanks or at
--- a line's end with no word before it, where Greed's own `word_at` would
--- take the spaces or the line break.
function M.word_near(buffer: greed.Buffer, pos: number): (number?, number?)
	if text.class(buffer:char_at(pos)) == "word" then
		return text.word_at(buffer, pos)
	end
	if pos > 0 then
		local before = buffer:prev_char(pos)
		if text.class(buffer:char_at(before)) == "word" then
			return text.word_at(buffer, before)
		end
	end
	return nil, nil
end

-- Selects the word near the primary cursor when nothing is selected.
-- Returns whether it did; with no word there it says so.
local function select_word(ctx: greed.Context): boolean
	local sel = ctx.view:selection()
	local range = sel.ranges[sel.primary]
	if range.anchor ~= range.head then
		return false
	end
	local from, to = M.word_near(ctx.buffer, range.head)
	if from and to then
		ctx.view:set_selection({ ranges = { { anchor = from, head = to } }, primary = 1 })
	else
		greed.echo("no word at the cursor")
	end
	return true
end

-- Runs `command` on each selection, or on the word at each cursor that has
-- none, leaving each cursor after what changed (as Emacs's M-u does).
local function on_words(ctx: greed.Context, command: string)
	local view, buffer = ctx.view, ctx.buffer
	local sel = view:selection()
	local had = text.anything_selected(sel)
	if not had then
		for i, range in sel.ranges do
			local from, to = M.word_near(buffer, range.head)
			if from and to then
				sel.ranges[i] = { anchor = from, head = to }
			end
		end
		view:set_selection(sel)
	end
	greed.run(command)
	if not had then
		local after = view:selection()
		for i, range in after.ranges do
			local stop = math.max(range.anchor, range.head)
			after.ranges[i] = { anchor = stop, head = stop }
		end
		view:set_selection(after)
		selection.forget(view)
	end
end

greed.command({
	name = "flash-upcase",
	doc = "Upper-case the selections, or the word at each cursor",
	run = function(ctx)
		on_words(ctx, "uppercase")
	end,
})

greed.command({
	name = "flash-downcase",
	doc = "Lower-case the selections, or the word at each cursor",
	run = function(ctx)
		on_words(ctx, "lowercase")
	end,
})

--- The case of `s`: "lower", "upper", "title" or "mixed".
function M.case_of(s: string): string
	if string.upper(s) == s and string.lower(s) ~= s then
		return "upper"
	elseif string.lower(s) == s then
		return "lower"
	elseif string.match(s, "^%u%l*$") then
		return "title"
	end
	return "mixed"
end

local CYCLE = { lower = "upper", upper = "title", title = "lower", mixed = "lower" }
local BACK = { lower = "title", title = "upper", upper = "lower", mixed = "lower" }
local COMMAND = { lower = "lowercase", upper = "uppercase", title = "title-case" }

-- Cycles each selection's case (or the word at each cursor's) through
-- lower, UPPER and Title, judged by the primary one.
for _, back in { false, true } do
	greed.command({
		name = if back then "flash-case-cycle-back" else "flash-case-cycle",
		doc = if back
			then "Change the case of the selections or words: lower, then Title, then UPPER"
			else "Change the case of the selections or words: lower, then UPPER, then Title",
		run = function(ctx)
			local sel = ctx.view:selection()
			local range = sel.ranges[sel.primary]
			local from, to = text.span(range)
			if from == to then
				local a, b = M.word_near(ctx.buffer, range.head)
				if a == nil or b == nil then
					return
				end
				from, to = a, b
			end
			local now = M.case_of(ctx.buffer:slice(from, to))
			local next = if back then BACK[now] else CYCLE[now]
			on_words(ctx, COMMAND[next])
		end,
	})
end

-- The last command run, by view, so alt-y knows whether the paste is
-- still the last thing done. ctrl-y is core's paste-over, which may read
-- the clipboard; this plugin never does.
local last_command: { [number]: string } = {}

greed.on("command.run", function(event: greed.CommandRun)
	if event.name ~= "flash-unpaste" then
		last_command[greed.view():id()] = event.name
	end
end)

greed.command({
	name = "flash-unpaste",
	doc = "Take back the last paste, when nothing else has been done since",
	run = function(ctx)
		if last_command[ctx.view:id()] == "paste-over" then
			last_command[ctx.view:id()] = nil
			greed.run("undo")
		else
			greed.echo("The last thing done wasn't a paste")
		end
	end,
})

-- Marks, by buffer and the key they were set with; they move with edits.
local marks: { [number]: { [string]: greed.Anchor } } = {}

greed.command({
	name = "flash-mark-set",
	doc = "Set a mark at the cursor, named by the next key",
	run = function(ctx)
		local key = greed.next_key()
		if key == "esc" then
			return
		end
		local mine = marks[ctx.buffer:id()] or {}
		marks[ctx.buffer:id()] = mine
		if mine[key] then
			mine[key]:forget()
		end
		mine[key] = ctx.buffer:track(ctx.view:cursor())
		greed.echo(`Mark {key} set`)
	end,
})

greed.command({
	name = "flash-mark-goto",
	doc = "Go to the mark named by the next key, extending an active selection",
	run = function(ctx)
		local key = greed.next_key()
		local mark = (marks[ctx.buffer:id()] or {})[key]
		local pos = mark and mark:pos()
		if pos == nil then
			if key ~= "esc" then
				greed.echo(`No mark {key}`)
			end
			return
		end
		selection.move(ctx, function()
			return pos
		end)
	end,
})

-- Asks for a line and moves there: `relative` takes +N or -N from the
-- cursor's line.
local function goto_line(ctx: greed.Context, relative: boolean)
	local answer = core.prompt.ask(if relative then "Lines (+N or -N)" else "Go to line")
	local n = answer and tonumber((string.gsub(answer, "^%+", "")))
	if n == nil then
		return
	end
	local buffer = ctx.buffer
	local line = if relative then buffer:line_of(ctx.view:cursor()) + n else n - 1
	line = math.clamp(line, 0, buffer:line_count() - 1)
	selection.move(ctx, function()
		return buffer:line_start(line)
	end)
end

greed.command({
	name = "flash-goto-line",
	doc = "Go to the line typed",
	run = function(ctx)
		goto_line(ctx, false)
	end,
})

greed.command({
	name = "flash-goto-line-relative",
	doc = "Go up or down by the number of lines typed, as +N or -N",
	run = function(ctx)
		goto_line(ctx, true)
	end,
})

-- What ctrl-r puts in place of a match; asked for the first time.
M.replacement = nil :: string?

greed.command({
	name = "flash-replacement",
	doc = "Set what ctrl-r and alt-r put in place of the search's matches",
	run = function()
		local answer = core.prompt.ask("Replace matches with", M.replacement)
		if answer then
			M.replacement = answer
		end
	end,
})

for _, back in { false, true } do
	greed.command({
		name = if back then "flash-replace-prev" else "flash-replace-next",
		doc = if back
			then "Replace the previous match of the last search"
			else "Replace the next match of the last search",
		run = function(ctx)
			local view = ctx.view
			local before = view:selection()
			greed.run(if back then "search-prev" else "search-next")
			local sel = view:selection()
			local range = sel.ranges[sel.primary]
			local from, to = text.span(range)
			local was = before.ranges[before.primary]
			if from == to or (range.anchor == was.anchor and range.head == was.head) then
				greed.echo("No match")
				return
			end
			-- Asked for after the search, since the prompt takes the focus
			-- for a moment after it's answered; the edit goes through the
			-- buffer and view themselves.
			if M.replacement == nil then
				M.replacement = core.prompt.ask("Replace matches with")
				if M.replacement == nil then
					return
				end
			end
			local with = M.replacement :: string
			ctx.buffer:edit(function(e)
				e:replace(from, to, with)
			end)
			local at = if back then from else from + #with
			view:set_selection({ ranges = { { anchor = at, head = at } }, primary = 1 })
			selection.forget(view)
		end,
	})
end

for _, back in { false, true } do
	greed.command({
		name = if back then "flash-add-prev-match" else "flash-add-next-match",
		doc = `Select the word at the cursor, then add the {if back then "previous" else "next"} `
			.. "match of it as another selection",
		run = function(ctx)
			if select_word(ctx) then
				return
			end
			if #ctx.view:selection().ranges == 1 then
				greed.run("search-selection")
			end
			greed.run(if back then "search-prev-add" else "search-next-add")
		end,
	})
end

greed.command({
	name = "flash-search-word",
	doc = "Search for the word at the cursor, or the selected text, and go to the next match",
	run = function(ctx)
		local sel = ctx.view:selection()
		local range = sel.ranges[sel.primary]
		if range.anchor == range.head then
			local from, to = M.word_near(ctx.buffer, range.head)
			if from == nil or to == nil then
				greed.echo("no word at the cursor")
				return
			end
			ctx.view:set_selection({ ranges = { { anchor = from, head = to } }, primary = 1 })
		end
		greed.run("search-selection")
		greed.run("search-next")
	end,
})

greed.command({
	name = "flash-pane-prev",
	doc = "Move to the previous pane",
	run = function()
		local tab = greed.tab.current()
		local current = panes.pane():id()
		for i, pane in tab.panes do
			if pane:id() == current then
				panes.focus(tab.panes[(i - 2) % #tab.panes + 1])
				return
			end
		end
	end,
})

greed.command({
	name = "flash-save-as",
	doc = "Save the buffer under a name you type",
	run = function()
		greed.run("command-line", { args = { "save " } })
	end,
})

-- Searches and motions that select their match: they extend an active
-- selection to the match, and otherwise select it, as Greed's do.
for name, command in
	{
		["flash-search-next"] = "search-next",
		["flash-search-prev"] = "search-prev",
	}
do
	greed.command({
		name = name,
		doc = `{command}; with a selection active, extend it to the match`,
		run = function(ctx)
			selection.wrap(ctx, command, false, true)
		end,
	})
end

-- A count for the next command, as Emacs's C-u: the digits typed, then
-- the keys of the command, which gets them as `ctx.count`.
greed.command({
	name = "flash-count",
	doc = "Type a number, then keys: their command runs that many times (as its count)",
	run = function()
		local digits = ""
		local key = greed.next_key()
		while string.match(key, "^%d$") do
			digits ..= key
			key = greed.next_key()
		end
		local count = tonumber(digits)
		local keys = key
		while true do
			local command, more = greed.keymap.resolve(keys)
			if command then
				greed.run(command, { count = count })
				return
			elseif not more then
				greed.echo(`{keys} runs nothing`)
				return
			end
			keys ..= " " .. greed.next_key()
		end
	end,
})

return M
