# A course written in your proof file

Open or create a `.v` or `.lean` file:

```sh
nix run . -- course.v
```

Then use **Space t a** or `:TutorAsk` to enter a question. You can also give the prompt directly:

```vim
:TutorAsk I can program but am new to proofs. Start a course with one small exercise.
:TutorAsk Critique my attempt near the cursor and give me a hint, not the solution.
:TutorAsk Explain why this works and suggest the next exercise.
```

The question is appended as a documentation comment and saved. Codex responds by editing the same file: explanations, exercises, and critiques appear alongside your work. The response is saved automatically. You can use `u` to undo the response as a single change, then `:write` to save that undo. Questions and answers are ordinary readable Unicode source, not hidden metadata.

Continue reading while the tutor thinks. If you change the buffer or its disk file before the reply arrives, the response is discarded rather than overwriting your work. Ask again to continue from the latest file. Save failures leave the response in the buffer and report the error.

| Command | Action |
| --- | --- |
| `:TutorAsk [question]` | Ask, or open the input prompt |
| `:TutorCancel` | Stop the current request and forget its conversation |
| `:TutorReset` | Start the next request from the full current file |

Closing and reopening the file starts a fresh conversation using its contents. This is intentional: the file itself is the course and the history needed to continue it. There are no course sidecars, session IDs, databases, chat transcripts, or inferred learner profiles to preserve.

## Codex connection

Use your installed **Codex CLI**, already logged in with `codex login`. The bridge runs `codex app-server` and uses your configured model and account. No separate API key is needed for an existing ChatGPT login. The CLI must support ephemeral app-server threads and structured turn output; `codex-cli 0.154.0` was used for live validation. The editor and renderer are pinned by Nix; this adapter deliberately uses your existing Codex executable and configuration.

Optional environment settings:

```sh
SF_CODEX_BIN=/absolute/path/to/codex nix run . -- course.v
SF_TUTOR_MODEL=your-model-name nix run . -- course.v
```

To provide an existing book or chapter as a teaching example before starting a conversation:

```vim
:let g:sf_tutor_example = '/absolute/path/to/lf/Basics.v'
:TutorReset
```

That example is sent with the first request. It is not copied into or edited as part of your course. The current course file and example are sent through your Codex account when you ask a question.

## Context and edits

Each buffer has an independent, ephemeral Codex thread. The first request sends the full file, language, cursor line, learner prompt, and optional example. Following requests send a unified diff from the last **successfully applied** reply to the current file, together with the new prompt and cursor. Undo and manual changes are naturally included in that diff.

The [system prompt](prompts/tutor.md) asks for teaching as file edits and preserves learner attempts. Codex returns exact-match replacements or an append. The local bridge rejects missing or ambiguous matches before anything is applied. Neovim checks the buffer revision and disk contents again, applies the response as one undoable buffer change, saves, and only then acknowledges it as the next diff baseline. Failures and cancellations reset the conversation so the next request gets a full snapshot.

The bridge uses the CLI's [app-server interface](https://developers.openai.com/codex/app-server/) with `ephemeral: true`; conversation and diff baselines live in memory. Temporary working directories are removed on normal exit/cancellation. Existing Codex authentication/configuration and provider-side data handling remain those of your Codex installation. No Codex rollout is used as course storage.

## Current scope

Tutoring edits support both Rocq and Lean 4. **Graphical documentation previews and interactive prover integration remain Rocq-only.** Lean files receive ordinary Lean documentation comments and code; this prototype does not yet bundle Lean, its language server, or Lean comment rendering. The tutor is not supplied live prover results and must not claim its edits have been checked. Use Coqtail to inspect Rocq exercises normally.

The older design documents explore a larger event-sourced application. This implementation follows the simpler file-only course model: `.v`/`.lean` content plus the system prompt, with disposable runtime state.

`nix flake check` includes offline checks for Unicode edits, ambiguous replacements, full-file/diff context, saved questions and answers, undo, concurrent edits, disk conflicts, cancellation, and Lean routing. Live Codex smoke tests are separate because they require your login and use model inference.
