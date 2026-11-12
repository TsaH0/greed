-- The selection engine. Each range has a fixed anchor and a head that
-- motions move. A motion extends the selection (keeps the anchor) when
-- the selection is active, and otherwise moves the cursor, leaving none.
--
-- The selection is active when any of these hold:
--   * the motion was pressed with shift (`ctrl-W`), which starts one;
--   * persistent selection is on (`ctrl-space`), as Emacs's mark;
--   * something is selected, as after a text object;
--   * the last thing to touch the selection was an extending motion, so a
--     head that came back onto its anchor keeps going past it.
--
-- Positions are between characters (the style's cursor is a bar), so a
-- range covers anchor..head whichever way round, and moving the head back
-- past the anchor shrinks the selection and then grows it the other way.

local greed = require("@greed")
local core = require("@core")

local M = {}

-- Persistent selection, by view and the buffer it shows: another buffer
-- in the view starts without it.
local sticky: { [string]: boolean } = {}
-- The selection an extending motion left, by view and buffer.
local made: { [string]: greed.Selection } = {}

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

--- Whether persistent selection is on in `view`.
function M.sticky(view: greed.View): boolean
	return sticky[key(view)] == true
end

--- Turns persistent selection on or off in `view`.
function M.set_sticky(view: greed.View, on: boolean)
	sticky[key(view)] = if on then true else nil
	if not on then
		made[key(view)] = nil
	end
end

--- Whether a motion in `view` extends the selection rather than moving.
--- With `strict`, as for searches, a selection only counts when motions
--- made it, so a search's own match doesn't make the next search extend.
function M.active(view: greed.View, shift: boolean?, strict: boolean?): boolean
	if shift or sticky[key(view)] then
		return true
	end
	local selection = view:selection()
	if same(selection, made[key(view)]) then
		return true
	end
	return not strict and core.text.anything_selected(selection)
end

--- Notes that `view`'s selection was made by extending, so the next motion
--- extends it too.
function M.remember(view: greed.View)
	made[key(view)] = view:selection()
end

function M.forget(view: greed.View)
	made[key(view)] = nil
end

--- Sets each range from `extend` (anchor kept) or as a cursor at the new
--- head, and remembers which.
function M.place(view: greed.View, heads: { number }, extend: boolean)
	local selection = view:selection()
	for i, range in selection.ranges do
		local head = heads[i] or range.head
		selection.ranges[i] = if extend
			then { anchor = range.anchor, head = head }
			else { anchor = head, head = head }
	end
	view:set_selection(selection)
	if extend then
		M.remember(view)
	else
		M.forget(view)
	end
end

--- Moves each head to `target(buffer, head)` (count times), extending when
--- the selection is active or `shift` is held.
function M.move(
	ctx: greed.Context,
	target: (buffer: greed.Buffer, head: number) -> number?,
	shift: boolean?
)
	local extend = M.active(ctx.view, shift)
	local heads = {}
	for i, range in ctx.view:selection().ranges do
		local head = range.head
		for _ = 1, ctx.count or 1 do
			head = target(ctx.buffer, head) or head
		end
		heads[i] = head
	end
	M.place(ctx.view, heads, extend)
end

--- Runs `command`, one of Greed's that moves the cursors, then keeps each
--- anchor when extending, or leaves a cursor at each head when not (unless
--- `keep` says to leave what the command selected, as a search's match,
--- and to extend only as `active`'s `strict` says).
function M.wrap(ctx: greed.Context, command: string, shift: boolean?, keep: boolean?)
	local view = ctx.view
	local extend = M.active(view, shift, keep)
	local before = view:selection()
	greed.run(command, { count = ctx.count })
	-- A jump to another file or pane leaves this view's selection alone.
	if greed.view():id() ~= view:id() or view:buffer():id() ~= ctx.buffer:id() then
		return
	end
	local after = view:selection()
	if extend and #after.ranges == #before.ranges then
		for i, range in after.ranges do
			after.ranges[i] = { anchor = before.ranges[i].anchor, head = range.head }
		end
		view:set_selection(after)
		M.remember(view)
	elseif not extend and not keep then
		local heads = {}
		for i, range in after.ranges do
			heads[i] = range.head
		end
		M.place(view, heads, false)
	end
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
end

greed.command({
	name = "flash-toggle-selection",
	doc = "Turn persistent selection on, so motions select; "
		.. "again, turn it off and collapse to the cursor",
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
	name = "flash-escape",
	doc = "Drop the selection and turn persistent selection off",
	run = function(ctx)
		M.collapse(ctx.view, false)
	end,
})

-- Editing ends persistent selection, as typing does Emacs's mark.
local EDITS = {
	["type-char"] = true,
	["type-newline"] = true,
	["type-tab"] = true,
	["erase-back"] = true,
	["erase-forward"] = true,
	["paste-over"] = true,
	["cut"] = true,
	["cut-or-line"] = true,
}

greed.on("command.run", function(event: greed.CommandRun)
	if EDITS[event.name] and greed.mode.get() == "flash" then
		local view = greed.view()
		if sticky[key(view)] then
			M.set_sticky(view, false)
		end
	end
end)

return M
