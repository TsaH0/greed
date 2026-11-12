# Flash Keys

An editing style for Greed without modes, selection first: every motion
selects what it moves over, shift carries the selection on, `ctrl-space`
stops selecting, ctrl does a thing and alt its opposite, and ordinary
keys type. It mixes Emacs's modifier keys, Helix's
selection-first editing, Vim's precise motions and a few of Neovim's
commands.

It's an independent style: Helix, Vim and VS Code styles are untouched,
and `:style` switches between all four while Greed runs.

## Installing

Copy the `flash-keys` folder into your Greed plugins folder and turn the
style on:

```sh
git clone -b flash-keys https://github.com/TsaH0/greed ~/src/greed-flash
mkdir -p ~/.config/greed/plugins
cp -r ~/src/greed-flash/flash-keys ~/.config/greed/plugins/
echo 'require("@greed").option.set("editing-style", "flash")' >> ~/.config/greed/init.luau
```

Restart Greed (or run `:config-reload`), or switch for the session only with
`:style flash`. The plugin asks for no capabilities, so it loads without
`:plugins-approve`. To check it against your Greed:

```sh
greed check ~/.config/greed/plugins/flash-keys
```

To update, copy the folder again. To stop using it, `:style helix` (or
remove the `editing-style` line), and delete the folder to remove it.

## How selecting works

Selection first, as in Helix and Kakoune: you select, then act. Every
range has an anchor and a head, and the cursor sits between characters.

| Press | Does | Again |
|---|---|---|
| `C-w` | Selects the next word (with the space after it) | Selects the word after that |
| `C-e` | Selects the next word on its own | The next one |
| `A-a` | Selects to the end of the line | Selects the next line, up to its line break |
| `C-a` | Selects back to the first non-blank, then the line start | The line before |
| `C-l` / `C-h` | Selects the next / previous character | The one after / before |
| `C-j` / `C-k` | Selects down / up a line, keeping the column | The next line down / up |
| `C-f x` | Selects through the next `x` | Through the one after |

- **Every plain motion selects what it moved over**, and pressed again it
  selects the next piece on its own rather than growing the last one.
- **Shift carries the selection on:** `C-w C-S-w C-S-w` selects three
  words; `A-a A-S-a A-S-a` three lines. The anchor stays where it was, and
  going back past it shrinks the selection, then grows it the other way.
- **`C-space` stops selecting:** each selection collapses to its cursor.
  `esc` does too, `C-S-s` collapses to the anchor and `A-S-s` to the head.
