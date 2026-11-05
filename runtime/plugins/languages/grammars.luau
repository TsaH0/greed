-- Grammars Greed doesn't have built in, downloaded the first time a file in
-- their language opens and kept in the cache folder after that. Each is a
-- WebAssembly file from the grammar's own releases, checked against the
-- checksum below, with the queries from the same version of its
-- repository, their capture names changed to Greed's.
--
-- Turn downloading off with `greed.option.set("grammar-download", false)`;
-- grammars already downloaded still load. `:grammar-fetch NAME` downloads
-- one ahead of time.

local greed = require("@greed")

greed.option.define({
	name = "grammar-download",
	doc = "Download the grammar for a language Greed has none for when a file in it opens",
	default = true,
})

export type Source = {
	--- The GitHub repository, e.g. "tree-sitter/tree-sitter-ruby".
	repo: string,
	--- The release tag the grammar and its queries come from.
	version: string,
	sha256: string,
	--- The grammar's own name, when it isn't the language's with "-" as "_".
	symbol: string?,
	--- Languages whose queries come first, like C's for C++.
	inherits: { string }?,
	--- Where the WebAssembly file is, instead of the release.
	url: string?,
	--- Where the queries are, with "{kind}" for "highlights" or
	--- "injections", instead of the repository.
	queries: string?,
}

local M = {}

local function tree_sitter(name: string, version: string, sha256: string): Source
	return { repo = `tree-sitter/tree-sitter-{name}`, version = version, sha256 = sha256 }
end

--- The grammars Greed knows where to get, by language.
M.sources = {
	cpp = tree_sitter(
		"cpp",
		"v0.23.4",
		"174eb0deb75b2ec7881bcacda9f995648d8e683956e5c2267e69ab6dc503fcbf"
	),
	css = tree_sitter(
		"css",
		"v0.25.0",
		"8a23977fe271357cce6f254ef88c9bebf3854602d8046605aef6a45c02135c59"
	),
	html = tree_sitter(
		"html",
		"v0.23.2",
		"c48fcd82c7ea8bf943180088ba7f28c48b2bb5287874179168bf9d31e394cf85"
	),
	java = tree_sitter(
		"java",
		"v0.23.5",
		"4fdeac4ca6ca089f06c6f7e562abcac1733cd465728cc7031ebb73c2019122c4"
	),
	ruby = tree_sitter(
		"ruby",
		"v0.23.1",
		"09a96427d7c72f0613ed470cd9812223fc4a91d6a9c025c0235cc6bd59ff96f4"
	),
	haskell = tree_sitter(
		"haskell",
		"v0.24.1",
		"ea89cb1199b1ca2102e273b27239e795baff17248128a9bcd3c3825ac17d8cc0"
	),
	["c-sharp"] = tree_sitter(
		"c-sharp",
		"v0.23.5",
		"6f69e1cae44e1c32c1eccc170dc5a9778fb94ff716f71113fe1f8c4299aa2f40"
	),
	scala = tree_sitter(
		"scala",
		"v0.26.2",
		"37d7fe5a91ca98941dc05493b0c05a0df0f36df5035890fa00b02497c68aaac3"
	),
	regex = tree_sitter(
		"regex",
		"v0.25.0",
		"e63c28e3a023614e14f2086b0d818e190239ebe5b2fcce7e64a9940091d83a79"
	),
	jsdoc = tree_sitter(
		"jsdoc",
		"v0.25.0",
		"5530e630fd42424b1c026ec4b2b260ff1b73b78b7040239ac33d4be22a9b2271"
	),
	julia = tree_sitter(
		"julia",
		"v0.25.0",
		"b20da9dc7d7334e2cae034ca4974dd09c94be8c0a524df1fc194b545bc2f49f5"
	),
	ocaml = tree_sitter(
		"ocaml",
		"v0.26.0",
		"bfa3eef92b9d3cc1117aa486d46ecb06c98a3a28c1747660aaa5851df5e4530c"
	),
	php = tree_sitter(
		"php",
		"v0.25.1",
		"bd5e2bf8d42306b7aa32e6b7e39ae9fd9543c62a875ad8b2bc3d488242f72817"
	),
} :: { [string]: Source }
M.sources.cpp.inherits = { "c" }

local function grammars(repo: string, version: string, sha256: string): Source
	return { repo = `tree-sitter-grammars/{repo}`, version = version, sha256 = sha256 }
