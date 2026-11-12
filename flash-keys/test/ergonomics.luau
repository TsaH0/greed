local greed = require("@greed")
local test = require("@greed/test")

-- | is a range's head, ^ its anchor.
local function check(t: test.TestContext, before: string, keys: string, after: string)
	t:buffer(before)
	greed.mode.set("flash")
	t:keys(keys)
	t:expect(after)
end

local function rust(t: test.TestContext, before: string)
	t:buffer(before)
	greed.view():buffer():set_language("rust")
	greed.mode.set("flash")
end

-- Moving lines

test("ctrl-u moves the cursor's line up, alt-u down, the cursor with it", function(t)
	check(t, "a\nb|c\nd", "ctrl-u", "b|c\na\nd")
	check(t, "a\nb|c\nd", "alt-u", "a\nd\nb|c")
end)

test("moving lines keeps a multiline selection's shape", function(t)
	check(t, "x\na^b\nc|d\ny", "ctrl-u", "a^b\nc|d\nx\ny")
	check(t, "x\na^b\nc|d\ny", "alt-u", "x\ny\na^b\nc|d")
end)

test("moving lines moves every cursor's line", function(t)
	check(t, "a\n|b\nc\n|d", "ctrl-u", "|b\na\n|d\nc")
	check(t, "|a\nb\n|c\nd", "alt-u", "b\n|a\nd\n|c")
	-- Cursors on lines next to each other move as one block.
	check(t, "|a\n|b\nc", "alt-u", "c\n|a\n|b")
end)

test("a line move is one step to undo, and stops at the buffer's ends", function(t)
	check(t, "a\nb|\nc", "ctrl-u ctrl-u ctrl-z", "a\nb|\nc")
	check(t, "a|\nb", "ctrl-u", "a|\nb")
	check(t, "a\nb|", "alt-u", "a\nb|")
end)

-- Duplicating lines

test("ctrl-D duplicates the lines below and alt-D above, the cursor going with the copy", function(t)
	check(t, "a\nb|c\nd", "ctrl-D", "a\nbc\nb|c\nd")
	check(t, "a\nb|c\nd", "alt-D", "a\nb|c\nbc\nd")
end)

test("duplicating keeps the selected text and its shape", function(t)
	check(t, "a^b\nc|d\ne", "ctrl-D", "ab\ncd\na^b\nc|d\ne")
	check(t, "a^b\nc|d\ne", "alt-D", "a^b\nc|d\nab\ncd\ne")
end)

test("duplicating copies every cursor's line, and is one step to undo", function(t)
	-- Cursors on lines next to each other duplicate as one block.
	check(t, "|a\n|b", "ctrl-D", "a\nb\n|a\n|b")
	check(t, "|a\nx\n|b", "ctrl-D", "a\n|a\nx\nb\n|b")
	check(t, "|a\n|b", "ctrl-D ctrl-z", "|a\n|b")
end)

-- Copy, cut, paste

test("alt-c copies the selection and stops selecting", function(t)
	check(t, "|one two", "ctrl-W alt-c", "one |two")
	-- The next motion selects afresh rather than growing what was copied.
	t:keys("ctrl-w")
	t:expect("one ^two|")
	-- And pasting replaces what the motion selected.
	t:keys("ctrl-y")
	t:expect("one one |")
end)

test("alt-c copies what a plain motion selected", function(t)
	check(t, "|one two", "ctrl-w alt-c alt-a ctrl-space ctrl-y", "one twoone |")
end)

test("alt-c with nothing selected copies the line, whole lines pasting above", function(t)
	check(t, "a|b\ncd", "alt-c ctrl-j ctrl-space ctrl-y", "ab\nab\nc|d")
end)

test("alt-c copies every cursor's selection, one piece each", function(t)
	check(t, "^a| 1\n^b| 2", "alt-c", "a| 1\nb| 2")
	t:keys("alt-a ctrl-space ctrl-y")
	t:expect("a 1a|\nb 2b|")
end)

test("alt-C copies and keeps the selection, so shift carries it on", function(t)
	check(t, "|one two", "ctrl-W alt-C", "^one |two")
	t:keys("ctrl-W")
	t:expect("^one two|")
	t:keys("ctrl-space ctrl-y")
	t:expect("one twoone |")
end)

test("ctrl-X cuts the selection, or the line with nothing selected", function(t)
	check(t, "^ab| cd", "ctrl-X alt-a ctrl-space ctrl-y", " cdab|")
	check(t, "ab\nc|d\nef", "ctrl-X", "ab\n|ef")
	check(t, "ab\nc|d\nef", "ctrl-X ctrl-y", "ab\ncd\n|ef")
end)

test("C-c e y copies keeping the selection, C-c e c as alt-c does", function(t)
	check(t, "|ab", "ctrl-W ctrl-c e y", "^ab|")
	check(t, "|ab", "ctrl-W ctrl-c e c", "ab|")
end)

-- Comments

