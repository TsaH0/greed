local greed = require("@greed")
local test = require("@greed/test")

-- | is a range's head, ^ its anchor.
local function check(t: test.TestContext, before: string, keys: string, after: string)
	t:buffer(before)
	greed.mode.set("flash")
	t:keys(keys)
	t:expect(after)
end

test("ctrl-w selects the next word, and again the word after it", function(t)
	check(t, "|one two three", "ctrl-w", "^one |two three")
	check(t, "|one two three", "ctrl-w ctrl-w", "one ^two |three")
	check(t, "|one two three", "ctrl-w ctrl-w ctrl-w", "one two ^three|")
	-- From just after a word, the next one.
	check(t, "one| two three", "ctrl-w", "one ^two |three")
end)

test("alt-w selects the word before, and again the one before that", function(t)
	check(t, "one two three|", "alt-w", "one two |three^")
	check(t, "one two three|", "alt-w alt-w", "one |two ^three")
end)

test("ctrl-e selects the next word without the blanks, alt-e back to a word's end", function(t)
	check(t, "|one two", "ctrl-e", "^one| two")
	check(t, "|one two", "ctrl-e ctrl-e", "one ^two|")
	check(t, "one two|", "alt-e", "one| two^")
end)

test("ctrl-h and ctrl-l only move, alt-h and alt-l the other way", function(t)
	check(t, "a|bc", "ctrl-l", "ab|c")
	check(t, "a|bc", "ctrl-l ctrl-l", "abc|")
	check(t, "ab|c", "ctrl-h", "a|bc")
	check(t, "a|bc", "alt-h", "ab|c")
	check(t, "ab|c", "alt-l", "a|bc")
end)

test("ctrl-h j k l drop a selection and move from its cursor", function(t)
	check(t, "|one two", "ctrl-w ctrl-l", "one t|wo")
	check(t, "^ab|c\nxyz", "ctrl-j", "abc\nxy|z")
	check(t, "|one two", "ctrl-W ctrl-h", "one| two")
end)

test("alt-a selects to the line's end, and again the next line", function(t)
	check(t, "a|bc\ndef\ngh", "alt-a", "a^bc|\ndef\ngh")
	check(t, "a|bc\ndef\ngh", "alt-a alt-a", "abc\n^def|\ngh")
	check(t, "a|bc\ndef\ngh", "alt-a alt-a alt-a", "abc\ndef\n^gh|")
end)

test("ctrl-a selects back to the first non-blank, the line's start, then the line before", function(t)
	check(t, "ab\n  cd|e", "ctrl-a", "ab\n  |cd^e")
	check(t, "ab\n  cd|e", "ctrl-a ctrl-a", "ab\n|  ^cde")
	check(t, "ab\n  cd|e", "ctrl-a ctrl-a ctrl-a", "|ab^\n  cde")
end)

test("ctrl-j and ctrl-k only move down and up, keeping the column", function(t)
	check(t, "ab|c\nd\nxyz", "ctrl-j", "abc\nd|\nxyz")
	check(t, "ab|c\nd\nxyz", "ctrl-j ctrl-j", "abc\nd\nxy|z")
	check(t, "abc\nxy|z", "ctrl-k", "ab|c\nxyz")
	check(t, "abc\nxy|z", "alt-j", "ab|c\nxyz")
	check(t, "ab|c\nxyz", "alt-k", "abc\nxy|z")
end)

test("shift carries the selection on, keeping its anchor", function(t)
	check(t, "|one two three", "ctrl-W ctrl-W", "^one two |three")
	check(t, "|one two three", "ctrl-w ctrl-W", "^one two |three")
	check(t, "a|bc\ndef\ngh", "alt-A alt-A", "a^bc\ndef|\ngh")
	check(t, "ab|c\nd\nxyz", "ctrl-J ctrl-J", "ab^c\nd\nxy|z")
	check(t, "|abc", "ctrl-L ctrl-L", "^ab|c")
end)

