-- Flash's keys, as data: bound in the `flash` mode by init.luau, and read
-- by the tests and the docs. Ctrl does a thing, alt its opposite, shift
-- selects. Plain printable keys type.

local M = {}

-- Motions: ctrl, alt (the opposite) and their shifted, selecting forms.
-- h j k l w e a v, with C-S-x and A-S-x selecting.
local MOTIONS: { { string } } = {
	-- key, ctrl's motion, alt's motion
	{ "h", "char-left", "char-right" },
	{ "l", "char-right", "char-left" },
	{ "j", "line-down", "line-up" },
	{ "k", "line-up", "line-down" },
	{ "w", "word-next", "word-prev" },
	{ "e", "word-end", "word-end-prev" },
	-- WORDs: runs of anything but blanks, as Vim's W and B.
	{ "q", "bigword-next", "bigword-prev" },
	{ "a", "line-start", "line-end" },
	{ "v", "page-down", "page-up" },
}

M.keys = {
	-- Selection
	["ctrl-space"] = "flash-space",
	["ctrl-S"] = "flash-collapse-anchor",
	["alt-S"] = "flash-collapse-head",
	esc = "flash-escape",
	-- Delete the selection, or a character, as in most editors (the typing
	-- role's backspace and delete only ever take a character).
	backspace = "erase-back",
	delete = "erase-forward",
	-- enter and tab replace the selection too; a multi-line selection's tab
	-- indents its lines.
	enter = "type-newline",
	tab = "type-tab",

	-- Character finds, Vim's f F t T ; ,
	["ctrl-f"] = "flash-find-next",
	["alt-f"] = "flash-find-prev",
	["ctrl-F"] = "flash-select-find-next",
	["alt-F"] = "flash-select-find-prev",
	["ctrl-;"] = "flash-till-next",
	["alt-;"] = "flash-till-prev",
	["ctrl-:"] = "flash-select-till-next",
	["alt-:"] = "flash-select-till-prev",
	["ctrl-."] = "flash-find-repeat",
	["alt-."] = "flash-find-reverse",

	-- Buffers, panes, searches
	["ctrl-b"] = "buffer-next",
	["alt-b"] = "buffer-prev",
	["ctrl-p"] = "pane-next",
	["alt-p"] = "flash-pane-prev",
	["ctrl-n"] = "flash-search-next",
	["alt-n"] = "flash-search-prev",
	["ctrl-N"] = "flash-select-search-next",
	["alt-N"] = "flash-select-search-prev",
	["ctrl-/"] = "search",
	["alt-/"] = "search-back",

	-- Editing pairs
	["ctrl-d"] = "flash-delete-forward",
	["alt-d"] = "flash-delete-back",
	["ctrl-i"] = "indent",
	["alt-i"] = "dedent",
	["ctrl-o"] = "insert-line-below",
	["alt-o"] = "insert-line-above",
	-- Lines move with their selections, each move one undo step. Case went
	-- to backtick and C-c c.
	["ctrl-u"] = "move-lines-up",
	["alt-u"] = "move-lines-down",
	["ctrl-z"] = "undo",
	["alt-z"] = "redo",
	["ctrl-y"] = "paste-over",

	-- Everyday edits in one chord (see docs/README.md, "Why these keys").
	-- Shift makes a sibling of the plain key: ctrl-X cuts where ctrl-x is a
	-- prefix, ctrl-D duplicates where ctrl-d deletes, ctrl-O joins where
	-- ctrl-o opens a line.
	["alt-c"] = "flash-copy",
	["alt-C"] = "flash-copy-keep",
	["ctrl-X"] = "cut-or-line",
	["ctrl-D"] = "copy-lines-down",
	["alt-D"] = "copy-lines-up",
	["ctrl-O"] = "join-lines",
	["alt-O"] = "flash-join-prev",
	["ctrl-,"] = "repeat-change",
	["alt-x"] = "command-palette",
	["ctrl-P"] = "pick-file",
	["ctrl-B"] = "pick-buffer",
	["ctrl-R"] = "rename",
	-- Surround, on a short prefix; C-c e a/r/d stay too.
	["ctrl-T a"] = "surround-add",
	["ctrl-T r"] = "surround-replace",
	["ctrl-T d"] = "surround-delete",
	["alt-y"] = "flash-unpaste",
	["ctrl-s"] = "flash-add-next-match",
	["alt-s"] = "flash-add-prev-match",
	["ctrl-r"] = "flash-replace-next",
	["alt-r"] = "flash-replace-prev",

	-- Jumping
	-- Jumping, as flash.nvim (ctrl-m, which terminals without the kitty
	-- protocol send as enter, is surround's now; C-g j jumps there).
	["ctrl-enter"] = "flash-jump",
	["ctrl-shift-enter"] = "flash-select-jump",
	["alt-enter"] = "flash-jump-back",
	["ctrl-g j"] = "flash-jump",

	-- Surround: ctrl-m then a pair's key wraps, alt-m then one takes it
	-- away, ctrl-m ctrl-s then the old and the new swaps.
	["ctrl-m '"] = "flash-surround-single",
	["ctrl-m `"] = "flash-surround-backtick",
	['ctrl-m "'] = "flash-surround-q",
	["ctrl-m ctrl-s"] = "flash-surround-change",
	["ctrl-m s"] = "flash-surround-change",
	["alt-m alt-n"] = "flash-unsurround-n",
	["alt-m n"] = "flash-unsurround-n",

	-- Punctuation
	["ctrl-\\"] = "toggle-comment",
	["alt-\\"] = "flash-uncomment",
	["ctrl-`"] = "flash-case-cycle",
	["alt-`"] = "flash-case-cycle-back",
	["ctrl-["] = "flash-expand",
	["alt-["] = "flash-shrink",
	["ctrl-]"] = "flash-sibling-next",
	["alt-]"] = "flash-sibling-prev",
	["ctrl-'"] = "flash-mark-set",
	["alt-'"] = "flash-mark-goto",
	["ctrl-="] = "font-bigger",
	["alt-="] = "font-smaller",
	["ctrl--"] = "fold-close",
	["alt--"] = "fold-open",

	-- C-g: navigation
	["ctrl-g ctrl-d"] = "goto-definition",
	["ctrl-g ctrl-i"] = "goto-implementation",
	["ctrl-g ctrl-r"] = "goto-references",
	["ctrl-g ctrl-t"] = "goto-type-definition",
	["ctrl-g g"] = "flash-doc-start",
	["alt-g g"] = "flash-doc-end",
	["ctrl-g G"] = "flash-select-doc-start",
	["alt-g G"] = "flash-select-doc-end",
	["ctrl-g l"] = "flash-goto-line",
	["ctrl-g r"] = "flash-goto-line-relative",
	["ctrl-g n"] = "next-diagnostic",
	["alt-g n"] = "prev-diagnostic",
	["alt-g alt-d"] = "jump-back",
	["ctrl-g w"] = "jump-to-word",
	["ctrl-g o"] = "pick-outline",
	["ctrl-g s"] = "pick-workspace-symbol",
	["ctrl-g ]"] = "next-function",
	["ctrl-g ["] = "prev-function",
	["ctrl-g m"] = "flash-mark-set",
	["ctrl-g '"] = "flash-mark-goto",
	["ctrl-g ctrl-o"] = "jump-back",
	["alt-g alt-o"] = "jump-forward",

	-- C-x: files and windows
	["ctrl-x ctrl-f"] = "pick-file",
	["ctrl-x ctrl-s"] = "save",
	["ctrl-x ctrl-w"] = "flash-save-as",
	["ctrl-x s"] = "save-all",
	["ctrl-x b"] = "pick-buffer",
	["ctrl-x 2"] = "pane-split-down",
	["ctrl-x 3"] = "pane-split-right",
	["ctrl-x 0"] = "pane-close",
	["ctrl-x 1"] = "pane-only",
	["ctrl-x o"] = "pane-next",
	["ctrl-x k"] = "buffer-close",
	["ctrl-x :"] = "command-line",
	["ctrl-x ctrl-c"] = "quit-ask",
	["ctrl-x h"] = "select-all",
	["ctrl-x y"] = "flash-copy-file",
	-- Extend mode: plain motions carry the selection on, as shift does,
	-- until ctrl-space. For terminals that can't send ctrl with shift.
	["ctrl-x space"] = "flash-toggle-selection",
	["ctrl-x u"] = "undo-tree",
	-- What alt-p, alt-t, alt-r, alt-space, alt-m, alt-f, alt-w, alt-W,
	-- alt-F, alt-n, alt-= and alt-- do in other styles, which flash's own keys take.
	["ctrl-x p"] = "pane-mode",
	["ctrl-x t"] = "tab-mode",
	["ctrl-x l"] = "layout-next",
	["ctrl-x m"] = "layout-swap-main",
	["ctrl-x f"] = "floats-toggle",
	["ctrl-x w"] = "float-layout-next",
	["ctrl-x W"] = "float-dock-pick",
	["ctrl-x F"] = "float-file",
	["ctrl-x n"] = "pane-terminal",
	["ctrl-x ="] = "pane-grow",
	["ctrl-x -"] = "pane-shrink",
	["ctrl-x r"] = "resize-mode",

	-- A count for the next command
	["ctrl-c n"] = "flash-count",

	-- C-c m: multiple cursors
	["ctrl-c m n"] = "flash-add-next-match",
	["ctrl-c m p"] = "flash-add-prev-match",
	["ctrl-c m a"] = "select-all-matches",
	["ctrl-c m j"] = "copy-selection-down",
	["ctrl-c m k"] = "copy-selection-up",
	["ctrl-c m s"] = "split-lines",
	["ctrl-c m r"] = "select-regex",
	["ctrl-c m x"] = "remove-primary",
	["ctrl-c m c"] = "keep-primary",
	["ctrl-c m o"] = "rotate-primary",
	["ctrl-c m O"] = "rotate-primary-back",
	["ctrl-c m l"] = "align-selections",

	-- C-c s: search
	["ctrl-c s w"] = "flash-search-word",
	["ctrl-c s a"] = "select-all-matches",
	["ctrl-c s r"] = "replace-in-file",
	["ctrl-c s e"] = "flash-replacement",
	["ctrl-c s f"] = "search-project",
	["ctrl-c s b"] = "search-buffer",
	["ctrl-c s c"] = "search-clear",
	["ctrl-c s g"] = "grep",

	-- C-c c: text transformations
	["ctrl-c c u"] = "flash-upcase",
	["ctrl-c c l"] = "flash-downcase",
	["ctrl-c c >"] = "flash-case-cycle",
	["ctrl-c c <"] = "flash-case-cycle-back",
	["ctrl-c c ~"] = "switch-case",
	["ctrl-c c t"] = "title-case",
	["ctrl-c c s"] = "snake-case",
	["ctrl-c c c"] = "camel-case",
	["ctrl-c c k"] = "kebab-case",
	["ctrl-c c p"] = "pascal-case",
	["ctrl-c c o"] = "sort-lines",
	["ctrl-c c r"] = "reflow",

	-- C-c e: editing actions
	["ctrl-c e y"] = "flash-copy-keep",
	["ctrl-c e c"] = "flash-copy",
	["ctrl-c e x"] = "cut-or-line",
	["ctrl-c e P"] = "paste-before",
	["ctrl-c e j"] = "join-lines",
	["ctrl-c e ;"] = "toggle-comment",
	["ctrl-c e k"] = "delete-lines-at-cursor",
	["ctrl-c e u"] = "copy-lines-down",
	["ctrl-c e U"] = "copy-lines-up",
	["ctrl-c e O"] = "flash-join-prev",
	["ctrl-c e /"] = "flash-uncomment",
	["ctrl-c e J"] = "move-lines-down",
	["ctrl-c e K"] = "move-lines-up",
	["ctrl-c e a"] = "surround-add",
	["ctrl-c e r"] = "surround-replace",
	["ctrl-c e d"] = "surround-delete",
	["ctrl-c e ."] = "repeat-change",
	["ctrl-c e +"] = "increment",
	["ctrl-c e -"] = "decrement",
	["ctrl-c e q"] = "record-macro",
	["ctrl-c e @"] = "play-macro",
	['ctrl-c e "'] = "select-register",
	["ctrl-c e i"] = "insert-register",
	["ctrl-c e ="] = "reindent-lines",
	["ctrl-c e w"] = "trim-selections",

	-- C-c d: debugging
	["ctrl-c d d"] = "debug",
	["ctrl-c d l"] = "debug-log",

	-- C-c g: version control
	["ctrl-c g n"] = "next-change",
	["ctrl-c g p"] = "prev-change",
	["ctrl-c g s"] = "stage-change",
	["ctrl-c g r"] = "revert-change",
	["ctrl-c g b"] = "blame-line",
	["ctrl-c g c"] = "changes",
	["ctrl-c g f"] = "pick-changed-file",

	-- C-c h: help
	["ctrl-c h h"] = "describe",
	["ctrl-c h c"] = "describe-command",
	["ctrl-c h o"] = "describe-option",
	["ctrl-c h m"] = "keys-help",
	["ctrl-c h t"] = "tutor",

	-- C-c k: keymap inspector
	["ctrl-c k k"] = "describe-key",
	["ctrl-c k m"] = "describe-mode",
	["ctrl-c k s"] = "describe-style",

	-- C-c l: language servers
	["ctrl-c l d"] = "goto-definition",
	["ctrl-c l r"] = "goto-references",
	["ctrl-c l h"] = "hover",
	["ctrl-c l n"] = "rename",
	["ctrl-c l a"] = "code-action",
	["ctrl-c l f"] = "format",
	["ctrl-c l o"] = "pick-outline",
	["ctrl-c l s"] = "pick-workspace-symbol",
	["ctrl-c l p"] = "pick-diagnostic",
	["ctrl-c l R"] = "lsp-restart",

	-- C-c p: plugins
	["ctrl-c p l"] = "plugins",
	["ctrl-c p a"] = "plugins-approve",
	["ctrl-c p s"] = "plugins-sync",
	["ctrl-c p u"] = "plugins-update",
	["ctrl-c p d"] = "describe-plugin",

	-- C-c q: the problems and grep lists
	["ctrl-c q p"] = "pick-problem",
	["ctrl-c q d"] = "pick-diagnostic",
	["ctrl-c q g"] = "grep",
	["ctrl-c q c"] = "grep-close",

	-- C-c r: refactoring
	["ctrl-c r n"] = "rename",
	["ctrl-c r a"] = "code-action",
	["ctrl-c r f"] = "format",
	["ctrl-c r j"] = "swap-node-next",
	["ctrl-c r k"] = "swap-node-prev",

	-- C-c t: tests and tasks
	["ctrl-c t t"] = "task",
	["ctrl-c t n"] = "next-test",
	["ctrl-c t p"] = "prev-test",

	-- C-c u: undo history
	["ctrl-c u u"] = "undo-tree",
	["ctrl-c u s"] = "selection-undo",
	["ctrl-c u r"] = "selection-redo",

	-- C-c v: view
	["ctrl-c v c"] = "center-view",
	["ctrl-c v t"] = "align-view-top",
	["ctrl-c v b"] = "align-view-bottom",
	["ctrl-c v z"] = "pane-zoom",
	["ctrl-c v T"] = "theme",
	["ctrl-c v s"] = "pick-style",
	["ctrl-c v o"] = "toggle-option",

	-- C-c w: workspace
	["ctrl-c w p"] = "pick-project",
	["ctrl-c w f"] = "pick-file",
	["ctrl-c w a"] = "pick-anything",
	["ctrl-c w s"] = "save-all",
	["ctrl-c w c"] = "command-palette",

	-- C-c x: shell
	["ctrl-c x x"] = "shell",
	["ctrl-c x !"] = "shell-line",
	["ctrl-c x t"] = "pane-terminal",
	["ctrl-c x p"] = "pick-terminal",

	-- C-c z: folding
	["ctrl-c z z"] = "fold-toggle",
	["ctrl-c z c"] = "fold-close",
	["ctrl-c z o"] = "fold-open",
	["ctrl-c z C"] = "fold-close-all",
	["ctrl-c z O"] = "fold-open-all",
	["ctrl-c z n"] = "fold-next",
	["ctrl-c z p"] = "fold-prev",

	-- Fallbacks for terminals without the kitty keyboard protocol, which
	-- can't send ctrl-[ (it's esc), alt-[ alt-] (escape codes) or ctrl-'.
	["ctrl-t ctrl-o"] = "flash-inside-o",
	["alt-t alt-o"] = "flash-around-o",
	["ctrl-t -"] = "flash-shrink",
	["ctrl-t ]"] = "flash-sibling-next",
	["ctrl-t ["] = "flash-sibling-prev",
} :: { [string]: string }

for _, motion in MOTIONS do
	local key, ctrl, alt = motion[1], motion[2], motion[3]
	M.keys[`ctrl-{key}`] = `flash-{ctrl}`
	M.keys[`alt-{key}`] = `flash-{alt}`
	M.keys[`ctrl-{string.upper(key)}`] = `flash-select-{ctrl}`
	M.keys[`alt-{string.upper(key)}`] = `flash-select-{alt}`
end

-- Text objects: ctrl-t then ctrl-KEY (or KEY) inside, alt-t then alt-KEY
-- (or KEY) around.
for _, key in { "b", "r", "c", "a", "q" } do
	M.keys[`ctrl-m ctrl-{key}`] = `flash-surround-{key}`
	M.keys[`ctrl-m {key}`] = `flash-surround-{key}`
	M.keys[`alt-m alt-{key}`] = `flash-unsurround-{key}`
	M.keys[`alt-m {key}`] = `flash-unsurround-{key}`
end

for _, key in { "b", "a", "r", "c", "n", "q", "w", "p", "s", "f", "l", "x", "d", "i", "g", "t" } do
	M.keys[`ctrl-t ctrl-{key}`] = `flash-inside-{key}`
	M.keys[`ctrl-t {key}`] = `flash-inside-{key}`
	M.keys[`alt-t alt-{key}`] = `flash-around-{key}`
	M.keys[`alt-t {key}`] = `flash-around-{key}`
end
M.keys["ctrl-t W"] = "flash-inside-W"
M.keys["ctrl-t ctrl-W"] = "flash-inside-W"
M.keys["alt-t W"] = "flash-around-W"
M.keys["alt-t alt-W"] = "flash-around-W"
M.keys["ctrl-t /"] = "flash-inside-comment"
M.keys["ctrl-t ctrl-/"] = "flash-inside-comment"
M.keys["alt-t /"] = "flash-around-comment"
M.keys["alt-t alt-/"] = "flash-around-comment"
M.keys["ctrl-t o"] = "flash-inside-o"
M.keys["alt-t o"] = "flash-around-o"

return M