test("ctrl-\\ comments the lines, again uncomments them", function(t)
	rust(t, "a|b\ncd")
	t:keys("ctrl-\\")
	t:expect("// a|b\ncd")
	t:keys("ctrl-\\")
	t:expect("a|b\ncd")
end)

test("alt-\\ only ever uncomments, leaving lines without a comment alone", function(t)
	rust(t, "^// a\nb\n  // c|")
	t:keys("alt-\\")
	t:expect("^a\nb\n  c|")
	t:keys("alt-\\")
	t:expect("^a\nb\n  c|")
end)

-- Joining

test("ctrl-O joins the next line on, alt-O joins the line onto the one before", function(t)
	check(t, "a|b\n  cd", "ctrl-O", "a|b cd")
	check(t, "ab\n  c|d", "alt-O", "ab c|d")
	check(t, "a|b\ncd", "alt-O", "a|b\ncd")
end)

test("alt-O joins every cursor's line, as one step to undo", function(t)
	check(t, "a\nb|\nc\nd|", "alt-O", "a b|\nc d|")
	check(t, "a\nb|\nc\nd|", "alt-O ctrl-z", "a\nb|\nc\nd|")
end)

-- Repeat, pickers, rename

test("ctrl-, does the last edit again", function(t)
	check(t, "|a\nb", "x ctrl-j ctrl-a ctrl-space ctrl-,", "xa\nx|b")
end)

test("alt-x, ctrl-P and ctrl-B open the command, file and buffer pickers", function(t)
	for _, keys in { "alt-x", "ctrl-P", "ctrl-B" } do
		t:buffer("|abc")
		greed.mode.set("flash")
		t:keys(keys)
		assert(greed.view():buffer():kind() == "picker", keys)
		t:keys("esc")
		assert(greed.view():buffer():kind() ~= "picker", `{keys}: esc closes it`)
	end
end)

test("ctrl-R renames the symbol at the cursor", function(t)
	t:buffer("|abc")
	greed.mode.set("flash")
	assert(greed.keymap.resolve("ctrl-R") == "rename", tostring(greed.keymap.resolve("ctrl-R")))
end)

-- Surround

test("ctrl-T a, r and d add, replace and delete a surrounding pair", function(t)
	check(t, "a ^b| c", "ctrl-T a (", "a ^(b)| c")
	check(t, "a (b|) c", "ctrl-T r ( [", "a [b]| c")
	check(t, "a (b|) c", "ctrl-T d (", "a b| c")
	-- The longer keys stay.
	check(t, "a ^b| c", "ctrl-c e a (", "a ^(b)| c")
end)

-- What stays as it was

test("shifted motions still select", function(t)
	check(t, "a|bc", "ctrl-L ctrl-L", "a^bc|")
	check(t, "ab|c", "ctrl-H", "a|b^c")
	check(t, "ab|c\nxyz", "ctrl-J", "ab^c\nxy|z")
	check(t, "abc\nxy|z", "ctrl-K", "ab|c\nxy^z")
	check(t, "|one two", "ctrl-W", "^one |two")
	check(t, "one |two", "ctrl-E", "one ^two|")
end)

test("text objects and character finds are where they were", function(t)
	check(t, "x[a|b]y", "ctrl-t ctrl-b", "x[^ab|]y")
	check(t, "x[a|b]y", "alt-t alt-b", "x^[ab]|y")
	check(t, "|a,b,c", "ctrl-f ,", "^a,|b,c")
	check(t, "a,b,c|", "alt-f ,", "a,b|,c^")
	check(t, "|a,b,c", "ctrl-; ,", "^a|,b,c")
	check(t, "a,b,c|", "alt-; ,", "a,b,|c^")
	check(t, "|a,b,c", "ctrl-f , ctrl-.", "a,^b,|c")
end)

test("letters still type, shifted ones too", function(t)
	check(t, "|", "a X c U T O D", "aXcUTOD|")
end)

test("the new keys don't reach pickers, prompts or terminals", function(t)
	t:buffer("|abc")
	greed.mode.set("flash")
	t:keys("ctrl-x b")
	assert(greed.view():buffer():kind() == "picker", "picker")
	for _, keys in { "ctrl-u", "alt-u", "alt-c", "ctrl-D" } do
		local got = greed.keymap.resolve(keys)
		local flash = got ~= nil and (string.find(got, "^flash%-") ~= nil or got == "move-lines-up")
		assert(not flash, `picker {keys}: {got}`)
	end
	t:type("ab")
	assert(string.find(greed.view():buffer():text(), "ab", 1, true), "typed into the picker")
	t:keys("esc")
	t:keys("ctrl-g l")
	t:type("1")
	t:keys("enter")
	t:expect("|abc")
	t:run("terminal", { "cat" })
	t:wait_for(function()
		return greed.mode.get() == "terminal"
	end)
	for _, keys in { "alt-c", "ctrl-X", "ctrl-D", "ctrl-u", "ctrl-\\", "alt-x", "ctrl-," } do
		local got = greed.keymap.resolve(keys)
		assert(got == nil or not string.find(got, "^flash%-"), `terminal {keys}: {got}`)
	end
end)
