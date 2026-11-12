-- Jumping as flash.nvim does it: ctrl-enter, then type what you're looking for,
-- a character or as many as it takes. Every match on screen lights up, the
-- rest dims, and each match gets a label just after it, nearest first. Type
-- the label to jump there; keep typing to narrow the matches.
--
-- Labels never use a letter that could carry a match on (the character
-- right after any match), so a key is always one or the other: a label, or
-- more of the search. A match keeps its label as you type more. Lower case
-- finds any case; a capital makes the search match case exactly.
--
--   enter       jump to the nearest match
--   backspace   take back the last character typed (on none, cancel)
--   esc, alt-enter  cancel
--
-- It's on ctrl-enter (and C-g j). Afterwards alt-enter goes back to where
-- the jump started; ctrl-shift-enter jumps extending the selection.

local greed = require("@greed")
local find = require("./find")
local selection = require("./selection")

local M = {}

export type Target = { from: number, to: number, label: string? }

-- Where each view was before its last jump.
local before: { [number]: greed.Selection } = {}

local NS = "flash-keys-jump"

local function alphabet(): { string }
	local out = {}
	for _, code in utf8.codes(greed.option.get("jump-label-alphabet") :: string) do
		table.insert(out, utf8.char(code))
	end
	return out
end

-- The characters a regex gives meaning to, which `literal` escapes.
local META = "[%\\%.%+%*%?%(%)%|%[%]%{%}%^%$%#%&%-%~]"

--- `text` as a regex that finds it: escaped, and ignoring case unless it
--- has a capital (smart case).
function M.literal(text: string): string
	local escaped = string.gsub(text, META, "\\%0")
	if string.lower(text) == text then
		return "(?i)" .. escaped
	end
	return escaped
end

--- The matches of `text` in what `view` shows, nearest `head` first, each
--- labelled when there's a label for it. `previous` (a match's start to
--- its label) keeps labels where they were as the search grows.
function M.targets(
	view: greed.View,
	head: number,
	text: string,
	previous: { [number]: string }?
): { Target }
	if text == "" then
		return {}
	end
	local buffer = view:buffer()
	local from, to = view:visible()
	local found: { Target } = {}
	for _, match in buffer:find_all(M.literal(text), from, to) or {} do
		if match.to > match.from then
			table.insert(found, { from = match.from, to = match.to })
		end
	end
	table.sort(found, function(a, b)
		local da, db = math.abs(a.from - head), math.abs(b.from - head)
		return da < db or (da == db and a.from < b.from)
	end)
	-- A letter that comes right after a match would carry the search on,
	-- so it can't be a label.
	local taken: { [string]: boolean } = {}
	for _, target in found do
		local after = buffer:char_at(target.to)
		if after then
			taken[string.lower(after)] = true
		end
	end
	local free: { string } = {}
	local usable: { [string]: boolean } = {}
	for _, letter in alphabet() do
		if not taken[string.lower(letter)] then
			table.insert(free, letter)
			usable[letter] = true
		end
	end
	local used: { [string]: boolean } = {}
	for _, target in found do
		local kept = previous and previous[target.from]
		if kept and usable[kept] and not used[kept] then
			target.label = kept
			used[kept] = true
		end
	end
	local next = 1
	for _, target in found do
		if target.label == nil then
			while next <= #free and used[free[next]] do
				next += 1
			end
			if next > #free then
				break
			end
			target.label = free[next]
			used[free[next]] = true
		end
	end
	return found
end

-- Dims what's on screen and lights up the matches and their labels.
local function show(view: greed.View, targets: { Target }, searching: boolean)
	local buffer = view:buffer()
	local from, to = view:visible()
	local marks: { greed.Mark } = {}
	if searching then
		table.insert(marks, { from = from, to = to, style = "comment" })
	end
	for _, target in targets do
		table.insert(marks, { from = target.from, to = target.to, style = "ui.search.match" })
		if target.label then
			local stop = if target.to < buffer:len() then buffer:next_char(target.to) else target.to
			table.insert(marks, {
				from = target.to,
				to = stop,
				text = target.label,
				overlay = true,
				above = true,
				style = "ui.jump.label",
			})
		end
	end
	buffer:decorate(NS, marks)
end

-- Reads the search and a label; the place to jump to, or nil when
-- cancelled.
local function choose(view: greed.View): number?
	local head = view:cursor()
	local text = ""
	local targets: { Target } = {}
	while true do
		show(view, targets, true)
		local key = greed.next_key()
		if key == "esc" or key == "alt-enter" or key == "alt-m" then
			return nil
		elseif key == "enter" then
			return if targets[1] then targets[1].from else nil
		elseif key == "backspace" then
			if text == "" then
				return nil
			end
			text = string.sub(text, 1, (utf8.offset(text, -1) or 1) - 1)
		else
			local char = find.char_of(key)
			if char == nil then
				return nil
			end
			for _, target in targets do
				if target.label == char then
					return target.from
				end
			end
			text ..= char
		end
		local labels: { [number]: string } = {}
		for _, target in targets do
			if target.label then
				labels[target.from] = target.label
			end
		end
		targets = M.targets(view, head, text, labels)
	end
end

for _, shift in { false, true } do
	greed.command({
		name = if shift then "flash-select-jump" else "flash-jump",
		doc = if shift
			then "Search what's on screen as you type and extend the selection to the label typed"
			else "Search what's on screen as you type, and jump to the label typed (as flash.nvim)",
		run = function(ctx)
			local view = ctx.view
			local ok, pos = pcall(choose, view)
			view:buffer():decorate(NS, {})
			if not ok then
				error(pos, 0)
			end
			if pos == nil then
				return
			end
			before[view:id()] = view:selection()
			local extend = selection.active(view, shift)
			local sel = view:selection()
			local primary = sel.ranges[sel.primary]
			local anchor = if extend then primary.anchor else pos
			view:set_selection({ ranges = { { anchor = anchor, head = pos } }, primary = 1 })
			selection.remember(view)
		end,
	})
end

greed.command({
	name = "flash-jump-back",
	doc = "Go back to where the last jump started",
	run = function(ctx)
		local was = before[ctx.view:id()]
		if was == nil then
			greed.echo("no jump to go back from")
			return
		end
		before[ctx.view:id()] = nil
		ctx.view:set_selection(was)
	end,
})

return M
