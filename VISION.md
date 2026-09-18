# LearnLean: product vision

## Purpose

Make learning Lean a conversation grounded in visible proof activity. The tutor notices what the learner is trying to understand, chooses an appropriate next encounter, and adapts its explanation while the learner works with real tools.

The central product is a dialogue with a workspace. The LLM can present a concept, pose a question, open an exercise, compare proof states, or offer a different approach. Rich materials enter the conversation when useful. Each learner's sequence emerges from their questions, attempts, preferences, and responses.

## Who it serves

The initial learner is comfortable with programming and curious about formal proofs. They want to understand why a tactic changes a goal, not merely complete a sequence of code puzzles. Some already have a preferred editor; using it should make the learning environment feel familiar.

The MVP focuses on a single person using their own computer. Neovim is the first supported editor integration. The application supplies a working configuration, and the learner can opt into their own configuration without changing the overall interaction model.

## The conversation drives the session

A learner might begin: “I know Python, but formal proof is new to me.” The tutor asks a small diagnostic question, shows what a hypothesis means, and presents an implication exercise. After a successful attempt, it asks the learner to explain the transition. The learner's answer may lead to conjunctions, another implication, or a visual explanation of evidence.

A different learner might begin with induction and discover that rewriting is the real obstacle. The tutor can move directly to a rewriting exercise and later return to induction. There is no mandatory onboarding quiz, fixed syllabus, or linear completion bar.

The learning loop is:

1. **Discuss:** establish an intention or investigate a difficulty.
2. **Encounter:** present a concept, example, diagram, or assignment suited to that intention.
3. **Try:** work in the embedded editor, using its normal commands.
4. **Inspect:** connect source positions to Lean's hypotheses, goals, and diagnostics.
5. **Explain:** articulate what changed; request a hint or challenge the tutor's account.
6. **Adapt:** deepen, revisit, change representation, or move on.

The tutor makes bounded decisions at natural conversational points. It does not narrate every keystroke, interrupt typing with unsolicited messages, or start solving exercises in the background. A learner can ask “stay with this proof” or “something harder” at any time.

## Lessons from MathPub

