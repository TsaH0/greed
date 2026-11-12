local greed = require("@greed")
local test = require("@greed/test")
local flash = require("@flash-keys")

local function setup(t: test.TestContext, text: string)
	t:buffer(text)
	greed.mode.set("flash")
end

local function labels(): { [number]: string }
	local out = {}
	for _, mark in greed.view():buffer():decorations("flash-keys-jump") do
		if mark.text then
			out[mark.from] = mark.text
		end
	end
	return out
end

test("matches on screen are labelled nearest first, the label just after each", function(t)
	setup(t, "foo1 foo2 |foo3 foo4")
	local targets = flash.jump.targets(greed.view(), greed.view():cursor(), "foo")
	assert(#targets == 4, tostring(#targets))
	assert(targets[1].from == 10 and targets[1].to == 13, greed.json.encode(targets))
	assert(targets[2].from == 5, greed.json.encode(targets))
	assert(targets[1].label == "a" and targets[2].label == "b", greed.json.encode(targets))
end)

test("a letter that comes right after a match is never a label", function(t)
	-- "x" is followed by a, b, c and d, so labels start at e.
	setup(t, "|xa xb xc xd")
	local targets = flash.jump.targets(greed.view(), 0, "x")
	for _, target in targets do
		assert(not string.find("abcd", target.label :: string, 1, true), greed.json.encode(targets))
	end
	assert(targets[1].label == "e", greed.json.encode(targets))
end)

test("type as much as you like, then the label, to jump to the match's start", function(t)
	setup(t, "|one fox foo fig")
	-- f: fox is a, foo b, fig c; fo: fox and foo keep a and b.
	t:keys("ctrl-m f o b")
	t:expect("one fox |foo fig")
	setup(t, "|one fox foo fig")
	-- fig was c after f, and stays c after fi.
	t:keys("ctrl-m f i c")
	t:expect("one fox foo |fig")
end)

test("typing more narrows the matches, keeping their labels", function(t)
	setup(t, "|ab ac ad")
	t:keys("ctrl-m a")
	local first = labels()
	t:keys("c")
	local narrowed = labels()
	t:keys("esc")
	assert(narrowed[5] ~= nil, "ac's label moves past the c")
	assert(narrowed[5] == first[4], "and stays the same letter")
	local count = 0
	for _ in narrowed do
		count += 1
	end
	local function list(t: { [number]: string }): string
		local out = {}
		for pos, label in t do
			table.insert(out, `{pos}={label}`)
		end
		return table.concat(out, " ")
	end
	assert(count == 1, list(narrowed))
	assert(first[1] ~= nil and first[4] ~= nil and first[7] ~= nil, list(first))
end)

test("lower case finds any case, a capital only itself", function(t)
	setup(t, "|x Foo foo")
	assert(#flash.jump.targets(greed.view(), 0, "foo") == 2, "smart case")
	assert(#flash.jump.targets(greed.view(), 0, "Foo") == 1, "exact with a capital")
end)

test("punctuation is searched for as itself", function(t)
	setup(t, "|a.b a+b a.b")
	assert(#flash.jump.targets(greed.view(), 0, ".") == 2, ".")
	assert(#flash.jump.targets(greed.view(), 0, "a+") == 1, "a+")
	t:keys("ctrl-m + a")
	t:expect("a.b a|+b a.b")
end)

test("enter jumps to the nearest match", function(t)
	setup(t, "foo |x foo")
	t:keys("ctrl-m f o o enter")
	t:expect("foo x |foo")
end)

test("backspace takes back a character, and on none cancels", function(t)
	setup(t, "|ab ac")
	t:keys("ctrl-m a c backspace backspace backspace")
	t:expect("|ab ac")
	assert(#greed.view():buffer():decorations("flash-keys-jump") == 0, "labels cleared")
end)

test("esc or alt-m cancels and clears the screen", function(t)
	setup(t, "x1 x2 |x3")
	t:keys("ctrl-m x esc")
	t:expect("x1 x2 |x3")
	t:keys("ctrl-m x alt-m")
	t:expect("x1 x2 |x3")
	assert(#greed.view():buffer():decorations("flash-keys-jump") == 0, "cleared")
end)

test("alt-m afterwards goes back to where the jump started", function(t)
	setup(t, "foo x |y")
	t:keys("ctrl-m f o o a")
	t:expect("|foo x y")
	t:keys("alt-m")
	t:expect("foo x |y")
end)

test("ctrl-M jumps extending the selection", function(t)
	setup(t, "|ab foo")
	t:keys("ctrl-M f o o a")
	t:expect("^ab |foo")
	setup(t, "|ab foo")
	t:keys("ctrl-m f o o a")
	t:expect("ab |foo")
end)

test("typing in a buffer after a jump works as usual", function(t)
	setup(t, "|ab foo")
	t:keys("ctrl-m f o o a x")
	t:expect("ab x|foo")
end)
