# ncdiff

`ncdiff` is a metadata-first terminal diff explorer for two directory trees.

## Design

- Recursive directory comparison with synchronized left and right tree columns.
- Folders start collapsed. Optional in-place expansion exists, but it is disabled by default.
- Pressing `Enter` on a folder re-roots the comparison into that folder, making it the new top level until you go back up.
- Initial file comparison uses file attributes only: type, size, mode, and nanosecond mtime.
- Displayed sizes are human-readable by default.
- Every row is shown on both sides. Missing entries render as `-` in red, one-sided entries as `+` in cyan, changed pairs as `!` in yellow, and type mismatches as `~` in magenta.
- Files with differing metadata are highlighted without paying the full content-diff cost up front.
- Directories inherit a changed state when any descendant differs.
- Pressing `Enter` on a changed file opens a full-screen ncurses side-by-side text diff.
- Diff mode keeps left and right file status aligned in separate footer panes, including type, size, mode, and mtime.
- When both sides exist, the mtime footer marks the newer side with `(new)` and the older side with `(old)`.
- `s` toggles recursive directory size calculation and shows those sizes inline in the browser list, `ncdu`-style.
- `c` toggles descendant file and directory counts.

## Build

```sh
make
```

## Run

```sh
./ncdiff /path/to/left/tree /path/to/right/tree
```

## Keys

- Browser mode:
- `Up` / `Down`: move
- `j` / `k`: move
- `Right`, `l`, or `Enter` on a folder: enter that folder as the new comparison root
- `Right`, `l`, or `Enter` on a file: open a side-by-side diff
- `Left`, `h`, `Backspace`, or `u`: go up to the parent comparison root
- `e`: enable or disable optional in-place folder expansion
- `s`: toggle recursive directory sizes
- `c`: toggle descendant file/folder counts
- `Space`: expand or collapse the selected folder when expansion mode is enabled
- `PgUp` / `PgDn`: jump
- `r`: rescan the trees
- `q`: quit
- Diff mode:
- `Up` / `Down`: scroll
- `j` / `k`: scroll
- `PgUp` / `PgDn`: page
- `s`: toggle recursive directory sizes
- `c`: toggle descendant file/folder counts
- `Left`, `h`, `q`, or `Esc`: return to the browser