end

M.sources.zig = grammars(
	"tree-sitter-zig",
	"v1.1.2",
	"54b3b83dd9c62da5815f06132bc3fc914d9dcc780370b32416446a0b7969e8c6"
)
-- Its grammar is called zig whichever language loads it.
M.sources.zig.symbol = "zig"
M.sources.zon = M.sources.zig
M.sources.odin = grammars(
	"tree-sitter-odin",
	"v1.3.0",
	"4a3c9f50ac2356d2284d26e92322c554b276ad6bf6bce87a8594cff95d2ed6f1"
)
M.sources.make = grammars(
	"tree-sitter-make",
	"v1.1.1",
	"1254d1e5787be8bb944d55d1f6552b6b2b7908272ed498013bfdc07bd7d042dd"
)
M.sources.cuda = grammars(
	"tree-sitter-cuda",
	"v0.21.2",
	"3af5699d2ced8cd23b25da09193179b47e31e36bc7f7c7ff72427803ce9ed4b6"
)
M.sources.cuda.inherits = { "cpp" }
-- The repository has XML's and DTD's grammars, each with its own queries.
M.sources.xml = grammars(
	"tree-sitter-xml",
	"v0.7.0",
	"9950327f8542a3d563fe4192aa05986a53e6fd6adca518cbb1a1699cbc8970ad"
)
M.sources.xml.queries =
	"https://raw.githubusercontent.com/tree-sitter-grammars/tree-sitter-xml/v0.7.0/queries/xml/{kind}.scm"
M.sources.kotlin = {
	repo = "fwcd/tree-sitter-kotlin",
	version = "0.3.8",
	sha256 = "c624e7443b371c28adc5d81674e73067564c12555ebe3ed96a6c8db814b7602d",
}
M.sources.elixir = {
	repo = "elixir-lang/tree-sitter-elixir",
	version = "v0.3.5",
	sha256 = "1818ae0d7343f880abb0b7932c9a815f09896ca67b3e126096a2dd7677d1477b",
}
M.sources.r = {
	repo = "r-lib/tree-sitter-r",
	version = "v1.3.0",
	sha256 = "3e406e27cec05a60ba3281e2da021187200b83d152d9eb0dcf0a731cbfbcc28d",
}
M.sources.perl = {
	repo = "tree-sitter-perl/tree-sitter-perl",
	version = "v2.0.4",
	sha256 = "5cf639cfa71699a04d76d89c24cef314f5f31f7ab598b00610b97d9cde8033ec",
}

-- HCL, which Terraform and OpenTofu files are written in. The grammar has
-- no queries of its own; Helix's (same license as Greed) fit it.
M.sources.hcl = {
	repo = "tree-sitter-grammars/tree-sitter-hcl",
	version = "v1.2.0",
	sha256 = "2f9acf63e7c263215f283e2cf0f4ebbb9bfa77f58e18fa42b91094be201372a7",
	symbol = "hcl",
	queries = "https://raw.githubusercontent.com/helix-editor/helix/ba40e547426b0f9896c8bdc699a4ab11f2b37dbc/runtime/queries/hcl/{kind}.scm",
}
M.sources.terraform = M.sources.hcl
M.sources["terraform-vars"] = M.sources.hcl

-- Capture names other editors use, as Greed's (see the highlighting docs).
local NAMES: { [string]: string? } = {
	number = "constant.numeric",
	float = "constant.numeric.float",
	boolean = "constant.builtin.boolean",
	character = "constant.character",
	escape = "constant.character.escape",
	["string.escape"] = "constant.character.escape",
	property = "variable.other.member",
	field = "variable.other.member",
	["variable.member"] = "variable.other.member",
	parameter = "variable.parameter",
	method = "function.method",
	["function.call"] = "function",
	["function.method.call"] = "function.method",
	conditional = "keyword.control.conditional",
	["repeat"] = "keyword.control.repeat",
	include = "keyword.control.import",
	exception = "keyword.control.exception",
	["keyword.conditional"] = "keyword.control.conditional",
	["keyword.repeat"] = "keyword.control.repeat",
	["keyword.return"] = "keyword.control.return",
	["keyword.import"] = "keyword.control.import",
	["keyword.exception"] = "keyword.control.exception",
	module = "namespace",
	delimiter = "punctuation.delimiter",
	["tag.attribute"] = "attribute",
	["type.definition"] = "type",
	["string.special.uri"] = "string.special.url",
	["text.title"] = "markup.heading",
	["text.emphasis"] = "markup.italic",
	["text.strong"] = "markup.bold",
	["text.literal"] = "markup.raw",
	["text.uri"] = "markup.link.url",
	["text.reference"] = "markup.link.text",
}

