-- Motions. Each has a plain command (`flash-word-next`), which selects
-- what it moves over (see selection.luau), and an extending one
-- (`flash-select-word-next`), bound with shift, which keeps the anchor.

local greed = require("@greed")
local core = require("@core")
local selection = require("./selection")

local text = core.text
type Buffer = greed.Buffer

local M = {}

-- Where the word before `pos` ends: the nearest place back from `pos`
-- where a word or run of punctuation stops.
function M.prev_word_end(buffer: Buffer, pos: number): number
	local p = pos
	while p > 0 do
		p = buffer:prev_char(p)
		if p == 0 then
			return 0
		end
		local before = text.class(buffer:char_at(buffer:prev_char(p)))
		local here = text.class(buffer:char_at(p))
		if before ~= "space" and before ~= "eol" and here ~= before then
			return p
		end
	end
	return 0
end

local function blank(buffer: Buffer, pos: number): boolean
	local class = text.class(buffer:char_at(pos))
	return class == "space" or class == "eol"
end

-- Past the blanks (line breaks too) at `pos`.
local function past_blanks(buffer: Buffer, pos: number): number
	while pos < buffer:len() and blank(buffer, pos) do
		pos = buffer:next_char(pos)
	end
	return pos
end

-- The next word with the blanks after it, from the first word at or after
-- the head: pressed again, the word after that.
local function word_next(buffer: Buffer, head: number): (number, number)
	local from = past_blanks(buffer, head)
	return text.next_word_start(buffer, from), from
end

-- The next word on its own, without the blanks before or after it.
local function word_end(buffer: Buffer, head: number): (number, number)
	local from = past_blanks(buffer, head)
	return text.word_end(buffer, from), from
end

-- Back to the first non-blank, then to the line's start; from the line's
-- start, the line before (from its end back to its start).
local function line_start(buffer: Buffer, head: number): (number?, number?)
	local line = buffer:line_of(head)
	local start = buffer:line_start(line)
	local first = text.first_non_blank(buffer, start)
	if head > first then
		return first, nil
	elseif head > start then
		return start, nil
	elseif line > 0 then
		return buffer:line_start(line - 1), buffer:line_end(line - 1)
	end
	return nil, nil
end

-- To the line's end; from the line's end, the next line (from its start
-- to its end, without the line break).
local function line_end(buffer: Buffer, head: number): (number?, number?)
	local line = buffer:line_of(head)
	local stop = buffer:line_end(line)
	if head < stop then
		return stop, nil
	elseif line + 1 < buffer:line_count() then
		return buffer:line_end(line + 1), buffer:line_start(line + 1)
	end
	return nil, nil
end

--- The motions that move each head by a function of the text.
M.targets = {
	["char-left"] = function(buffer: Buffer, head: number): number?
		return if head > 0 then text.step(buffer, head, -1) else nil
	end,
	["char-right"] = function(buffer: Buffer, head: number): number?
		return if head < buffer:len() then text.step(buffer, head, 1) else nil
	end,
	["word-next"] = word_next,
	["word-prev"] = text.prev_word_start,
	["word-end"] = word_end,
	["word-end-prev"] = M.prev_word_end,
	["line-start"] = line_start,
	["line-end"] = line_end,
} :: { [string]: selection.Target }

local DOCS: { [string]: string } = {
	["char-left"] = "a character left",
	["char-right"] = "a character right",
	["word-next"] = "to the start of the next word",
	["word-prev"] = "to the start of the previous word",
	["word-end"] = "to the end of the word",
	["word-end-prev"] = "to the end of the previous word",
	["line-start"] = "back to the first non-blank, the line's start, then the line before",
	["line-end"] = "to the end of the line, then the next line",
	["line-down"] = "a line down",
	["line-up"] = "a line up",
	["page-down"] = "a page down",
	["page-up"] = "a page up",
	["doc-start"] = "to the start of the buffer",
	["doc-end"] = "to the end of the buffer",
}

-- The motions that only move the cursor; the others select what they go
-- over.
local MOVES = {
	["char-left"] = true,
	["char-right"] = true,
	["line-down"] = true,
	["line-up"] = true,
	["page-down"] = true,
	["page-up"] = true,
	["doc-start"] = true,
	["doc-end"] = true,
}

-- Defines `flash-NAME` and `flash-select-NAME` running `run(ctx, shift)`.
local function pair(name: string, run: (ctx: greed.Context, shift: boolean) -> ())
	for _, shift in { false, true } do
		greed.command({
			name = if shift then `flash-select-{name}` else `flash-{name}`,
			doc = if shift
				then `Extend the selection {DOCS[name]}`
				elseif MOVES[name] then `Move {DOCS[name]}`
				else `Select {DOCS[name]}`,
			run = function(ctx)
				run(ctx, shift)
			end,
		})
	end
end

-- h and l only move the cursor (collapsing any selection), as j and k
-- do; with shift they extend.
for name, target in M.targets do
	pair(name, function(ctx, shift)
		if MOVES[name] then
			selection.teleport(ctx, target, shift)
		else
			selection.move(ctx, target, shift)
		end
	end)
end

-- Up and down only move the cursor, as h and l do; with shift they
-- extend. They keep the column they started from while nothing else
-- touches the selection, so going through a short line doesn't lose it.
-- Folded lines are stepped over.
local goals: { [number]: { selection: greed.Selection, columns: { number } } } = {}

local function vertical(ctx: greed.Context, delta: number, shift: boolean)
	local view, buffer = ctx.view, ctx.buffer
	local extend = selection.active(view, shift)
	local sel = view:selection()
	local goal = goals[view:id()]
	local columns: { number } = {}
	-- Only the cursors count, so stopping a selection keeps the column.
	local same_heads = goal ~= nil and #goal.selection.ranges == #sel.ranges
	if goal and same_heads then
		for i, range in sel.ranges do
			if goal.selection.ranges[i].head ~= range.head then
				same_heads = false
			end
		end
	end
	if goal and same_heads then
		columns = goal.columns
	else
		for i, range in sel.ranges do
			columns[i] = text.drawn_column(buffer, range.head, view)
		end
	end
	local hidden = view:hidden_lines()
	local function folded(line: number): boolean
		for _, lines in hidden do
			if line >= lines.from and line <= lines.to then
				return true
			end
		end
		return false
	end
	local last = buffer:line_count() - 1
	for i, range in sel.ranges do
		local line = buffer:line_of(range.head)
		for _ = 1, ctx.count or 1 do
			local next = line + delta
			while next >= 0 and next <= last and folded(next) do
				next += delta
			end
			if next < 0 or next > last then
				break
			end
			line = next
		end
		local head = if line == buffer:line_of(range.head)
			then range.head
			else text.at_drawn_column(buffer, line, columns[i], view)
		sel.ranges[i] = if extend
			then { anchor = range.anchor, head = head }
			else { anchor = head, head = head }
	end
	view:set_selection(sel)
	selection.remember(view)
	goals[view:id()] = { selection = view:selection(), columns = columns }
end

for _, down in { true, false } do
	pair(if down then "line-down" else "line-up", function(ctx, shift)
		vertical(ctx, if down then 1 else -1, shift)
	end)
end

local WRAPPED: { [string]: string } = {
	["page-down"] = "page-down",
	["page-up"] = "page-up",
	["doc-start"] = "goto-start",
	["doc-end"] = "goto-end",
}

for name, command in WRAPPED do
	pair(name, function(ctx, shift)
		if MOVES[name] then
			selection.wrap_move(ctx, command, shift)
		else
			selection.wrap(ctx, command, shift)
		end
	end)
end

return M
