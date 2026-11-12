# Flash Keys

An editing style for Greed without modes: ctrl does a thing, alt does its
opposite, shift selects, `ctrl-space` keeps selecting until you press it
again, and ordinary keys type. It mixes Emacs's modifier keys, Helix's
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

Every range has an anchor that stays put and a head that motions move.
The cursor sits between characters.

| You have | `ctrl-w` | `ctrl-W` (shift) |
|---|---|---|
| Nothing selected | Moves to the next word | Starts a selection and selects to the next word |
| Something selected (a text object, a shifted motion) | Extends the selection | Extends the selection |
| `ctrl-space` on | Extends the selection | Extends the selection |

- `ctrl-space` turns persistent selection on: every motion extends from
  where you pressed it. Press it again to turn it off; the selection
  collapses to its head.
- Going back the other way shrinks the selection, and once the head comes
  back to the anchor it carries on past it, selecting the other way.
- `ctrl-S` collapses to the anchor and `alt-S` to the head, both turning
  persistent selection off. `esc` drops the selection too.
- Typing replaces the selection and turns persistent selection off, as
  typing does Emacs's mark. Copying keeps the selection, as in Helix.
- Each cursor moves and selects on its own, so all of this works with
  several cursors.
- Searches (`ctrl-n`, `alt-n`) select their match. They extend only when
  persistent selection is on or motions built the selection, so `ctrl-n`
  after a search goes to the next match rather than growing the first.

## Keys

`C-` is ctrl, `A-` alt, `S-` shift. Shifted letters are written as
capitals in Greed's key names: `ctrl-W` is ctrl-shift-w.

### Motions

Shift selects (`C-S-w`, `A-S-w` and so on); without shift a motion
extends an active selection and otherwise moves.

| Ctrl | | Alt | |
|---|---|---|---|
| `C-h` | Left a character | `A-h` | Right a character |
| `C-l` | Right a character | `A-l` | Left a character |
| `C-j` | Down a line | `A-j` | Up a line |
| `C-k` | Up a line | `A-k` | Down a line |
| `C-w` | Next word start | `A-w` | Previous word start |
| `C-e` | Next word end | `A-e` | Previous word end |
| `C-a` | First non-blank, then line start | `A-a` | Line end |
| `C-v` | Page down | `A-v` | Page up |
| `C-g g` | Buffer start (`C-g G` selects) | `A-g g` | Buffer end (`A-g G` selects) |

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
| `C-F x`, `A-F x` | | Select through the character |
| `C-: x`, `A-: x` | | Select up to it (shift with `;`) |

A till skips the character right beside the cursor, so `C-.` after one
moves on to the next match.

### Selection

| Keys | |
|---|---|
| `C-space` | Persistent selection on; again, off and collapse to the head |
| `C-S-s` | Collapse to the anchor |
| `A-S-s` | Collapse to the head |
| `esc` | Drop the selection |
| `C-s` / `A-s` | Select the word, then add the next / previous match as another selection |
| `C-[` / `A-[` | Grow / shrink the selection by the syntax tree |
| `C-]` / `A-]` | Select the next / previous syntax sibling |

### Text objects

`C-t` then a key selects inside the object around each cursor; `A-t`
then a key selects around it. The second key works with or without its
modifier (`C-t C-b` or `C-t b`). Objects don't turn persistent selection
on, but motions extend what they select.

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

Surround: `C-c e a` adds a pair around each selection (type the
bracket), `C-c e r` replaces one (type the old, then the new), `C-c e d`
deletes one.

### Editing

| Ctrl | | Alt | |
|---|---|---|---|
| `C-d` | Delete forward (or the selection) | `A-d` | Delete backward (or the selection) |
| `C-i` | Indent | `A-i` | Unindent |
| `C-o` | Open a line below | `A-o` | Open a line above |
| `C-u` | Upper-case the selection, or the word | `A-u` | Lower-case it |
| `C-\` | Case: lower, UPPER, Title | `A-\` | Case the other way round |
| `C-z` | Undo | `A-z` | Redo |
| `C-y` | Paste, replacing the selection | `A-y` | Take the paste back, if it's still the last thing done |
| `C-r` | Replace the next match of the search | `A-r` | Replace the previous match |

`C-r` asks what to replace with the first time, and uses that after;
`C-c s e` changes it.

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
| `C-c c` | Text case and shape | `u` upper, `l` lower, `~` switch, `t` Title, `s` snake, `c` camel, `k` kebab, `p` Pascal, `o` sort lines, `r` reflow |
| `C-c e` | Editing | `y` copy (the line, with nothing selected), `x` cut, `P` paste before, `j` join lines, `;` comment, `k` delete the lines, `u` duplicate them, `J` / `K` move them down / up, `a` / `r` / `d` surround add / replace / delete, `.` repeat the last change, `+` / `-` the number at the cursor, `q` record a macro, `@` play it, `"` pick a register, `i` insert a register, `=` reindent, `w` trim the selections |
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
| `C-S-letter` | The same as `C-letter` | Turn on `C-space` first and use the plain motion |
| `C-h` | Some terminals send it for `backspace` | `backspace` still deletes |

## Conflicts with Greed's own keys

Flash binds its keys in its own mode, `flash`. A mode's keys win over the
keys bound for every mode, so inside Flash these work as Flash says, and
everywhere else (other styles, terminals, pickers) Greed's keys are
unchanged. The tests check both sides.

| Key | Greed's default (every mode) | In Flash |
|---|---|---|
| `C-space` | The leader in the VS Code style; the leader from a terminal | Persistent selection. The leader is `alt-space` |
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
  press adds the match. That's Greed's `select-next-match`, as in VS Code.
- Numeric counts are `C-c n N keys` rather than a bare number, since digits
  type in a style without modes. Commands that ignore counts ignore them
  here too.
- `C-=` / `A-=` change the text size in the window client only.
- The style's mode label stays `flash` while persistent selection is on;
  the status line says "Selection on" and "Selection off" as you toggle.
- The key table is written for a US keyboard. On other layouts, the
  punctuation keys (`;` `'` `[` `]` `\` `/` `=` `-`) are where those
  characters are typed with ctrl, which the terminal may not send.

### Tested and not

`greed test` runs 78 tests over: plain and selecting motions, repeated
`C-S-w`, `C-space` on and off, shrinking and crossing the anchor,
f/F/t/T and their repeats (punctuation, space, multi-byte), every text
object, syntax node selection, surround, the jump and its cancelling,
marks, case changes, paste and taking it back, search and replace, line
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