-- Captures that are only for other editors' own features.
local DROPPED = { embedded = true, spell = true, nospell = true, none = true }

-- Lua's character classes, as the regex classes that match the same.
local CLASSES: { [string]: string? } = {
	a = "alpha",
	c = "cntrl",
	d = "digit",
	l = "lower",
	p = "punct",
	s = "space",
	u = "upper",
	w = "alnum",
	x = "xdigit",
}

--- `pattern`, a Lua pattern, as a regex that matches the same, written to
--- go in a query's string, where a backslash is doubled.
function M.regex(pattern: string): string
	local out = {}
	local inside = false
	local i = 1
	while i <= #pattern do
		local c = string.sub(pattern, i, i)
		local class = if c == "%" then string.sub(pattern, i + 1, i + 1) else ""
		local name = CLASSES[string.lower(class)]
		if name then
			local negated = class ~= string.lower(class)
			local inner = if negated then `[:^{name}:]` else `[:{name}:]`
			table.insert(out, if inside then inner else `[{inner}]`)
			i += 1
		elseif c == "%" then
			table.insert(out, "\\\\" .. class)
			i += 1
		elseif inside then
			table.insert(out, if c == "\\" then "\\\\\\\\" else c)
			inside = c ~= "]"
		elseif c == "[" then
			table.insert(out, c)
			inside = true
			-- A `]` right after `[` or `[^` is one of the set.
			local after = string.sub(pattern, i + 1, i + 1)
			if after == "^" then
				table.insert(out, "^")
				i += 1
				after = string.sub(pattern, i + 1, i + 1)
			end
			if after == "]" then
				table.insert(out, "\\\\]")
				i += 1
			end
		elseif c == "-" then
			-- Lua's lazy repeat.
			table.insert(out, "*?")
		elseif string.find("{}|\\", c, 1, true) then
			table.insert(out, "\\\\" .. c)
		else
			table.insert(out, c)
		end
		i += 1
	end
	return table.concat(out)
end

-- A pattern that names any node of a kind, like `(identifier) @variable`.
-- With the first pattern to match some text winning, these go last.
local CATCH_ALL = "^%(([%w_]+)%)%s+@[%w._]+$"

--- `source`, a query written for another editor, with Greed's capture names
--- and its catch-all patterns moved to the end.
function M.adapt(source: string): string
	local renamed = string.gsub(source, "@([%w._]+)", function(name: string): string
		if DROPPED[name] then
			return ""
		end
		return "@" .. (NAMES[name] or name)
	end)
	-- `(pattern/wildcard)`, a node by its supertype, needs the supertypes
	-- in the grammar, which not every build of one has; the node alone
	-- matches the same text.
	renamed = string.gsub(renamed, "%(([%w_]+)/([%w_]+)", "(%2")
	-- Neovim's `#lua-match?` takes a Lua pattern; left as it is, nothing
	-- checks it and the pattern matches everything, like every identifier
	-- as a type. As a regex `#match?` checks the same.
	for negated, escaped in { [""] = "", ["not-"] = "not%-" } do
		renamed = string.gsub(
			renamed,
			`#{escaped}lua%-match%?(%s+@[%w._]+%s+)"([^"]*)"`,
			function(capture: string, pattern: string): string
				return `#{negated}match?{capture}"{M.regex(pattern)}"`
			end
		)
	end
	-- Greed doesn't track which names are local variables, so a pattern
	-- for those that aren't is a catch-all, kept after the others.
	renamed =
		string.gsub(renamed, "%(%(([%w_]+)%)%s+(@[%w._]+)%s*%(#is%-not%? local%)%s*%)", "(%1) %2")
	local lines, last = {}, {}
	for line in string.gmatch(renamed .. "\n", "(.-)\n") do
		table.insert(if string.match(line, CATCH_ALL) then last else lines, line)
	end
	for _, line in last do
		table.insert(lines, line)
	end
	return table.concat(lines, "\n")
end