[MathPub's agentic vision](../mathpub/AGENTIC_VISION.md) places conversation ahead of tool mechanics: the person states an intention and reviews the actual result. Its [workspace](../mathpub/GUI_DESIGN.md) couples an ordinary terminal with a synchronized visual surface. Its [component lexicon](../mathpub/COMPONENT_LEXICON_DESIGN.md) treats content as reusable objects connected by concepts.

LearnLean applies those ideas to learning. The chat is the main interface; a terminal hosts the learner's editor; Lean provides the synchronized view. Feedback on a goal or tactic carries its precise source context back into the dialogue. A material catalog supports the tutor, without becoming a table of contents the learner must follow.

MathPub is a reference for interaction and integration patterns. Its publication workflow, PDF pipeline, validation manifests, and implementation choices are not adopted wholesale, particularly where they differ from this project's event-sourcing requirements.

## Product principles

### Make adaptation visible and negotiable

When the tutor chooses a new exercise, give a brief reason: “Let's try a second example to check the idea without copying.” Offer meaningful alternatives, and accept free-form redirection. The learner should understand the next action without being shown an internal mastery score.

Separate evidence from inference. A checked proof shows that a particular statement was proved under a particular environment. It does not establish that the learner understood it. Reflections and transfer exercises help the tutor form a provisional view, which the learner can correct.

### Use rich material inside the dialogue

Conversation turns can contain mathematics, diagrams, source excerpts, expandable explanations, and exercise cards. Selecting an assignment opens the working file beside the conversation; the prompt remains anchored in chat. The learner can return to an earlier explanation without losing the current proof.

The initial library provides reliable material for hypotheses, implications, conjunctions, equality, and induction. These are coverage areas, not chapters. Components have concept links, prerequisites, suitable hints, and checked examples. The tutor can reuse them, choose parameterized variants, or propose a new small exercise when there is a gap.

New exercise proposals require a coherent statement and a reference solution checked by Lean before being offered as ready to practice. This establishes solvability, not the quality of the teaching or correctness of all accompanying prose. If validation is unavailable, keep the proposal in a pending state or choose a library exercise.

### Let people use their tools

The embedded terminal is a real PTY running a real editor. Neovim motions, modes, undo, search, splits, and commands remain recognizable. The surrounding application supplies conversation and proof inspection, not a replacement text editor.

A small editor adapter supplies semantic integration: current assignment, unsaved source changes, cursor and selection, and accepted patches. The long-term contract supports other editors. In the MVP, any terminal program can be displayed, while only Neovim promises live buffer integration. Other editors can use a clearly labeled saved-file fallback.

### Keep proof evidence precise

Show the difference between the current buffer, the selected proof step, and the result of checking the whole assignment. A complete proof can still have open goals at an earlier selected step. Old results remain explicitly stale until refreshed.

The tutor can explain or suggest; Lean checks formal claims. Reviewed patches change source only when accepted. A learner can reveal a solution without the environment pretending that this demonstrates independent understanding.

### Run locally and reproduce the environment

The learner launches one Nix application on their own machine. The flake pins the toolchain and integrations, avoiding a collection of manually coordinated installations. The local application owns its session log, material library, PTY, Neovim, and Lean processes.

The configured LLM can be remote or local. Remote service behavior is not made deterministic by Nix, so received responses must be retained. Hosted accounts, classroom tenancy, process isolation, and public-service hardening are outside the MVP. Focus on launch reliability, interruption recovery, and a responsive proof loop.

### Recover the actual learning history

Record source inputs, learner messages, received model responses, presented material references, and deliberate teaching actions. Rebuild the transcript, assignment state, and path from that history. Recompute proof results and inferred progress; keep those projections disposable.

Preserving a path means remembering which materials were actually presented, not asking a model to invent a similar route on restart. Replay must not call a provider or generate a different exercise. The learner can restore an assignment revision while retaining the surrounding conversation.

## MVP scope

Deliver one complete adaptive learning loop: initial conversation, material selection, assignment activation, Neovim editing, proof-state inspection, contextual discussion, accepted suggestion, and restart recovery. Seed the catalog with roughly 10–15 small reviewed materials across the five coverage areas; do not turn that count into a mandatory sequence.

Include a provider adapter, Nix-packaged local service, terminal/editor integration, Lean adapter, SQLite event log, graphical chat cards, and recoverable history. A browser UI on macOS is the first experience; Linux compatibility is a packaging target. A native shell can follow once the loop works.

Defer collaboration, hosted execution, authentication systems, security-boundary engineering, mobile terminal optimization, full local-model installation, unrestricted course generation, and adapters for every editor. Broader Lean projects can follow the initial small-assignment model.

## Success criteria

Proposed pilot gates, not measured claims:

- A learner with Nix and a configured model endpoint launches the workspace without separately installing Lean, Neovim, or a database.
- The tutor can take two learners with different initial goals through different coherent paths using the same material library.
- In a pilot of 8–12 learners, at least 70% can explain a selected tactic transition and solve a nearby transfer exercise without revealing its solution.
- Learners can redirect the tutor, ask for a different explanation, and keep an assignment open while discussing something else.
- Neovim editing, cursor inspection, and a reviewed patch work without losing normal undo behavior or confusing stale and current source.
- After deleting all projections and runtime files, every acknowledged edit, received response, and presented assignment is recovered; Lean results visibly recheck.
- A terminal restart, model outage, or Lean failure leaves the rest of the session usable and source recoverable.

Gather interviews and calculate pilot measures from recorded events when needed. Avoid durable calculated mastery profiles. The purpose of the pilot is to establish learning value and usable integration, not maximize exercise completion counts.

## Questions to resolve through prototypes

The highest-priority uncertainties are reliable unsaved-buffer synchronization, clear attention and focus across chat and terminal, the right moments for tutor initiative, and accurate tactic-boundary inspection. Validate those before growing the content catalog or adding a desktop wrapper.
