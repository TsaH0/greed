-- The selection engine, selection first as in Helix and Kakoune. Each
-- range has an anchor and a head.
--
--   * A plain motion selects what it moves over: from where the cursor
--     was to where the motion lands. Pressed again, it selects the next
--     piece on its own (ctrl-w the next word, alt-a the next line).
--   * With shift, a motion keeps the anchor and moves the head, carrying
--     the selection on. Going back past the anchor shrinks it and then
--     grows it the other way.
--   * ctrl-space from a bare cursor starts selecting: motions extend from
--     there until it's pressed again. With a selection, ctrl-space (and
--     esc) stop selecting: each range collapses to its head.
--
-- Typing replaces whatever is selected, what a plain motion selected
-- included, and backspace and delete delete it. With the option
-- `flash-type-at-cursor` on, what a plain motion selected is "soft"
-- instead: typing, enter, backspace, delete and pasting drop it and go in
-- at the cursor, and only selections made on purpose (shift, text
-- objects, ctrl-s) are replaced.
--
-- Positions are between characters (the style's cursor is a bar).

local greed = require("@greed")

local M = {}

greed.option.define({
	name = "flash-type-at-cursor",
	doc = "In the flash style, typing after a plain motion goes in at the cursor "
		.. "rather than replacing what the motion selected",
	default = false,
})

-- Extend mode, by view and the buffer it shows: with it on, plain motions
-- extend as shifted ones do. ctrl-space from a bare cursor turns it on,
-- and again (or with any selection) turns it off.
local sticky: { [string]: boolean } = {}
-- The selection a plain motion left, by view and buffer.
local soft: { [string]: greed.Selection } = {}

local function key(view: greed.View): string
	return `{view:id()}:{view:buffer():id()}`
end

local function same(a: greed.Selection, b: greed.Selection?): boolean
	if b == nil or #a.ranges ~= #b.ranges then
		return false
	end
	for i, r in a.ranges do
		if r.anchor ~= b.ranges[i].anchor or r.head ~= b.ranges[i].head then
			return false
		end
	end
	return true
end

M.same = same

--- Whether persistent selection is on in `view`.
function M.sticky(view: greed.View): boolean
	return sticky[key(view)] == true
end

--- Turns persistent selection on or off in `view`.
function M.set_sticky(view: greed.View, on: boolean)
	sticky[key(view)] = if on then true else nil
end

--- Whether a motion in `view` extends the selection, keeping its anchor:
--- with shift, or while persistent selection is on.
function M.active(view: greed.View, shift: boolean?, _strict: boolean?): boolean
	return shift == true or sticky[key(view)] == true
end

--- Notes that `view`'s selection is one a plain motion made, which typing
--- drops rather than replaces.
function M.soften(view: greed.View)
	soft[key(view)] = view:selection()
end

--- Whether `view`'s selection is still the one a plain motion made.
function M.is_soft(view: greed.View): boolean
	return same(view:selection(), soft[key(view)])
end

--- Notes that `view`'s selection was made on purpose (shift, a text
--- object), so typing replaces it.
function M.remember(view: greed.View)
	soft[key(view)] = nil
end

M.forget = M.remember

--- For a jump somewhere (a mark, a line, a label): each head goes to
--- `heads[i]`, extending when `extend`, and otherwise leaving a cursor.
function M.place(view: greed.View, heads: { number }, extend: boolean)
	local selection = view:selection()
	for i, range in selection.ranges do
		local head = heads[i] or range.head
		selection.ranges[i] = if extend
			then { anchor = range.anchor, head = head }
			else { anchor = head, head = head }
	end
	view:set_selection(selection)
	M.remember(view)
end

--- Where a motion takes a head: the new head, and for a motion that picks
--- out a piece of its own (the next word, the next line), where that piece
--- starts. Nil leaves the range as it is.
export type Target = (buffer: greed.Buffer, head: number) -> (number?, number?)

--- Runs a motion on each range (count times): with shift (or persistent
--- selection) the head moves and the anchor stays; otherwise each range
--- becomes what the motion went over, from its head or the start of the
--- piece the motion picked out.
function M.move(ctx: greed.Context, target: Target, shift: boolean?)
	local view = ctx.view
	local extend = M.active(view, shift)
	local selection = view:selection()
	for i, range in selection.ranges do
		local head, start = range.head, nil
		for step = 1, ctx.count or 1 do
			local to, from = target(ctx.buffer, head)
			if to == nil then
				break
			end
			if step == 1 then
				start = from
			end
			head = to
		end
		selection.ranges[i] = if extend
			then { anchor = range.anchor, head = head }
			else { anchor = start or range.head, head = head }
	end
	view:set_selection(selection)
	if extend then
		M.remember(view)
	else
		M.soften(view)
	end
end

--- For a jump somewhere: moves each head with `target`, extending with
--- shift or persistent selection, and otherwise leaving a cursor there.
function M.teleport(ctx: greed.Context, target: Target, shift: boolean?)
	local heads = {}
	for i, range in ctx.view:selection().ranges do
		heads[i] = target(ctx.buffer, range.head) or range.head
	end
	M.place(ctx.view, heads, M.active(ctx.view, shift))
end

