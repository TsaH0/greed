-- Motions. Each has a plain command (`flash-word-next`), which moves or,
-- with the selection active, extends it, and a selecting one
-- (`flash-select-word-next`), bound with shift, which always extends.

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

-- The first non-blank of the line, or its start when already there.
local function smart_start(buffer: Buffer, head: number): number
	local start = buffer:line_start(buffer:line_of(head))
	local first = text.first_non_blank(buffer, start)
	return if head == first then start else first
end

local function line_end(buffer: Buffer, head: number): number
	return buffer:line_end(buffer:line_of(head))
end

--- The motions that move each head by a function of the text.
M.targets = {
	["char-left"] = function(buffer: Buffer, head: number): number
		return text.step(buffer, head, -1)
	end,
	["char-right"] = function(buffer: Buffer, head: number): number
		return text.step(buffer, head, 1)
	end,
	["word-next"] = text.next_word_start,
	["word-prev"] = text.prev_word_start,
	["word-end"] = text.word_end,
	["word-end-prev"] = M.prev_word_end,
	["line-start"] = smart_start,
	["line-end"] = line_end,
} :: { [string]: (Buffer, number) -> number }

local DOCS: { [string]: string } = {
	["char-left"] = "a character left",
	["char-right"] = "a character right",
	["word-next"] = "to the start of the next word",
	["word-prev"] = "to the start of the previous word",
	["word-end"] = "to the end of the word",
	["word-end-prev"] = "to the end of the previous word",
	["line-start"] = "to the first non-blank of the line, or its start",
	["line-end"] = "to the end of the line",
	["line-down"] = "a line down",
	["line-up"] = "a line up",
	["page-down"] = "a page down",
	["page-up"] = "a page up",
	["doc-start"] = "to the start of the buffer",
	["doc-end"] = "to the end of the buffer",
}

-- Defines `flash-NAME` and `flash-select-NAME` running `run(ctx, shift)`.
local function pair(name: string, run: (ctx: greed.Context, shift: boolean) -> ())
	for _, shift in { false, true } do
		greed.command({
			name = if shift then `flash-select-{name}` else `flash-{name}`,
			doc = if shift
				then `Select {DOCS[name]}, extending the selection`
				else `Move {DOCS[name]}, extending the selection when one is active`,
			run = function(ctx)
				run(ctx, shift)
			end,
		})
	end
end

for name, target in M.targets do
	pair(name, function(ctx, shift)
		selection.move(ctx, target, shift)
	end)
end

-- Up and down keep the column they started from: core's commands do that,
-- and extend-up and extend-down keep the anchor themselves.
for _, down in { true, false } do
	pair(if down then "line-down" else "line-up", function(ctx, shift)
		local extend = selection.active(ctx.view, shift)
		local verb = if extend then "extend-" else "move-"
		greed.run(verb .. (if down then "down" else "up"), { count = ctx.count })
		if extend then
			selection.remember(ctx.view)
		else
			selection.forget(ctx.view)
		end
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
		selection.wrap(ctx, command, shift)
	end)
end

return M
