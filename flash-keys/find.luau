-- Vim's f, F, t and T on the cursor's line, for a cursor between
-- characters:
--
--   ctrl-f x   forward through the next x (the cursor ends after it)
--   alt-f x    back to the previous x (the cursor ends before it)
--   ctrl-; x   forward up to just before the next x
--   alt-; x    back to just after the previous x
--   ctrl-.     the last of these again, the same way
--   alt-.      the last of these again, the other way
--
-- A till skips the character right beside the cursor, so repeating it
-- moves on to the next one rather than staying put. The character is taken
-- literally, punctuation and all.

local greed = require("@greed")
local selection = require("./selection")

type Buffer = greed.Buffer

local M = {}

export type Find = { char: string, forward: boolean, till: boolean }

--- The last find, for ctrl-. and alt-. to repeat.
M.last = nil :: Find?

--- Where a find for `char` from `head` lands on `head`'s line, or nil.
function M.target(buffer: Buffer, head: number, find: Find): number?
	local line = buffer:line_of(head)
	local start, stop = buffer:line_start(line), buffer:line_end(line)
	if find.forward then
		local at = head
		if find.till and at < stop then
			at = buffer:next_char(at)
		end
		while at < stop do
			if buffer:char_at(at) == find.char then
				return if find.till then at else buffer:next_char(at)
			end
			at = buffer:next_char(at)
		end
		return nil
	end
	local at = head
	if find.till and at > start then
		at = buffer:prev_char(at)
	end
	while at > start do
		local before = buffer:prev_char(at)
		if buffer:char_at(before) == find.char then
			return if find.till then at else before
		end
		at = before
	end
	return nil
end

--- The character a key types, or nil for one that types none (esc).
function M.char_of(key: string): string?
	if key == "space" then
		return " "
	elseif key == "tab" then
		return "\t"
	elseif utf8.len(key) == 1 then
		return key
	end
	return nil
end

local function run(ctx: greed.Context, find: Find, shift: boolean?)
	selection.move(ctx, function(buffer, head)
		return M.target(buffer, head, find)
	end, shift)
end

for _, spec in
	{
		{ "find-next", true, false, "through the next" },
		{ "find-prev", false, false, "back to the previous" },
		{ "till-next", true, true, "up to just before the next" },
		{ "till-prev", false, true, "back to just after the previous" },
	}
do
	local name, forward, till, what = spec[1], spec[2], spec[3], spec[4]
	for _, shift in { false, true } do
		greed.command({
			name = if shift then `flash-select-{name}` else `flash-{name}`,
			doc = if shift
				then `Select {what} character typed, on this line`
				else `Move {what} character typed, on this line, extending an active selection`,
			run = function(ctx)
				local char = M.char_of(greed.next_key())
				if char == nil then
					return
				end
				local find = { char = char, forward = forward, till = till }
				M.last = find
				run(ctx, find, shift)
			end,
		})
	end
end

for _, reverse in { false, true } do
	greed.command({
		name = if reverse then "flash-find-reverse" else "flash-find-repeat",
		doc = if reverse
			then "Do the last character find again, the other way"
			else "Do the last character find again, the same way",
		run = function(ctx)
			local last = M.last
			if last == nil then
				return
			end
			run(ctx, {
				char = last.char,
				forward = if reverse then not last.forward else last.forward,
				till = last.till,
			})
		end,
	})
end

return M
