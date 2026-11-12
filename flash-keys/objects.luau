-- Text objects: ctrl-t then a key selects inside an object around each
-- cursor, alt-t then a key around it. They select without turning on
-- persistent selection; what's selected is then extended by motions, or
-- replaced by typing.
--
-- The objects come from core.textobjects (brackets, quotes, words,
-- paragraphs, sentences, tags) and the syntax tree (functions, nodes).

local greed = require("@greed")
local core = require("@core")
local selection = require("./selection")

type Buffer = greed.Buffer

local M = {}

-- Selects from each head with `find(buffer, pos)`; a range with no object
-- around it is left as it was.
local function select_each(
	ctx: greed.Context,
	find: (buffer: Buffer, pos: number) -> (number?, number?)
)
	local sel = ctx.view:selection()
	local found = false
	for i, range in sel.ranges do
		local from, to = find(ctx.buffer, range.head)
		if from and to then
			sel.ranges[i] = { anchor = from, head = to }
			found = true
		end
	end
	if found then
		ctx.view:set_selection(sel)
		selection.remember(ctx.view)
	end
end

local QUOTES = { '"', "'", "`" }

-- The innermost quoted text around `pos`, of any kind of quote.
local function quotes(buffer: Buffer, pos: number, around: boolean): (number?, number?)
	local best_from: number?, best_to: number? = nil, nil
	for _, quote in QUOTES do
		local from, to = core.textobjects.find(buffer, pos, quote, around)
		if from and to and (best_from == nil or to - from < (best_to :: number) - best_from) then
			best_from, best_to = from, to
		end
	end
	return best_from, best_to
end

-- The line around `pos`: inside, its text without the indent and the line
-- break; around, the whole line with its line break.
local function line(buffer: Buffer, pos: number, around: boolean): (number, number)
	local n = buffer:line_of(pos)
	local start, stop = buffer:line_start(n), buffer:line_end(n)
	if around then
		return start, if n + 1 < buffer:line_count() then buffer:line_start(n + 1) else stop
	end
	return core.text.first_non_blank(buffer, start), stop
end

export type Object = {
	name: string,
	--- The key core.textobjects.find takes for it.
	key: string?,
	--- Or a function of its own.
	find: ((Buffer, number, boolean) -> (number?, number?))?,
	--- How to find one when the cursor isn't in one: the brackets or
	--- quotes whose next and last pairs to look at, "tag", or a syntax
	--- tree object ("function").
	seek: ({ string } | string)?,
}

-- A place inside the object that starts or ends nearest `pos` on each
-- side, for each way `seek` says to look: { pos inside, the key to find
-- it with }.
type Probe = { at: number, key: string }

local function probes(buffer: Buffer, pos: number, object: Object): { Probe }
	local out: { Probe } = {}
	local seek = object.seek
	if type(seek) == "table" then
		for _, char in seek do
			for _, back in { false, true } do
				local open = core.textobjects.next_pair(buffer, pos, char, back)
				if open then
					table.insert(out, { at = buffer:next_char(open), key = char })
				end
			end
		end
	elseif seek == "tag" then
		local after = buffer:find_all("<[A-Za-z]", pos) or {}
		if after[1] then
			table.insert(out, { at = after[1].to, key = "x" })
		end
		local before = buffer:find_all("<[A-Za-z]", 0, pos) or {}
		if #before > 0 then
			table.insert(out, { at = before[#before].to, key = "x" })
		end
	elseif type(seek) == "string" then
		local next: number?, last: number? = nil, nil
		for _, found in core.syntax.objects(buffer, seek) do
			local from, to = found.around.from, found.around.to
			if from > pos and (next == nil or from < next) then
				next = from
			elseif to <= pos and (last == nil or from > last) then
				last = from
			end
		end
		-- One character in: core's finder doesn't count the first.
		for _, at in { next, last } do
			if at then
				table.insert(out, { at = buffer:next_char(at), key = object.key :: string })
			end
		end
	end
	return out
end

--- With the cursor at `pos` in no `object`, the one to take, as Vim and
--- targets.vim do: the next one starting on the cursor's line, or else
--- the nearest, before or after. Nil when there's none.
function M.nearest(
	buffer: Buffer,
	pos: number,
	object: Object,
	around: boolean
): (number?, number?)
	local line = buffer:line_of(pos)
	local best_from: number?, best_to: number? = nil, nil
	local best_rank, best_distance = math.huge, math.huge
	for _, probe in probes(buffer, pos, object) do
		local from, to = core.textobjects.find(buffer, probe.at, probe.key, around)
		if from and to then
			local after = from >= pos
			local rank = if after and buffer:line_of(from) == line then 0 else 1
			local distance = if after then from - pos else pos - to
			if rank < best_rank or (rank == best_rank and distance < best_distance) then
				best_from, best_to, best_rank, best_distance = from, to, rank, distance
			end
		end
	end
	return best_from, best_to
end

--- The objects, by the key after ctrl-t or alt-t: a name for the docs and
--- the key core.textobjects.find takes, or a function of its own.
M.objects = {
	b = { name = "square brackets", key = "[", seek = { "[" } },
	a = { name = "angle brackets", key = "<", seek = { "<" } },
	r = { name = "parentheses", key = "(", seek = { "(" } },
	c = { name = "curly braces", key = "{", seek = { "{" } },
	n = { name = "nearest bracket pair", key = "m", seek = { "(", "[", "{", "<" } },
	q = { name = "quotes (any kind, innermost)", find = quotes, seek = { '"', "'", "`" } },
	w = { name = "word", key = "w" },
	p = { name = "paragraph", key = "p" },
	s = { name = "sentence", key = "s" },
	f = { name = "function", key = "f", seek = "function" },
	l = { name = "line", find = line },
	x = { name = "HTML or XML tag", key = "x", seek = "tag" },
} :: { [string]: Object }

for letter, object in M.objects do
	for _, around in { false, true } do
		local side = if around then "around" else "inside"
		greed.command({
			name = `flash-{side}-{letter}`,
			doc = `Select {side} the {object.name} around each cursor, `
				.. "or the nearest one when it's in none",
			run = function(ctx)
				select_each(ctx, function(buffer, pos)
					local from: number?, to: number?
					if object.find then
						from, to = object.find(buffer, pos, around)
					else
						from, to = core.textobjects.find(buffer, pos, object.key :: string, around)
					end
					if (from == nil or to == nil) and object.seek then
						from, to = M.nearest(buffer, pos, object, around)
					end
					return from, to
				end)
			end,
		})
	end
end

-- The syntax node: inside, the smallest one around each cursor; around,
-- the one around that.
for _, around in { false, true } do
	greed.command({
		name = if around then "flash-around-o" else "flash-inside-o",
		doc = if around
			then "Select the syntax node around the one at each cursor"
			else "Select the syntax node at each cursor",
		run = function(ctx)
			greed.run("expand-selection")
			if around then
				greed.run("expand-selection")
			end
			selection.remember(ctx.view)
		end,
	})
end

-- Growing and shrinking by the syntax tree, and moving to siblings, keep
-- motions extending what they leave.
for name, command in
	{
		["flash-expand"] = "expand-selection",
		["flash-shrink"] = "shrink-selection",
		["flash-sibling-next"] = "select-next-sibling",
		["flash-sibling-prev"] = "select-prev-sibling",
	}
do
	greed.command({
		name = name,
		doc = `{command}, then motions extend what it selected`,
		run = function(ctx)
			greed.run(command)
			selection.remember(ctx.view)
		end,
	})
end

return M