--- Runs `command`, one of Greed's that moves the cursors, as a motion: with
--- shift each anchor stays, and otherwise each range becomes what the
--- command moved over. With `keep`, what the command selected stays as it
--- is when not extending, as a search's match.
function M.wrap(ctx: greed.Context, command: string, shift: boolean?, keep: boolean?)
	local view = ctx.view
	local extend = M.active(view, shift)
	local before = view:selection()
	greed.run(command, { count = ctx.count })
	-- A jump to another file or pane leaves this view's selection alone.
	if greed.view():id() ~= view:id() or view:buffer():id() ~= ctx.buffer:id() then
		return
	end
	local after = view:selection()
	if #after.ranges ~= #before.ranges then
		M.remember(view)
		return
	end
	if extend then
		for i, range in after.ranges do
			after.ranges[i] = { anchor = before.ranges[i].anchor, head = range.head }
		end
		view:set_selection(after)
		M.remember(view)
	elseif keep then
		M.remember(view)
	else
		for i, range in after.ranges do
			after.ranges[i] = { anchor = before.ranges[i].head, head = range.head }
		end
		view:set_selection(after)
		M.soften(view)
	end
end

--- Runs `command`, one of Greed's that moves the cursors, as a move only:
--- with shift (or while selecting) each anchor stays; otherwise each range
--- becomes a cursor where the command left it.
function M.wrap_move(ctx: greed.Context, command: string, shift: boolean?)
	local view = ctx.view
	local extend = M.active(view, shift)
	local before = view:selection()
	greed.run(command, { count = ctx.count })
	if greed.view():id() ~= view:id() or view:buffer():id() ~= ctx.buffer:id() then
		return
	end
	local after = view:selection()
	for i, range in after.ranges do
		local anchor = if extend and before.ranges[i] then before.ranges[i].anchor else range.head
		after.ranges[i] = { anchor = anchor, head = range.head }
	end
	view:set_selection(after)
	M.remember(view)
end

--- Collapses every range onto its anchor (`to_anchor`) or its head, and
--- turns persistent selection off.
function M.collapse(view: greed.View, to_anchor: boolean)
	local selection = view:selection()
	for i, range in selection.ranges do
		local at = if to_anchor then range.anchor else range.head
		selection.ranges[i] = { anchor = at, head = at }
	end
	view:set_selection(selection)
	M.set_sticky(view, false)
	M.remember(view)
end

greed.command({
	name = "flash-toggle-selection",
	doc = "Extend mode: plain motions carry the selection on as shifted ones do, "
		.. "until ctrl-space; again, turn it off and collapse to the cursor",
	run = function(ctx)
		if M.sticky(ctx.view) then
			M.collapse(ctx.view, false)
			greed.echo("Selection off")
		else
			M.set_sticky(ctx.view, true)
			greed.echo("Selection on")
		end
	end,
})

greed.command({
	name = "flash-collapse-anchor",
	doc = "Collapse each selection to its anchor, and turn persistent selection off",
	run = function(ctx)
		M.collapse(ctx.view, true)
	end,
})

greed.command({
	name = "flash-collapse-head",
	doc = "Collapse each selection to its moving end, and turn persistent selection off",
	run = function(ctx)
		M.collapse(ctx.view, false)
	end,
})

greed.command({
	name = "flash-space",
	doc = "Start selecting from the cursor, so motions extend until pressed again; "
		.. "with a selection, stop selecting and collapse to the cursor",
	run = function(ctx)
		local view = ctx.view
		local selecting = M.sticky(view)
		for _, range in view:selection().ranges do
			if range.anchor ~= range.head then
				selecting = true
			end
		end
		if selecting then
			M.collapse(view, false)
		else
			M.set_sticky(view, true)
			greed.echo("Selecting")
		end
	end,
})

greed.command({
	name = "flash-stop-selection",
	doc = "Stop selecting: collapse each selection to its cursor",
	run = function(ctx)
		M.collapse(ctx.view, false)
	end,
})

greed.command({
	name = "flash-escape",
	doc = "Drop the selection and turn persistent selection off",
	run = function(ctx)
		M.collapse(ctx.view, false)
	end,
})

-- Editing ends persistent selection, as typing does Emacs's mark.
local EDITS = {
	["delete-back"] = true,
	["delete-forward"] = true,
	["type-char"] = true,
	["type-newline"] = true,
	["type-tab"] = true,
	["erase-back"] = true,
	["erase-forward"] = true,
	["paste-over"] = true,
	["cut"] = true,
	["cut-or-line"] = true,
}

-- What typing does to a soft selection: drops it, so the text goes in at
-- the cursor rather than over what a motion went across.
local TYPING = {
	-- backspace and delete, through the typing role.
	["delete-back"] = true,
	["delete-forward"] = true,
	["type-char"] = true,
	["type-newline"] = true,
	["type-tab"] = true,
	["erase-back"] = true,
	["erase-forward"] = true,
	["paste-over"] = true,
}

greed.on("command.run", function(event: greed.CommandRun)
	if greed.mode.get() ~= "flash" then
		return
	end
	local view = greed.view()
	if
		TYPING[event.name]
		and greed.option.get("flash-type-at-cursor") == true
		and M.is_soft(view)
	then
		local selection = view:selection()
		for i, range in selection.ranges do
			selection.ranges[i] = { anchor = range.head, head = range.head }
		end
		view:set_selection(selection)
		M.remember(view)
	end
	if EDITS[event.name] and sticky[key(view)] then
		M.set_sticky(view, false)
	end
end)

return M