--- How files are fetched: `url` saved at `path`. A `file://` URL, as for a
--- grammar built locally, is copied.
function M.fetch(url: string, path: string)
	local file = string.match(url, "^file://(.+)$")
	if file then
		local copied, err = greed.fs.copy(file, path)
		if not copied then
			error(err, 0)
		end
		return
	end
	local response, err = greed.http.request({ url = url, save = path, timeout = 120000 })
	-- GitHub's downloads redirect to another host, which greed.http leaves
	-- to us; what arrives is checked against its sha256 either way.
	for _ = 1, 5 do
		local location = response and response.headers.location
		if not (response and response.status >= 300 and response.status < 400 and location) then
			break
		end
		response, err = greed.http.request({ url = location, save = path, timeout = 120000 })
	end
	if response == nil then
		error(`downloading {url}: {err}`, 0)
	elseif response.status < 200 or response.status >= 300 then
		error(`downloading {url}: status {response.status}`, 0)
	end
end

local KINDS = { "highlights", "injections" }

-- Where `name`'s files go.
local function folder(name: string, source: Source): string
	local cache = greed.fs.dirs().cache or (greed.fs.cwd() .. "/.greed-cache")
	return `{cache}/grammars/{name}/{source.version}`
end

local function wasm_url(source: Source): string
	if source.url then
		return source.url
	end
	local repo = string.match(source.repo, "/(.+)$") or source.repo
	local file = string.gsub(repo, "-", "_")
	file = string.gsub(file, "^tree_sitter_", "tree-sitter-")
	return `https://github.com/{source.repo}/releases/download/{source.version}/{file}.wasm`
end

local function queries_url(source: Source, kind: string): string
	if source.queries then
		return (string.gsub(source.queries, "{kind}", kind))
	end
	return `https://raw.githubusercontent.com/{source.repo}/{source.version}/queries/{kind}.scm`
end

-- The grammar's files, downloaded if they aren't yet. Returns the
-- WebAssembly file, or nil if it isn't there and can't be downloaded now.
local function files(name: string, source: Source): string?
	local dir = folder(name, source)
	local wasm = `{dir}/grammar.wasm`
	if greed.fs.stat(wasm) then
		return wasm
	end
	if greed.option.get("grammar-download") ~= true then
		return nil
	end
	greed.echo(`downloading the {name} grammar`)
	local part = wasm .. ".part"
	M.fetch(wasm_url(source), part)
	local got = greed.hash.sha256_file(part)
	if got ~= source.sha256 then
		greed.fs.remove(part)
		error(`the {name} grammar downloaded doesn't match its checksum ({got or "unknown"})`, 0)
	end
	for _, kind in KINDS do
		-- Not every grammar has every kind; those that don't are left out.
		pcall(M.fetch, queries_url(source, kind), `{dir}/{kind}.scm`)
	end
	local moved, err = greed.fs.rename(part, wasm)
	if not moved then
		error(err, 0)
	end
	return wasm
end

-- Languages being set up, so a second file opening doesn't start again.
local busy: { [string]: boolean } = {}

--- Sets up the grammar for `name` if Greed knows where to get one:
--- downloads it the first time, loads it and sets its queries, leaving
--- alone any a plugin or your config set from query files (`provided`
--- says which). Returns whether `name` has a grammar now.
function M.ensure(name: string, provided: (language: string, kind: string) -> boolean): boolean
	if table.find(greed.grammars(), name) then
		return true
	end
	local source = M.sources[name]
	if source == nil or busy[name] then
		return false
	end
	busy[name] = true
	local ok, result = pcall(function(): boolean
		local wasm = files(name, source)
		if wasm == nil then
			return false
		end
		greed.syntax.load_grammar(name, wasm, source.symbol)
		local dir = folder(name, source)
		-- A parent that downloads too, like C++ for CUDA, is set up first,
		-- so its queries are there to come before this one's.
		for _, parent in source.inherits or {} :: { string } do
			pcall(M.ensure, parent, provided)
		end
		for _, kind in KINDS do
			local own = greed.fs.read(`{dir}/{kind}.scm`)
			if own and not provided(name, kind) then
				local parts = {}
				local parents: { string } = source.inherits or {}
				for _, parent in parents do
					table.insert(parts, greed.syntax.query(parent, kind) or "")
				end
				table.insert(parts, own)
				greed.syntax.set_query(name, kind, M.adapt(table.concat(parts, "\n")))
			end
		end
		return true
	end)
	busy[name] = nil
	if not ok then
		error(result, 0)
	end
	return result
end

return M
