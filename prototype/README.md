# Rocq documentation prototype

Read Software Foundations as formatted content inside Neovim, open a documentation comment to edit its source, and see its preview update without saving. Proof code remains editable in the same ordinary `.v` file. Coqtail provides Rocq execution and goal panels.

From the repository root, with Nix flakes enabled:

```sh
nix run . -- lf/Basics.v
```

This runs the pinned Neovim in your **current terminal or tmux pane**. Use Kitty for graphical previews. The first run downloads or builds dependencies. `nix run .#nvim -- lf/Basics.v` is an equivalent explicit command.

For tmux, graphics passthrough must already be enabled. The plugin uses image.nvim's tmux support and hides previews when switching tmux windows. The [upstream configuration recommendations](https://github.com/3rd/image.nvim#tmux) are:

```tmux
set -g allow-passthrough on
set -g visual-activity off
set -g focus-events on
```

Your tmux settings are not modified by the launcher. If you prefer a separate Kitty window, that remains available:

```sh
nix run .#kitty -- lf/Basics.v
```

The flake pins Rocq, its standard library, Coqtail, Neovim, image.nvim, Kitty, fonts, and the rendering tools through the copied `flake.lock`. `nix develop` exposes the same tools. Run from this root so LF's project paths resolve as expected.

## Reading and editing

Standalone `(** … *)` documentation starts collapsed. Its rendered preview appears in the source window with a small `▸` control in the gutter; ordinary `(* … *)` prose comments and proof code stay visible. Decorative separator comments such as `(* #### *)` and `(* ==== *)` are hidden in the rendered view; `zR` or `:SFDocsDisable` reveals them without changing the file. Place the cursor on a documentation header or its source and use:

| Key / command | Action |
| --- | --- |
| Click the gutter triangle | Toggle source visibility |
| `zo` / `:SFDocsOpen` | Show the original comment for editing |
| `zc` / `:SFDocsClose` | Collapse the source again |
| `za` / `:SFDocsToggle` | Toggle source visibility |
| `zR` / `zM` | Open / close all documentation |
| `:SFDocsDisable` / `:SFDocsEnable` | Switch between plain source and previews |
| `:SFDocsRefresh` | Rebuild previews |
| `:SFDocsHealth` | Show renderer and graphics status |

The collapsed preview occupies the source header row without a separate fold-summary line. Use `zo`/`za` on that row or click its gutter triangle; entering Insert mode there also exposes the source. When open, the preview appears after the comment, so source and output can coexist. During Insert/Replace mode, previews stay frozen while you type. Press Escape to return to Normal mode and refresh from the unsaved text. Changes made in Normal mode (including tutor edits) use a 250 ms debounce. The plugin renders visible blocks first, then complete documentation comments beginning within roughly 1,000 source characters below the viewport. Pre-rendered previews reserve their screen space before you reach them, and that space is retained when they scroll out of view. An incomplete comment has no preview until its closing delimiter is restored. Save normally with `:write`; previewing never saves or rewrites source.

Rendering uses **coqdoc syntax**, including section headings, `_emphasis_`, `[inline code]`, lists, and displayed examples. It is not Markdown. Images are display-only: edit or copy the underlying source. Neovim motions operate on source lines, so moving past a comment can jump past its preview.

The inherited Coqtail controls use Space as leader:

| Keys | Action |
| --- | --- |
| `Space c j` / `Alt-Down` | Check the next sentence |
| `Space c k` / `Alt-Up` | Undo a checked sentence |
| `Space c l` | Check to cursor |
| `Space c r` | Restore goal panels |
| `Space c c` / `Space c q` | Start / stop Rocq |

Rocq starts automatically for `.v` files. Documentation rendering and proof execution are independent.

## How it works

`lua/sf_docs/parser.lua` scans nested comments and strings. The Neovim plugin tracks comment locations with extmarks and maintains source folds. A persistent local Python worker receives comment text, runs the pinned coqdoc, lays out HTML with WeasyPrint, and rasterizes it with Poppler. image.nvim displays the PNG through Kitty's graphics protocol, reserving virtual lines in the source window.