test("going back with shift shrinks the selection, then crosses the anchor", function(t)
	check(t, "ab|cd", "ctrl-L ctrl-L ctrl-H", "ab^c|d")
	check(t, "ab|cd", "ctrl-L ctrl-H ctrl-H", "a|b^cd")
	check(t, "|one two three", "ctrl-w ctrl-W alt-W", "^one |two three")
	check(t, "|one two three", "ctrl-w ctrl-W alt-W alt-W", "|one two three")
	check(t, "one |two three", "ctrl-w alt-W alt-W", "|one ^two three")
end)

test("ctrl-space stops selecting, collapsing to the cursor", function(t)
	check(t, "|one two", "ctrl-w ctrl-space", "one |two")
	check(t, "|one two", "ctrl-W ctrl-W ctrl-space", "one two|")
	check(t, "|one two", "ctrl-w esc", "one |two")
end)

test("C-x space makes plain motions extend until ctrl-space", function(t)
	check(t, "|one two three", "ctrl-x space ctrl-w ctrl-w", "^one two |three")
	check(t, "|one two three", "ctrl-x space ctrl-w ctrl-space ctrl-w", "one ^two |three")
end)

test("ctrl-space from a cursor starts selecting, and motions carry it on until pressed again", function(t)
	check(t, "ab|c\nd\nxyz", "ctrl-space ctrl-j ctrl-j", "ab^c\nd\nxy|z")
	check(t, "abc\nxy|z", "ctrl-space ctrl-k", "ab|c\nxy^z")
	check(t, "a|bcd", "ctrl-space ctrl-l ctrl-l alt-l", "a^b|cd")
	check(t, "|one two three", "ctrl-space ctrl-w ctrl-w", "^one two |three")
	check(t, "ab|c\nd\nxyz", "ctrl-space ctrl-j ctrl-j ctrl-space", "abc\nd\nxy|z")
	check(t, "ab|c\nd\nxyz", "ctrl-space ctrl-j ctrl-space ctrl-j", "abc\nd\nxy|z")
	-- With a selection showing, it stops it instead.
	check(t, "|one two", "ctrl-w ctrl-space ctrl-l", "one t|wo")
end)

test("shift-s collapses to the anchor, alt-shift-s to the head", function(t)
	check(t, "|one two three", "ctrl-W ctrl-W ctrl-S", "|one two three")
	check(t, "|one two three", "ctrl-W ctrl-W alt-S", "one two |three")
end)

test("typing replaces what a motion selected", function(t)
	check(t, "|one two", "ctrl-w x", "x|two")
	check(t, "|one two", "ctrl-e x", "x| two")
	check(t, "a|bc\ndef", "alt-a x y", "axy|\ndef")
	check(t, "|one two", "ctrl-f e X", "X| two")
	check(t, "|one two", "ctrl-w ctrl-w x", "one x|")
end)

test("backspace and delete delete what's selected, or a character", function(t)
	check(t, "|ab cd", "ctrl-w backspace", "|cd")
	check(t, "|ab cd", "ctrl-w delete", "|cd")
	check(t, "ab| cd", "backspace", "a| cd")
	check(t, "ab| cd", "delete", "ab|cd")
end)

test("enter and paste replace what's selected", function(t)
	check(t, "|ab cd", "ctrl-w enter", "\n|cd")
	check(t, "|ab cd", "ctrl-e alt-c ctrl-w ctrl-y", "ab ab|")
end)

test("with flash-type-at-cursor on, typing after a motion goes in at the cursor", function(t)
	greed.option.set("flash-type-at-cursor", true)
	check(t, "|one two", "ctrl-w x", "one x|two")
	check(t, "|ab cd", "ctrl-w backspace", "ab|cd")
	check(t, "|ab cd", "ctrl-w enter", "ab \n|cd")
	-- Selections made on purpose are still replaced.
	check(t, "|one two", "ctrl-W x", "x|two")
	greed.option.set("flash-type-at-cursor", false)
end)

