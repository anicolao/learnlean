# Stock Lean in Neovim

This trial runs the upstream `lean.nvim` setup with its suggested mappings and
normal Infoview. It has no Rocq plugins, tutor, custom theme, proof-panel layout,
or graphical documentation previews. The existing flake lock supplies Lean
4.28.0, Neovim 0.11.6, `lean.nvim`, and its dependencies; no host Lean, Lake,
Elan, or Neovim installation is needed.

Run in your current terminal (Kitty and tmux are not required):

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