The graphical view uses Neovim line concealment to hide the comment body completely. Its first source line remains a blank image anchor with a gutter triangle. A small, pinned image.nvim patch places the image on that anchor row and reserves only the remaining image height, eliminating both extra fold rows. Opening restores the original text and moves the preview below it. Ordinary native folds remain the fallback outside Kitty. Comments sharing a line with executable code are never concealed, so code cannot disappear with documentation.

Images, HTML, PDFs, and caches live in a worker-owned temporary directory and memory. They are disposable and rebuilt from source; graceful worker exit removes the directory. A force-killed process may leave temporary files for OS cleanup. No database, durable rendered state, or event log is introduced by this prototype.

## Scope and validation

This prototype targets **Kitty, directly or through tmux with graphics passthrough**, and one visible window per source buffer. Other terminals retain source/fold controls but do not show graphics. Previews have transparent backgrounds, so the terminal background shows through. Text colors follow Neovim’s detected light/dark mode and refresh when `background` changes. If detection needs correcting, use `:set background=light` or `:set background=dark`. Very tall comments exceeding the renderer's 30,000-pixel layout limit must be split. Rendering blocks separately means cross-document navigation, clickable links, full book layout, and document-wide section numbering are not provided.

The `lf/` tree is copied from `SoftwareFoundations/take4/lf`, including existing edits and generated files. The starting flake and lock came from its parent `take4/`. Its original license and book documentation remain in `lf/`. The original tree is untouched.

```sh
nix flake check --print-build-logs
```

Checks exercise coqdoc formatting, actual PNG output, cache invalidation and cleanup, parser edge cases, fold behavior, unchanged source bytes, and unsaved edits. The graphical path also received a live Kitty/Neovim smoke test on Apple Silicon macOS: rendered images, opening/editing/closing a comment, updating without saving, resizing, and Coqtail startup/execution. Headless checks do not validate terminal compositing; Linux and Intel macOS remain untested.

The prototype now includes a [Codex tutor that writes directly into the course file](TUTOR.md). Use `:TutorAsk` or **Space t a**. Questions, explanations, exercises, and critiques are saved in the `.v` or `.lean` file; the conversation and diff baseline are disposable in-memory state.

## Clearing orphaned terminal graphics

If graphics from an older run are stuck over the terminal, exit the editor and run:

```sh
nix run .#clear-previews
```

This sends Kitty's explicit image-delete command through tmux when applicable. It clears visible graphics in the enclosing terminal (including graphics in other tmux panes), not file content. A normal shell `clear` inside tmux may only redraw text. The updated renderer flushes graphics commands in order and explicitly deletes its owned image IDs, including hidden images, on exit.


## Trying text-anchored previews in tmux

Inside tmux, previews now use Kitty Unicode placeholders in Neovim virtual text
and virtual lines. Neovim draws the cells and tmux scrolls/clips/hides them like
text; Kitty supplies the image pixels. No placeholder characters are saved in
course files. Opening comments and the Insert-mode pause work as before.

Restart with the usual command:

```sh
nix run . -- lf/Basics.v
```

`:SFDocsHealth` reports `mode = "placeholders"`. To compare either backend
explicitly (also works outside tmux):

```sh
SF_DOC_GRAPHICS=placeholders nix run . -- lf/Basics.v
SF_DOC_GRAPHICS=overlay nix run . -- lf/Basics.v
```

This experimental mode enables truecolor to encode image IDs; tmux must preserve
RGB colors (Kitty clients normally advertise this). The existing palette-only
syntax theme may look different in truecolor; the green proof highlight retains
its RGB definition. No tmux settings are changed. Normal overlay mode remains the
default outside tmux. After attaching a different terminal to an existing session,
use `:SFDocsRefresh` to upload images to that terminal.

Old overlays are independent of the new placeholders: exit the old editor and
run `nix run .#clear-previews` once before trying this mode if any remain.

Validation includes headless checks for source preservation, long-comment tiling,
editing pauses, and image cleanup, plus a live Kitty/tmux protocol check with
focus events off, scrolling, window switching, and pane splitting. Display capture
was unavailable, so visual appearance still needs manual review.
