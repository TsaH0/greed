-- Surround on ctrl-m and alt-m, with the letters the text objects use:
-- ctrl-m then a pair's key wraps each selection in it (b parentheses, r
-- square brackets, c braces, a angle brackets, q double quotes, or the
-- bracket or quote itself); alt-m then a key takes the pair around each
-- cursor away (n the nearest of any kind), the nearest one when the
-- cursor is in none, as ctrl-t finds them. ctrl-m ctrl-s swaps a pair:
-- the old one's key, then the new one's.
--
-- With nothing selected, ctrl-m wraps the word at the cursor.

local greed = require("@greed")
local core = require("@core")
local edit = require("./edit")
local objects = require("./objects")
local selection = require("./selection")

local M = {}

--- What each key wraps in.
M.pairs = {
	b = { "(", ")" },
	r = { "[", "]" },
	c = { "{", "}" },
	a = { "<", ">" },
	q = { '"', '"' },
} :: { [string]: { string } }

for _, pair in { { "(", ")" }, { "[", "]" }, { "{", "}" }, { "<", ">" } } do
	M.pairs[pair[1]] = pair
	M.pairs[pair[2]] = pair
end
for _, quote in { '"', "'", "`" } do
	M.pairs[quote] = { quote, quote }
end

-- The text object letter that finds the pair for `key`.
local OBJECT: { [string]: string } = {
	b = "b",
	r = "r",
	c = "c",
	a = "a",
	q = "q",
	n = "n",
	["("] = "b",
	[")"] = "b",
	["["] = "r",
	["]"] = "r",
	["{"] = "c",
	["}"] = "c",
	["<"] = "a",
	[">"] = "a",
}

-- A key as the pair key it stands for: ctrl-b is b.
local function plain(key: string): string
	return string.match(key, "^ctrl%-(.)$") or string.match(key, "^alt%-(.)$") or key
end

--- Wraps each selection (or the word at each cursor) in `pair`, leaving
--- what's wrapped selected with its pair.
function M.add(ctx: greed.Context, pair: { string })
	local view, buffer = ctx.view, ctx.buffer
	local sel = view:selection()
	local spans: { { number } } = {}
	for i, range in sel.ranges do
		local from, to = core.text.span(range)
		if from == to then
			local a, b = edit.word_near(buffer, range.head)
			if a and b then
				from, to = a, b
			end
		end
		spans[i] = { from, to }
	end
	local open, close = pair[1], pair[2]
	buffer:edit(function(e)
		for _, span in spans do
			if span[1] == span[2] then
				e:insert(span[1], open .. close)
			else
				e:insert(span[2], close)
				e:insert(span[1], open)
			end
		end
	end)
	-- Each span moved by the pairs put in before it.
	local order = {}
	for i in spans do
		table.insert(order, i)
	end
	table.sort(order, function(x, y)
		return spans[x][1] < spans[y][1]
	end)
	local shift = 0
	for _, i in order do
		local from, to = spans[i][1], spans[i][2]
		sel.ranges[i] = {
			anchor = from + shift,
			head = to + shift + #open + #close,
		}
		shift += #open + #close
	end
	view:set_selection(sel)
	selection.remember(view)
end

-- The pair around each cursor for `key`: where it starts and ends, the
-- pair's characters included.
local function around_each(ctx: greed.Context, key: string): { { number } }
	local out = {}
	local letter = OBJECT[key]
	for _, range in ctx.view:selection().ranges do
		local from, to
		if letter then
			from, to = objects.range(ctx.buffer, range.head, letter, true)
		elseif key == "'" or key == "`" or key == '"' then
			from, to = core.textobjects.find(ctx.buffer, range.head, key, true)
		end
		if from and to and to - from >= 2 then
			table.insert(out, { from, to })
		end
	end
	return out
end

-- Replaces the first and last characters of each of `spans` with `open`
-- and `close` (empty to take them away), each pair once.
local function swap_ends(buffer: greed.Buffer, spans: { { number } }, open: string, close: string)
	local seen: { [number]: boolean } = {}
	buffer:edit(function(e)
		for _, span in spans do
			if not seen[span[1]] then
				seen[span[1]] = true
				e:replace(buffer:prev_char(span[2]), span[2], close)
				e:replace(span[1], buffer:next_char(span[1]), open)
			end
		end
	end)
end

--- Takes away the pair for `key` around each cursor.
function M.delete(ctx: greed.Context, key: string)
	local spans = around_each(ctx, key)
	if #spans == 0 then
		greed.echo("no pair to take away")
		return
	end
	swap_ends(ctx.buffer, spans, "", "")
	selection.remember(ctx.view)
end

--- Swaps the pair for `old` around each cursor for the pair `new`.
function M.replace(ctx: greed.Context, old: string, new: { string })
	local spans = around_each(ctx, old)
	if #spans == 0 then
		greed.echo("no pair to change")
		return
	end
	-- Each character swapped for one, so the selection stays as it was.
	local was = ctx.view:selection()
	swap_ends(ctx.buffer, spans, new[1], new[2])
	ctx.view:set_selection(was)
	selection.remember(ctx.view)
end

-- Each key that wraps, the name its command ends with, and what it wraps in.
local WRAPS: { { string } } = {
	{ "b", "b", "parentheses" },
	{ "r", "r", "square brackets" },
	{ "c", "c", "braces" },
	{ "a", "a", "angle brackets" },
	{ "q", "q", "double quotes" },
	{ "'", "single", "single quotes" },
	{ "`", "backtick", "backticks" },
}

for _, wrap in WRAPS do
	local key, id, name = wrap[1], wrap[2], wrap[3]
	greed.command({
		name = `flash-surround-{id}`,
		doc = `Wrap each selection (or the word at the cursor) in {name}`,
		run = function(ctx)
			M.add(ctx, M.pairs[key])
		end,
	})
end

for key, name in
	{
		b = "parentheses",
		r = "square brackets",
		c = "braces",
		a = "angle brackets",
		q = "quotes",
		n = "nearest pair",
	}
do
	greed.command({
		name = `flash-unsurround-{key}`,
		doc = `Take away the {name} around each cursor (or the nearest)`,
		run = function(ctx)
			M.delete(ctx, key)
		end,
	})
end

greed.command({
	name = "flash-surround-change",
	doc = "Swap the pair around each cursor: type the old pair's key (b r c a q n, "
		.. "or the bracket), then the new one's",
	run = function(ctx)
		local old = plain(greed.next_key())
		if OBJECT[old] == nil and M.pairs[old] == nil then
			return
		end
		local new = M.pairs[plain(greed.next_key())]
		if new == nil then
			return
		end
		M.replace(ctx, old, new)
	end,
})

return M