test("typing replaces a selection made on purpose", function(t)
	check(t, "|one two", "ctrl-W x", "x|two")
	check(t, "|one two", "ctrl-w ctrl-W x", "x|")
	check(t, "a (b|c) d", "ctrl-t ctrl-r x", "a (x|) d")
end)

test("ctrl-d deletes what a motion selected, or a character", function(t)
	check(t, "|one two", "ctrl-w ctrl-d", "|two")
	check(t, "|one two", "ctrl-w ctrl-w ctrl-d", "one |")
	check(t, "a|bc", "ctrl-d", "a|c")
	check(t, "a|bc", "alt-d", "|bc")
	check(t, "one two|", "alt-w alt-d", "one |")
end)

test("plain keys type, punctuation and space included", function(t)
	check(t, "|", "h i space ; .", "hi ;.|")
	check(t, "a|", "enter b", "a\nb|")
end)

test("every cursor selects on its own", function(t)
	check(t, "|ab |cd", "ctrl-l", "a|b c|d")
	check(t, "|ab |cd", "ctrl-L", "^a|b ^c|d")
	check(t, "|ab cd |ef gh", "ctrl-w", "^ab |cd ^ef |gh")
	check(t, "|ab cd |ef gh", "ctrl-w ctrl-w", "ab ^cd |ef ^gh|")
end)

test("motions take multi-byte characters whole", function(t)
	check(t, "|éü ok", "ctrl-l", "é|ü ok")
	check(t, "|éü ok", "ctrl-L", "^é|ü ok")
	check(t, "|日本 語", "ctrl-w", "^日本 |語")
	check(t, "|日本 語", "ctrl-e", "^日本| 語")
end)

test("ctrl-v and alt-v only page down and up, shift and ctrl-space extending", function(t)
	local lines = {}
	for i = 1, 2000 do
		lines[i] = `line {i}`
	end
	local text = table.concat(lines, "\n")
	t:buffer("|" .. text)
	greed.mode.set("flash")
	t:keys("ctrl-v")
	local sel = greed.view():selection().ranges[1]
	assert(sel.head > 0 and sel.anchor == sel.head, `moved without selecting: {sel.anchor} {sel.head}`)
	t:keys("alt-v")
	sel = greed.view():selection().ranges[1]
	assert(sel.head == 0 and sel.anchor == 0, `back up: {sel.anchor} {sel.head}`)
	t:keys("ctrl-V")
	sel = greed.view():selection().ranges[1]
	assert(sel.anchor == 0 and sel.head > 0, "shift extends")
	t:keys("alt-S ctrl-g g ctrl-space ctrl-g g ctrl-space ctrl-v")
	local after = greed.view():selection().ranges[1]
	assert(after.anchor == 0 and after.head > 0, `ctrl-space extends: {after.anchor} {after.head}`)
	-- With a selection, it's dropped.
	t:buffer("|" .. text)
	greed.mode.set("flash")
	t:keys("ctrl-w ctrl-v")
	sel = greed.view():selection().ranges[1]
	assert(sel.anchor == sel.head, "dropped")
end)

test("page and document motions select from the cursor, shift extending", function(t)
	check(t, "a|b\ncd\nef", "alt-g g", "a^b\ncd\nef|")
	check(t, "ab\ncd\ne|f", "ctrl-g g", "|ab\ncd\ne^f")
	check(t, "ab\ncd\ne|f", "ctrl-w ctrl-g G", "|ab\ncd\ne^f")
end)

test("a motion with nowhere to go leaves the selection as it was", function(t)
	check(t, "ab|", "ctrl-l", "ab|")
	check(t, "ab|", "alt-a", "ab|")
	check(t, "|ab", "ctrl-a", "|ab")
end)
