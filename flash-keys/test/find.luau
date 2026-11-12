local greed = require("@greed")
local test = require("@greed/test")

local function check(t: test.TestContext, before: string, keys: string, after: string)
	t:buffer(before)
	greed.mode.set("flash")
	t:keys(keys)
	t:expect(after)
end

test("ctrl-f goes through the next character, alt-f back before the previous", function(t)
	check(t, "|a,b,c", "ctrl-f ,", "a,|b,c")
	check(t, "|a,b,c", "ctrl-f , ctrl-f ,", "a,b,|c")
	check(t, "a,b,c|", "alt-f ,", "a,b|,c")
	check(t, "a,b,c|", "alt-f , alt-f ,", "a|,b,c")
end)

test("ctrl-; stops just before the next character, alt-; just after the previous", function(t)
	check(t, "|a,b,c", "ctrl-; ,", "a|,b,c")
	check(t, "a,b,c|", "alt-; ,", "a,b,|c")
end)

test("a till pressed again moves on to the next one", function(t)
	check(t, "|a,b,c", "ctrl-; , ctrl-.", "a,b|,c")
	check(t, "a,b,c|", "alt-; , ctrl-.", "a,|b,c")
end)

test("ctrl-. repeats the last find the same way, alt-. the other way", function(t)
	check(t, "|a,b,c,d", "ctrl-f , ctrl-. ctrl-.", "a,b,c,|d")
	check(t, "|a,b,c,d", "ctrl-f , ctrl-f , alt-.", "a,b|,c,d")
	check(t, "a,b,c,d|", "alt-f , alt-.", "a,b,c,|d")
end)

test("a find stays on the cursor's line", function(t)
	check(t, "|abc\nx,y", "ctrl-f ,", "|abc\nx,y")
	check(t, "a,b\nc|d", "alt-f ,", "a,b\nc|d")
end)

test("the character is taken literally, punctuation and space too", function(t)
	check(t, "|a.b(c)", "ctrl-f .", "a.|b(c)")
	check(t, "|a.b(c)", "ctrl-f (", "a.b(|c)")
	check(t, "|a b", "ctrl-f space", "a |b")
	check(t, "|x%y", "ctrl-f %", "x%|y")
end)

test("esc in place of the character does nothing", function(t)
	check(t, "|a,b", "ctrl-f esc", "|a,b")
end)

test("shifted finds select, and finds extend an active selection", function(t)
	check(t, "|a,b,c", "ctrl-F ,", "^a,|b,c")
	check(t, "a,b,c|", "alt-F ,", "a,b|,c^")
	check(t, "|ab cd,e", "ctrl-W ctrl-f ,", "^ab cd,|e")
	check(t, "|a,b,c", "ctrl-space ctrl-; c", "^a,b,|c")
end)

test("every cursor finds on its own line", function(t)
	check(t, "|a,b\n|c,d", "ctrl-f ,", "a,|b\nc,|d")
end)

test("finds count characters, not bytes", function(t)
	check(t, "|é,ü,x", "ctrl-f ü", "é,ü|,x")
	check(t, "|é,ü,x", "ctrl-F ,", "^é,|ü,x")
end)
