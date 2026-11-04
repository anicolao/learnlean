# Lean in Neovim with formatted documentation

This runs the upstream `lean.nvim` setup with its suggested mappings and normal
Infoview, plus formatted documentation in the source buffer. The existing flake
lock supplies Lean 4.28.0, Neovim 0.11.6, the Markdown/PNG renderer, and plugin
dependencies. No host Lean, Lake, Elan, or Neovim installation is needed.

Run in your current terminal (Kitty is needed for graphical previews; other terminals show folded source):

```sh
nix run .#lean
```

Or start a Nix-supplied Kitty window:

```sh
nix run .#lean-kitty
```

With no arguments, either launcher creates a new writable `lean-trial.XXXXXX`
project in the current directory and opens `Main.lean`. It is kept after exit,
and repeated launches create separate directories without overwriting anything.
The project path is printed when it is created. Reopen it with:

```sh
nix run .#lean -- ./lean-trial.XXXXXX/Main.lean
```

You can also pass an existing Lean file. This trial always uses the Nix-pinned
Lean version; it does not install a different toolchain for an existing project's
`lean-toolchain`. Start with the generated example to avoid project-version or
external-library dependencies. Mathlib is not included.

## What to try

Move the cursor through `constructor`, `exact hP`, and `exact hQ` in the example.
The Infoview displays the goals and hypotheses for the cursor position. Change
`exact hP` to `exact hQ` to see a type error, then undo. Move to `#check` and
`#eval` to inspect their messages.

The upstream local leader is the backslash key (`\`), not the Space prefix used
by our Rocq prototype:

- `\i`: toggle the Infoview (`:LeanInfoviewToggle`).
- `\p`: pause/resume the Infoview.
- `\x`: pin the current position for comparison.
- `\c`: clear pins.
- `:LeanGoal`: show the goal at the cursor in a popup.
- `Ctrl-W w`: switch between source and Infoview.

Lean rechecks changes automatically; there is no Rocq-style sentence execution
step. See the [upstream plugin](https://github.com/Julian/lean.nvim) for more.

## Validation

`nix build .#checks.aarch64-darwin.lean` (replace the system as appropriate)
builds the sample with Lake and starts the actual Lean language server through
the packaged Neovim. It checks Infoview creation, proof-goal requests, messages,
and diagnostics after an unsaved invalid edit.

## Formatted source comments

`/-! ... -/` module documentation and `/-- ... -/` declaration documentation
render as Markdown: headings, emphasis, lists, inline code, and fenced code.
Ordinary `/- ... -/` and `--` comments stay as source. Verso-specific roles and
checked documentation extensions are not interpreted by this Markdown preview.

- `zo` opens documentation for editing; `zc` closes it; `za` toggles it.
- Previews remain still during Insert mode and refresh on Escape, without saving.
- `zR` opens all documentation; `zM` closes it.
- `:SFDocsRefresh` rebuilds previews; `:SFDocsDisable` shows the plain source.

The source file contains only Lean text. Palette-based Kitty placeholders work
in a direct Kitty window or through tmux; RGB support is not required. The Lean
Infoview and its normal mappings remain available. This launcher still does not
load the LLM tutor.
