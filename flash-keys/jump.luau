-- The character jump: ctrl-m, then the character to go to, then the label
-- shown on the occurrence you want. Only what's on screen is labelled,
-- nearest first, one letter each while they last and two after that.
-- esc or alt-m while choosing cancels; afterwards alt-m goes back to where
-- the last jump started.

local greed = require("@greed")
local find = require("./find")
local selection = require("./selection")

local M = {}

export type Target = { pos: number, label: string }

-- Where each view was before its last jump.
local before: { [number]: greed.Selection } = {}

local function alphabet(): { string }
	local out = {}
	for _, code in utf8.codes(greed.option.get("jump-label-alphabet") :: string) do
		table.insert(out, utf8.char(code))
	end
	return out
end

-- `char` as a regex matching itself.
local function literal(char: string): string
	if string.match(char, "^[%w%s]$") or #char > 1 then
		return char
	end
	return "\\" .. char
end

--- The places `char` is in what `view` shows, nearest `head` first, each
--- labelled.
function M.targets(view: greed.View, head: number, char: string): { Target }
	local from, to = view:visible()
	local found = view:buffer():find_all(literal(char), from, to) or {}
	table.sort(found, function(a, b)
		local da, db = math.abs(a.from - head), math.abs(b.from - head)
		return da < db or (da == db and a.from < b.from)
	end)
	local letters = alphabet()
	local two = #found > #letters
	local out = {}
	for i, match in found do
		local label
		if two then
			local first, second = (i - 1) // #letters + 1, (i - 1) % #letters + 1
			if first > #letters then
				break
			end
			label = letters[first] .. letters[second]
		else
			label = letters[i]
		end
		table.insert(out, { pos = match.from, label = label })
	end
	return out
end

local NS = "flash-keys-jump"

local function show(buffer: greed.Buffer, targets: { Target }, typed: string)
	local marks = {}
	for _, target in targets do
		if string.sub(target.label, 1, #typed) == typed then
			table.insert(marks, {
				from = target.pos,
				to = buffer:next_char(target.pos),
				text = string.sub(target.label, #typed + 1),
				overlay = true,
				style = "ui.jump.label",
			})
		end
	end
	buffer:decorate(NS, marks)
end

-- Reads a label; nil when cancelled or no label matches.
local function choose(buffer: greed.Buffer, targets: { Target }): number?
	local typed = ""
	while true do
		show(buffer, targets, typed)
		local key = greed.next_key()
		if key == "esc" or key == "alt-m" or utf8.len(key) ~= 1 then
			return nil
		end
		typed ..= key
		local left = 0
		for _, target in targets do
			if target.label == typed then
				return target.pos
			elseif string.sub(target.label, 1, #typed) == typed then
				left += 1
			end
		end
		if left == 0 then
			return nil
		end
	end
end

for _, shift in { false, true } do
greed.command({
	name = if shift then "flash-select-jump" else "flash-jump",
	doc = if shift
		then "Extend the selection to a character on screen: type it, then its label"
		else "Jump to a character on screen: type it, then the label on the one to go to",
	run = function(ctx)
		local char = find.char_of(greed.next_key())
		if char == nil then
			return
		end
		local view, buffer = ctx.view, ctx.buffer
		local targets = M.targets(view, view:cursor(), char)
		if #targets == 0 then
			greed.echo(`no {char} on screen`)
			return
		end
		local ok, pos = pcall(choose, buffer, targets)
		buffer:decorate(NS, {})
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
		if extend then
			selection.remember(view)
		else
			selection.forget(view)
		end
	end,
})
end

greed.command({
	name = "flash-jump-back",
	doc = "Go back to where the last character jump started",
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