- **Act on what's selected:** `C-d` deletes it (`C-w C-d` deletes a word,
  `A-a C-d` to the line's end), `A-c` copies it, `` C-` `` changes its case,
  `C-\` comments its lines, `C-S-t a (` puts brackets round it.
- **Typing replaces what's selected,** whatever selected it: `C-w x`
  puts `x` in place of the word, `A-a` then typing replaces the rest of the
  line. `enter`, `tab` and paste replace it too, and `backspace` and
  `delete` delete it.
- **To type at a place you moved to without replacing anything,** press
  `C-space` first: `A-a C-space` then typing appends to the line, `C-f ,
  C-space` types after the comma.
- If you'd rather typing after a plain motion always went in at the
  cursor (replacing only what shift, a text object or `C-s` selected),
  turn on `flash-type-at-cursor`:
  `require("@greed").option.set("flash-type-at-cursor", true)`.
- **Copying with `A-c` stops selecting** too, so the next motion selects
  afresh. `A-S-c` copies and keeps the selection.
- **Each cursor selects on its own**, so all of this works with several.
- **Searches** (`C-n`, `A-n`) select their match; `C-S-n` and `A-S-n`
  extend the selection to it.
- **Jumps** to a label (`C-m`), a mark or a line leave a cursor there;
  `C-S-m` extends the selection to the label instead.
- **Extend mode** (`C-x space`, off with `C-space`) makes plain motions
  carry the selection on as shift does, for terminals that can't send
  ctrl with shift.

## Keys

`C-` is ctrl, `A-` alt, `S-` shift. Shifted letters are written as
capitals in Greed's key names: `ctrl-W` is ctrl-shift-w.

### Motions

Each selects what it moves over; with shift (`C-S-w`, `A-S-w` and so on)
it carries the selection on instead.

| Ctrl | | Alt | |
|---|---|---|---|
| `C-h` | Left a character | `A-h` | Right a character |
| `C-l` | Right a character | `A-l` | Left a character |
| `C-j` | Down a line | `A-j` | Up a line |
| `C-k` | Up a line | `A-k` | Down a line |
| `C-w` | Next word start | `A-w` | Previous word start |
| `C-e` | Next word end | `A-e` | Previous word end |
| `C-a` | First non-blank, then line start, then the line before | `A-a` | Line end, then the next line |
| `C-v` | Page down | `A-v` | Page up |
| `C-g g` | To the buffer's start (`C-g G` extends) | `A-g g` | To its end (`A-g G` extends) |

Up and down keep the column they started from.

### Character finds (Vim's f F t T ; ,)

On the cursor's line, with the character taken literally (punctuation,
`space` and multi-byte characters too).

| Keys | Vim | |
|---|---|---|
| `C-f x` | `fx` | Forward through the next `x` |
| `A-f x` | `Fx` | Back to the previous `x` |
| `C-; x` | `tx` | Forward to just before the next `x` |
| `A-; x` | `Tx` | Back to just after the previous `x` |
| `C-.` | `;` | The last find again, the same way |
| `A-.` | `,` | The last find again, the other way |
| `C-F x`, `A-F x` | | Extend through the character |
| `C-: x`, `A-: x` | | Extend up to it (shift with `;`) |

A till skips the character right beside the cursor, so `C-.` after one
moves on to the next match.

### Selection

| Keys | |
|---|---|
| `C-space` | Stop selecting: collapse to the cursor |
| `C-x space` | Extend mode: plain motions extend, until `C-space` |
| `C-S-s` | Collapse to the anchor |
| `A-S-s` | Collapse to the head |
| `esc` | Drop the selection |
| `C-s` / `A-s` | Select the word, then add the next / previous match as another selection |
| `C-[` / `A-[` | Grow / shrink the selection by the syntax tree |
| `C-]` / `A-]` | Select the next / previous syntax sibling |

### Text objects

`C-t` then a key selects inside the object around each cursor; `A-t`
then a key selects around it. The second key works with or without its
modifier (`C-t C-b` or `C-t b`). Shifted motions carry an object's
selection on, and typing replaces it.

| Inside | Around | Object |
|---|---|---|
| `C-t C-b` | `A-t A-b` | Square brackets `[]` |
| `C-t C-a` | `A-t A-a` | Angle brackets `<>` |
| `C-t C-r` | `A-t A-r` | Parentheses `()` |
| `C-t C-c` | `A-t A-c` | Curly braces `{}` |
| `C-t C-n` | `A-t A-n` | The nearest bracket pair of any kind |
| `C-t C-q` | `A-t A-q` | Quotes: the innermost `"`, `'` or `` ` `` pair |
| `C-t C-w` | `A-t A-w` | Word |
| `C-t C-p` | `A-t A-p` | Paragraph |
| `C-t C-s` | `A-t A-s` | Sentence |
| `C-t C-f` | `A-t A-f` | Function (from the syntax tree) |
| `C-t C-l` | `A-t A-l` | Line (inside: without its indent and line break) |
| `C-t C-o` | `A-t A-o` | Syntax node (around: the node around it) |
| `C-t C-x` | `A-t A-x` | HTML or XML tag |

Surround: `C-S-t a` adds a pair around each selection (type the
bracket), `C-S-t r` replaces one (type the old, then the new), `C-S-t d`
deletes one. `C-c e a`, `C-c e r` and `C-c e d` do the same.

### Editing

| Ctrl | | Alt | |
|---|---|---|---|
| `C-d` | Delete the selection, or the character after | `A-d` | Delete the selection, or the character before |
| `C-i` | Indent | `A-i` | Unindent |
| `C-o` | Open a line below | `A-o` | Open a line above |
| `C-u` | Move the lines up, selections and all | `A-u` | Move them down |
| `C-S-d` | Duplicate the lines below, the selection going with the copy | `A-S-d` | Duplicate them above |
| `C-S-o` | Join the next line on | `A-S-o` | Join this line onto the one before |
| `C-\` | Comment the lines, or uncomment them if they all are | `A-\` | Uncomment the lines that have a comment; never adds one |
| `` C-` `` | Case: lower, UPPER, Title | `` A-` `` | Case the other way round |
| `C-z` | Undo | `A-z` | Redo |
| `A-c` | Copy the selection (the line with nothing selected) and stop selecting | `A-S-c` | Copy, keeping the selection |
| `C-S-x` | Cut the selection, or the line with nothing selected | | |
| `C-y` | Paste, replacing the selection (whole lines go above) | `A-y` | Take the paste back, if it's still the last thing done |
| `C-r` | Replace the next match of the search | `A-r` | Replace the previous match |

`C-r` asks what to replace with the first time, and uses that after;
`C-c s e` changes it.

| Keys | |
|---|---|
| `C-,` | Do the last edit again (Vim's `.`) |
| `A-x` | Run any command by name |
| `C-S-p` | Open a file in the project |
| `C-S-b` | Switch buffer |
| `C-S-r` | Rename the symbol at the cursor (language server) |

Moving and duplicating lines take every cursor's lines and keep each
selection where it was on its text, and each is one step to undo.
Cursors on lines next to each other move and duplicate as one block.

### Moving around

| Ctrl | | Alt | |
|---|---|---|---|
| `C-b` | Next buffer | `A-b` | Previous buffer |
| `C-p` | Next pane | `A-p` | Previous pane |
| `C-n` | Next search match | `A-n` | Previous search match |
| `C-/` | Search forward | `A-/` | Search backward |
| `C-m x` | Jump: type a character, then its label | `A-m` | Cancel the jump; afterwards, go back to where it started |
| `C-'` `x` | Set mark `x` | `A-'` `x` | Go to mark `x` |
| `C-=` | Bigger text (window only) | `A-=` | Smaller text |
| `C--` | Fold the block | `A--` | Unfold it |

The jump labels only what's on screen, nearest first, with one letter
each while the alphabet lasts and two after that
(`jump-label-alphabet` sets the letters). It lands one cursor.

### C-g: navigation

| Keys | |
|---|---|
| `C-g C-d` | Definition |
| `C-g C-i` | Implementation |
| `C-g C-r` | References |
| `C-g C-t` | Type definition |
| `A-g A-d` | Back from a definition (the jump list) |
| `C-g C-o` / `A-g A-o` | Back / forward through the jump list |
| `C-g g` / `A-g g` | Buffer start / end |
| `C-g l` | Go to the line typed |
| `C-g r` | Go up or down the lines typed, `+3` or `-3` |
| `C-g n` / `A-g n` | Next / previous problem |
| `C-g w` | Jump to a word by its label |
| `C-g m x` / `C-g ' x` | Set / go to mark `x` |

### C-x: files and windows

| Keys | |
|---|---|
| `C-x C-f` | Open a file |
| `C-x C-s` | Save |
| `C-x C-w` | Save as (the command line, with `save ` typed) |
| `C-x s` | Save every file |
| `C-x b` | The buffer picker |
| `C-x 2` / `C-x 3` | Split below / to the right |
| `C-x 0` / `C-x 1` | Close this pane / close the others |
| `C-x o` | Next pane |
| `C-x k` | Close the buffer |
| `C-x :` | The command line, for Greed's `:` commands |
| `C-x h` | Select everything |
| `C-x u` | The undo tree |
| `C-x C-c` | Quit, asking about unsaved files |
| `C-x p` / `C-x t` | The pane mode / the tab mode (`alt-p` / `alt-t` elsewhere) |
| `C-x l` / `C-x m` | The next pane layout / swap the pane with the main one |
| `C-x f` / `C-x w` / `C-x W` / `C-x F` | Hide or show the floats / the next float layout / pick a float / this file floating |
| `C-x n` | A terminal in a new pane |
| `C-x =` / `C-x -` | Give the pane more / less room |
| `C-x r` | The resize mode (`alt-r` elsewhere) |

### C-c: everything else

`C-c n` then digits, then keys, runs those keys' command with that count,
as Emacs's `C-u`: `C-c n 3 C-w` moves three words.

| Prefix | For | Keys |
|---|---|---|
| `C-c m` | Multiple cursors | `n` next match, `p` previous match, `a` every match, `j` / `k` a cursor below / above, `s` split into lines, `r` select a regex's matches, `x` remove the primary cursor, `c` keep only the primary, `o` / `O` rotate the primary, `l` line them up |
| `C-c s` | Search | `w` the word at the cursor, `a` select every match, `r` replace in the file, `e` what `C-r` replaces with, `f` the project, `b` this buffer as a list, `c` clear the highlights, `g` grep into a panel |
| `C-c c` | Text case and shape | `u` upper and `l` lower (the selection, or the word), `>` / `<` cycle the case, `~` switch, `t` Title, `s` snake, `c` camel, `k` kebab, `p` Pascal, `o` sort lines, `r` reflow |
| `C-c e` | Editing | `y` copy keeping the selection, `c` copy and let go (`A-c`), `x` cut, `P` paste before, `j` / `O` join with the next / previous line, `;` comment, `/` uncomment, `k` delete the lines, `u` / `U` duplicate them below / above, `J` / `K` move them down / up, `a` / `r` / `d` surround add / replace / delete, `.` repeat the last change, `+` / `-` the number at the cursor, `q` record a macro, `@` play it, `"` pick a register, `i` insert a register, `=` reindent, `w` trim the selections |
| `C-c d` | Debugging Greed | `d` debug topics, `l` the debug log |
| `C-c g` | Version control | `n` / `p` next / previous change, `s` stage, `r` revert, `b` blame, `c` every change, `f` a changed file |
| `C-c h` | Help | `h` describe anything, `c` a command, `o` an option, `m` this mode's keys, `t` the tutor |
| `C-c k` | Keymap inspector | `k` what a key does, `m` a mode's keys, `s` a style |
| `C-c l` | Language server | `d` definition, `r` references, `h` hover, `n` rename, `a` code action, `f` format, `o` outline, `s` workspace symbols, `p` problems, `R` restart the server |
| `C-c p` | Plugins | `l` list, `a` approve, `s` sync, `u` update, `d` describe |
| `C-c q` | Problems and grep results | `p` every problem, `d` this file's, `g` grep into a panel, `c` close it |
| `C-c r` | Refactoring | `n` rename, `a` code action, `f` format, `j` / `k` swap the syntax node with the next / previous |
| `C-c t` | Tests and tasks | `t` run a task, `n` / `p` select the next / previous test |
| `C-c u` | Undo history | `u` the undo tree, `s` / `r` undo / redo a selection change |
| `C-c v` | View | `c` center, `t` / `b` the line to the top / bottom, `z` zoom the pane, `T` theme, `s` style, `o` toggle an option |
| `C-c w` | Workspace | `p` projects, `f` files, `a` anything, `s` save all, `c` every command |
| `C-c x` | Shell | `x` a shell, `!` run a command line, `t` a terminal, `p` pick a terminal |
| `C-c z` | Folding | `z` toggle, `c` / `o` close / open, `C` / `O` close / open all, `n` / `p` next / previous fold |

Greed's leader (`space f` and the rest in Helix) opens with `alt-space`
here: `alt-space f` finds a file. Keys bound for the leader or for the
typing role in your config work in this style too.

## Terminals and the kitty keyboard protocol

Greed asks the terminal for the kitty keyboard protocol (kitty, Ghostty,
WezTerm, foot and recent Alacritty are among those that speak it), which is what lets it tell `ctrl-i` from `tab`, `ctrl-m` from
`enter`, `ctrl-[` from `esc`, and see `ctrl-;`, `ctrl-'`, `ctrl-.`,
`ctrl-=` and ctrl with shift at all. The window client (`greed --gui`)
sees every key.

In a terminal without it (or with `GREED_KEYS=legacy`), these don't
arrive as themselves. Use the fallbacks:

| Key | What the terminal sends without the protocol | Fallback |
|---|---|---|
| `C-i` | `tab` | `tab` indents a multi-line selection; `C-c e =` reindents |
| `C-m` | `enter` | `C-g w` jumps to a word |
| `C-[` / `A-[` | `esc` / the start of an escape code | `C-t C-o` selects the node, `A-t A-o` the one around it, `C-t -` shrinks |
| `C-]` / `A-]` | `C-]` works; `alt-]` may not | `C-t ]` / `C-t [` next / previous sibling |
| `C-'` / `A-'` | Nothing usable | `C-g m x` / `C-g ' x` |
| `C-;`, `C-.`, `C-=`, `C--`, `C-/`, `C-\` | Often nothing, or another key | Finds: `C-f` / `A-f` (no fallback for till and repeat); folds: `C-c z c` / `C-c z o`; case: `C-c c`; search: `C-c s b` |
| `C-S-letter` motions | The same as `C-letter` | `C-x space` (extend mode), then the plain motions, `C-space` to stop; or the `A-S-` twin (`A-S-k` for `C-S-j`) |
| `C-S-x` | `C-x`, the prefix | `C-c e x` |
| `C-S-d` | `C-d`, which deletes | `C-c e u` (and `C-c e U` for `A-S-d`) |
| `C-S-o` | `C-o`, which opens a line | `C-c e j` (`A-S-o` works: `C-c e O` too) |
| `C-S-p` / `C-S-b` | `C-p` next pane / `C-b` next buffer | `C-x C-f` / `C-x b` |
| `C-S-r` | `C-r`, replace next | `C-c l n` |
| `C-S-t` | `C-t`, the text objects (so `a` selects inside `<>`) | `C-c e a` / `r` / `d` |
| `` C-` `` | Usually `C-space` (both send the same byte), which stops selecting | `C-c c >` / `C-c c <` |
| `C-,` | A plain `,`, which types | `C-c e .` |
| `C-h` | Some terminals send it for `backspace` | `backspace` still deletes |

## Why these keys

Flash started with a key for every idea; using it, the edits made all day
(copy, cut, moving and duplicating lines, comments, joining, repeating)
were three keys deep under `C-c e`, while case changes had `C-u` and
`C-\` to themselves. So:

- **One chord for what you do all the time.** Copy, cut, paste, move and
  duplicate lines, comment, join, repeat, the command palette and the file
  and buffer pickers each take one chord. Everything else is at most
  three keys: a prefix (`C-g`, `C-x`, `C-c x`), then one or two.
- **Shift makes a sibling of the plain key.** `C-d` deletes and `C-S-d`
  duplicates; `C-o` opens a line and `C-S-o` joins one; `C-x` is the file
  prefix and `C-S-x` cuts; `C-t` selects objects and `C-S-t` changes what's
  around them; `C-p` and `C-b` step through panes and buffers, and
  `C-S-p` and `C-S-b` pick from them. On motions shift still selects.
- **Ctrl and alt stay opposites:** lines up and down (`C-u` / `A-u`),
  duplicate below and above, join next and previous, comment and
  uncomment, case forward and back, copy-and-let-go and copy-and-keep.
- **The home row keeps the motions.** `C-h j k l w e a f ;` and `C-m`,
  `C-t`, `C-s` are as they were.
- **Copy lets go.** After copying you usually move on, so `A-c` collapses
  the selection; `A-S-c` keeps it for when you don't.
- **Rare things live behind prefixes and `A-x`:** case styles, plugins,
  text size, macros, registers, formatting.

What couldn't be shortened safely:

- **Copy on `C-c`, cut on `C-x`:** those are the prefixes, so copy is
  `A-c` and cut `C-S-x`.
- **Uppercase and lowercase on one chord:** `C-u` / `A-u` now move lines.
  Case cycles on `` C-` `` and `` A-` ``; direct upper and lower are `C-c c u`
  and `C-c c l`.
- **Undoing a duplicate or join as an opposite key:** `A-S-d` is duplicate
  *above*, not "unduplicate"; `C-z` undoes either.
- **Rename has no opposite** (`A-S-r` is left unbound rather than given a
  made-up meaning).

### The keys this changed, and what was there

Checked against the keymap before the change (`greed.keymap.describe` in
Flash's mode, which also shows Greed's keys for every mode):

| Key | Before | Now |
|---|---|---|
| `C-u` / `A-u` | Upper / lower case | Move lines up / down. Case: `` C-` `` and `C-c c u` / `l` |
| `C-\` / `A-\` | Cycle case forward / back | Toggle comment / uncomment. Case: `` C-` `` / `` A-` `` |
| `C-c e y` | Copy (keeping the selection) | The same, now `flash-copy-keep` |
| `C-c c u` / `l` | Upper / lower the selection only | The selection, or the word with nothing selected |
| `A-c` `A-S-c` `C-S-x` `C-S-d` `A-S-d` `C-S-o` `A-S-o` `C-,` `A-x` `C-S-p` `C-S-b` `C-S-r` `C-S-t` `` C-` `` `` A-` `` | Unbound in Flash and in Greed's keys for every mode | As above |

## Conflicts with Greed's own keys

Flash binds its keys in its own mode, `flash`. A mode's keys win over the
keys bound for every mode, so inside Flash these work as Flash says, and
everywhere else (other styles, terminals, pickers) Greed's keys are
unchanged. The tests check both sides.

| Key | Greed's default (every mode) | In Flash |
|---|---|---|
| `C-space` | The leader in the VS Code style; the leader from a terminal | Stop selecting. The leader is `alt-space` |
| `A-h` `A-j` `A-k` `A-l` | Move to the pane on that side | Character and line motions. Panes: `alt` and the arrows (still Greed's), `C-p` / `A-p`, `C-x o` |
| `A-p` | The pane mode | Previous pane. Pane mode: `C-x p` |
| `A-t` | The tab mode | Around text objects. Tab mode: `C-x t` |
| `alt-space` | The next pane layout | The leader. Layouts: `C-x l` |
| `A-m` | Swap the pane with the main one | Cancel or go back from a jump. Swap: `C-x m` |
| `A-f` | Hide or show the floating views | Find backward. Floats: `C-x f` |
| `A-F` | This file in a floating view | Select back through a character. `C-x F` |
| `A-w` / `A-W` | The next float layout / pick a float | Previous word / select to it. `C-x w` / `C-x W` |
| `A-n` | A terminal in a new pane | Previous search match. `C-x n` |
| `A-r` | The resize mode | Replace the previous match. Resize mode: `C-x r` |
| `A-=` / `A--` | Grow / shrink the pane | Smaller text / unfold. `C-x =` / `C-x -`, or `alt-+` |
| `A-[` / `A-]` | The tab before / after (kitty only) | Shrink the selection / previous sibling. Tabs: `alt-<` / `alt->` |
| `C-c` | Copy in the VS Code style | The advanced prefix. Copy: `C-c e y` |
| `C-x`, `C-v`, `C-z`, `C-y` | Cut, paste, undo, redo in the VS Code style | Emacs's meanings: prefix, page, undo, paste |

Keys still Greed's own inside Flash: `alt` with the arrows (panes),
`alt-+` (grow the pane), `alt-<` `alt->` and
`alt-1` to `alt-9` (tabs), `alt-{` `alt-}` (floats), `f1` (this mode's
keys), and every key in pickers, prompts, the command line, the file tree
and terminals, which have layers of their own ahead of a style's.

## What isn't implemented, or only partly

- `C-q` / `A-q` (next / previous quickfix item) are unbound: Greed has no
  command that steps through the grep panel's results. `C-c q g` fills the
  panel and you move in it as in any list.
- `C-c s v`, Vim's "very magic" regex search, is unbound. Greed's searches
  and `:s` take Rust regexes, which are close to `\v` already: `(foo|bar)`
  groups and alternates without backslashes. `:%s/(foo|bar)/baz/g` works
  through `C-x :`; Vim's `\v`, `\<`, `\>` and the `c` (confirm) flag don't.
- The jump labels characters only. Word labels are `C-g w` (Greed's own);
  line-number labels aren't there.
- A jump lands one cursor, even with several.
- `C-s` / `A-s` with nothing selected select the word first; the next
  press adds the match, as in VS Code. The word is the one the cursor is
  in or just after; in blanks with no word beside it, nothing is selected.
- Numeric counts are `C-c n N keys` rather than a bare number, since digits
  type in a style without modes. Commands that ignore counts ignore them
  here too.
- `C-=` / `A-=` change the text size in the window client only.
- The style's mode label stays `flash` in extend mode; the status line
  says "Selection on" and "Selection off" as `C-x space` toggles it.
- The key table is written for a US keyboard. On other layouts, the
  punctuation keys (`;` `'` `[` `]` `\` `/` `=` `-`) are where those
  characters are typed with ctrl, which the terminal may not send.

### Tested and not

`greed test` runs 116 tests over: every motion selecting and selecting
the next piece again, shift carrying the selection on, `C-space`
stopping it and extend mode, typing, `enter`, `backspace`, `delete` and
paste replacing what a motion selected (and going in at the cursor with
`flash-type-at-cursor`), shrinking and crossing the
anchor,
f/F/t/T and their repeats (punctuation, space, multi-byte), every text
object, syntax node selection, surround, the jump and its cancelling,
marks, case changes, copying (letting go and keeping the selection, the line with nothing selected, one piece per cursor), cut, paste and taking it back, moving, duplicating and joining lines (multiline and with several cursors, each one undo step), commenting and uncommenting, search and replace, line
prompts, multiple cursors, macros, registers, counts, folds, repeating a
change, splits and panes, buffers, saving, the key conflicts above, typing
in pickers, prompts and the command line, keys passing through to a
terminal's program, and unloading and reloading the plugin.

These are bound to Greed's own commands but aren't exercised by the tests,
since they need a language server, a repository or a window: `C-g C-d`
`C-g C-i` `C-g C-r` `C-g C-t`, problems (`C-g n`), everything under
`C-c l`, `C-c r`, `C-c g`, `C-c t`, `C-c p`, `C-c d`, `C-c v`, `C-c x`,
and the text size. The tests do check that every key in the table runs a
command that exists.
