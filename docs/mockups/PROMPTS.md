# Graphical mockup generation

These five concepts replace the earlier book-oriented screens. They depict a local, chat-led LearnLean web application with a genuine Neovim terminal and a separate proof inspector. Generated and edited with the built-in `image_gen` tool; no CLI fallback was used. Written UX contracts govern exact behavior. Incidental generated copy and chrome are illustrative, not additional product requirements.

## a-conversation

Final asset: [a-conversation.png](a-conversation.png)

Initial generation prompt:

```text
Use case: ui-mockup. Create a high-fidelity graphical screenshot of LearnLean, a LOCAL conversational Lean learning web application in a macOS Safari window. Landscape 1536x1024, straight-on flat screenshot, crisp readable text, no perspective, no ASCII art. Top bar LearnLean, small Local label, session title Learning through proofs, History and Settings buttons. NO course navigation sidebar, NO book page, NO chapter heading, NO progress percentage.
Shared layout: large LEFT 55% pane is a rich conversation with Tutor and You messages, embedded mathematical concept/exercise cards, always-visible chat composer. RIGHT 45% contains a genuine dark charcoal terminal displaying NEOVIM in upper half and light proof inspector beneath. Real terminal aesthetic: monospace line numbers, tilde filler lines, NORMAL or INSERT mode status line, filename assignment.lean. Do not draw a Monaco-style editor toolbar inside the terminal. Application toolbar outside terminal says Assignment · Neovim and Bridge connected, plus Check and Previous/Next controls. The editor is the learner's chosen tool.
Visual style: light warm gray background, white chat surface, restrained teal primary actions, thin gray dividers, rounded controls, clean sans-serif UI, comfortably spaced content. Rich math diagrams appear inside tutor chat cards, not a separate book. Neovim uses charcoal background and tasteful cyan/purple/yellow syntax colors, teal status line. Inspector has Hypotheses, Goals, Lean messages, explicit selected-step and freshness labels. Tutor speech distinct from exact Lean output. Everything fits within browser, no external annotations or invented navigation.
Screen A: the learner begins an adaptive tutoring conversation. Chat dominates. You: I know Python, but formal proofs are new to me. I want to understand why tactics work. Tutor: Let's start with a small proof and look at what changes. Have you used implications before? You: Only informally.
Tutor rich concept card titled A hypothesis is evidence, with hP : P in a highlighted math block and sentence hP is a proof of P.
Tutor: Try this first. Use the evidence you already have.
Exercise card titled Return the evidence, formula P → P, small provenance label From the material library, button Open in editor.
Tutor: After intro hP, what do you need to prove?
Composer placeholder Ask, try an idea, or change direction… chips Explain differently / Give me a hint / Something harder.
Right Neovim terminal displays:
example (P : Prop) : P → P := by
  intro hP
  exact hP
Highlight intro hP line with gutter marker. Status NORMAL assignment.lean.
Proof inspector label After intro hP · current source. Hypotheses P : Prop, hP : P. Goal ⊢ P. Separate small badge Whole assignment checked. No course progress, no next lesson button.
```

## b-practice

Final asset: [b-practice.png](b-practice.png)

Initial generation prompt:

```text
Use case: ui-mockup. Create a high-fidelity graphical screenshot of LearnLean, a LOCAL conversational Lean learning web application in a macOS Safari window. Landscape 1536x1024, straight-on flat screenshot, crisp readable text, no perspective, no ASCII art. Top bar LearnLean, small Local label, session title Learning through proofs, History and Settings buttons. NO course navigation sidebar, NO book page, NO chapter heading, NO progress percentage.
Shared layout: large LEFT 55% pane is a rich conversation with Tutor and You messages, embedded mathematical concept/exercise cards, always-visible chat composer. RIGHT 45% contains a genuine dark charcoal terminal displaying NEOVIM in upper half and light proof inspector beneath. Real terminal aesthetic: monospace line numbers, tilde filler lines, NORMAL or INSERT mode status line, filename assignment.lean. Do not draw a Monaco-style editor toolbar inside the terminal. Application toolbar outside terminal says Assignment · Neovim and Bridge connected, plus Check and Previous/Next controls. The editor is the learner's chosen tool.
Visual style: light warm gray background, white chat surface, restrained teal primary actions, thin gray dividers, rounded controls, clean sans-serif UI, comfortably spaced content. Rich math diagrams appear inside tutor chat cards, not a separate book. Neovim uses charcoal background and tasteful cyan/purple/yellow syntax colors, teal status line. Inspector has Hypotheses, Goals, Lean messages, explicit selected-step and freshness labels. Tutor speech distinct from exact Lean output. Everything fits within browser, no external annotations or invented navigation.
Screen B: learner actively proving a conjunction with an error. Chat You: I think exact hQ should solve the left goal. Tutor: Let's compare the evidence with the goal before choosing a tactic. Rich card titled Two pieces of evidence showing a small graphical tree P ∧ Q branching into P and Q. Below Tutor: What is the type of hQ? Does it match the left goal? Buttons Smaller hint / Show a suggestion. Composer Ask about this step…
Right Neovim terminal displays exact code:
example (P Q : Prop) (hP : P) (hQ : Q) : P ∧ Q := by
  constructor
  · exact hQ
  · exact hQ
First exact hQ line has red underline and error gutter indicator. NORMAL assignment.lean. Outside terminal: Recorded · needs work. Controls Previous / Next / Check.
Inspector title Before failing tactic · current source. Hypotheses hP : P and hQ : Q. Current goal ⊢ P, Other goal ⊢ Q. Amber After-state unavailable. Separate red Lean messages card Type mismatch: hQ has type Q; expected P. No completion badge.
```

Final refinement prompt (applied to the inspected initial image):

```text
Edit this LearnLean UI mockup only in the concept card in the left conversation pane. Preserve all other layout, terminal proof, colors, messages, and controls. The card currently teaches elimination and has incorrect lowercase and.left/and.right code, but this scene needs conjunction introduction. Replace its contents with title 'Two pieces of evidence', subtitle 'To prove P ∧ Q, prove each part.', a simple diagram labeled 'Goal: P ∧ Q' branching down to 'Goal: P' and 'Goal: Q'. Label the branching connector 'constructor'. Remove every reference to and.left, and.right, h : P ∧ Q and elimination/projections. Under the diagram use only 'Use hP for P and hQ for Q.' Keep the followup question outside the card unchanged. This is a conceptual exercise screenshot.
```

## c-adaptation

Final asset: [c-adaptation.png](c-adaptation.png)

Initial generation prompt:

```text
Use case: ui-mockup. Create a high-fidelity graphical screenshot of LearnLean, a LOCAL conversational Lean learning web application in a macOS Safari window. Landscape 1536x1024, straight-on flat screenshot, crisp readable text, no perspective, no ASCII art. Top bar LearnLean, small Local label, session title Learning through proofs, History and Settings buttons. NO course navigation sidebar, NO book page, NO chapter heading, NO progress percentage.
Shared layout: large LEFT 55% pane is a rich conversation with Tutor and You messages, embedded mathematical concept/exercise cards, always-visible chat composer. RIGHT 45% contains a genuine dark charcoal terminal displaying NEOVIM in upper half and light proof inspector beneath. Real terminal aesthetic: monospace line numbers, tilde filler lines, NORMAL or INSERT mode status line, filename assignment.lean. Do not draw a Monaco-style editor toolbar inside the terminal. Application toolbar outside terminal says Assignment · Neovim and Bridge connected, plus Check and Previous/Next controls. The editor is the learner's chosen tool.
Visual style: light warm gray background, white chat surface, restrained teal primary actions, thin gray dividers, rounded controls, clean sans-serif UI, comfortably spaced content. Rich math diagrams appear inside tutor chat cards, not a separate book. Neovim uses charcoal background and tasteful cyan/purple/yellow syntax colors, teal status line. Inspector has Hypotheses, Goals, Lean messages, explicit selected-step and freshness labels. Tutor speech distinct from exact Lean output. Everything fits within browser, no external annotations or invented navigation.
Screen C: adaptive learning decision inside conversation. Chat You: I can copy the steps, but I still don't understand why constructor makes two goals. Tutor: Let's pause and connect it to pairs. You do not need a new tactic yet.
Rich tutor card title Two pieces of evidence. Diagram P ∧ Q with two connected rounded cards Proof of P and Proof of Q. Small tag From the material library. Short explanation A proof of a conjunction contains both pieces.
Tutor: Which hypothesis would fill each side? Reply in words before we edit. Learner message hP goes on the left; hQ goes on the right.
Tutor: Exactly. We can try a fresh version, revisit hypotheses, or move to rewriting. Recommendation Try a fresh version, small caption To check the idea without copying. Chips Try that / Revisit hypotheses / Change topic. This is a personal choice in chat, NOT a rigid curriculum.
Right Neovim still shows correct conjunction assignment:
example (P Q : Prop) (hP : P) (hQ : Q) : P ∧ Q := by
  constructor
  · exact hP
  · exact hQ
NORMAL assignment.lean, label Current assignment preserved. Inspector after constructor, hypotheses hP : P hQ : Q, goals ⊢ P and ⊢ Q. Chat remains most prominent.
```

Final refinement prompt (applied to the inspected initial image):

```text
Edit this screenshot with one targeted proof inspector text correction. Preserve everything else exactly. In the inspector's Selected step card replace 'Line 2: constructor' with 'After constructor · line 2' and replace the erroneous badge 'Freshness: used' with 'Current source'. Do not alter chat, code, diagram, layout, colors, or any other text.
```

## d-review

Final asset: [d-review.png](d-review.png)

Initial generation prompt:

```text
Use case: ui-mockup. Create a high-fidelity graphical screenshot of LearnLean, a LOCAL conversational Lean learning web application in a macOS Safari window. Landscape 1536x1024, straight-on flat screenshot, crisp readable text, no perspective, no ASCII art. Top bar LearnLean, small Local label, session title Learning through proofs, History and Settings buttons. NO course navigation sidebar, NO book page, NO chapter heading, NO progress percentage.
Shared layout: large LEFT 55% pane is a rich conversation with Tutor and You messages, embedded mathematical concept/exercise cards, always-visible chat composer. RIGHT 45% contains a genuine dark charcoal terminal displaying NEOVIM in upper half and light proof inspector beneath. Real terminal aesthetic: monospace line numbers, tilde filler lines, NORMAL or INSERT mode status line, filename assignment.lean. Do not draw a Monaco-style editor toolbar inside the terminal. Application toolbar outside terminal says Assignment · Neovim and Bridge connected, plus Check and Previous/Next controls. The editor is the learner's chosen tool.
Visual style: light warm gray background, white chat surface, restrained teal primary actions, thin gray dividers, rounded controls, clean sans-serif UI, comfortably spaced content. Rich math diagrams appear inside tutor chat cards, not a separate book. Neovim uses charcoal background and tasteful cyan/purple/yellow syntax colors, teal status line. Inspector has Hypotheses, Goals, Lean messages, explicit selected-step and freshness labels. Tutor speech distinct from exact Lean output. Everything fits within browser, no external annotations or invented navigation.
Screen D: tutor proposes a source edit, learner reviews it inside CHAT not a modal covering everything. Chat You: Show me the smallest fix. Tutor: Use the hypothesis whose type matches the left goal.
Large inline card Review suggested change, subtitle Pair the evidence. Unified monospace diff:
  constructor
- · exact hQ
+ · exact hP
  · exact hQ
Red deletion, green addition, actual +/- indicators. Badge Checked on a temporary copy. Note Your editor has not changed. Buttons Apply in Neovim (teal) / Dismiss.
Below small tutor text Applying this is one undoable edit. Composer Ask about this change…
Right Neovim displays original wrong proof first exact hQ and second exact hQ with red first error. NORMAL assignment.lean. Inspector before failing tactic, hP : P, hQ : Q, ⊢ P, other goal ⊢ Q. No incorrect success indicator on current source. Make rich chat patch card clear and prominent.
```

## e-resume

Final asset: [e-resume.png](e-resume.png)

Initial generation prompt:

```text
Use case: ui-mockup. Create a high-fidelity graphical screenshot of LearnLean, a LOCAL conversational Lean learning web application in a macOS Safari window. Landscape 1536x1024, straight-on flat screenshot, crisp readable text, no perspective, no ASCII art. Top bar LearnLean, small Local label, session title Learning through proofs, History and Settings buttons. NO course navigation sidebar, NO book page, NO chapter heading, NO progress percentage.
Shared layout: large LEFT 55% pane is a rich conversation with Tutor and You messages, embedded mathematical concept/exercise cards, always-visible chat composer. RIGHT 45% contains a genuine dark charcoal terminal displaying NEOVIM in upper half and light proof inspector beneath. Real terminal aesthetic: monospace line numbers, tilde filler lines, NORMAL or INSERT mode status line, filename assignment.lean. Do not draw a Monaco-style editor toolbar inside the terminal. Application toolbar outside terminal says Assignment · Neovim and Bridge connected, plus Check and Previous/Next controls. The editor is the learner's chosen tool.
Visual style: light warm gray background, white chat surface, restrained teal primary actions, thin gray dividers, rounded controls, clean sans-serif UI, comfortably spaced content. Rich math diagrams appear inside tutor chat cards, not a separate book. Neovim uses charcoal background and tasteful cyan/purple/yellow syntax colors, teal status line. Inspector has Hypotheses, Goals, Lean messages, explicit selected-step and freshness labels. Tutor speech distinct from exact Lean output. Everything fits within browser, no external annotations or invented navigation.
Screen E: returning to a personal session, with a narrow history drawer occupying far right 32%, conversation visible in left 48% and Neovim partially visible middle 20%. Main chat Tutor: Welcome back. We were connecting conjunctions to pairs. Your assignment is ready; Lean is rechecking it. You: Let's try one without hints. Rich exercise card Swap the evidence, formula Q ∧ P, buttons Start this / Stay with current proof. Composer Continue the conversation…
History drawer title Your learning path. Timeline items: Asked about hypotheses; Tried a conjunction; Discussed pairs; Practised without a hint. This is session history, not a course syllabus.
Lower drawer title Saved source, entries 10:42 Applied suggestion, 10:38 Edited proof selected. Preview code constructor / · exact hQ / · exact hQ. Amber Rechecking this saved source… . Buttons Restore in Neovim / Close. Caption Restoring adds a new revision and keeps the conversation.
Visible center dark Neovim terminal includes NORMAL assignment.lean. App top Local, History active. No course chapter menu or completion percentages.
```

Final refinement prompt (applied to the inspected initial image):

```text
Correct this LearnLean recovery screenshot while preserving the overall graphical design, chat-first layout, terminal column, and history drawer. Make the following precise state/content changes: (1) Replace the long initial tutor recap and its Conjunctions and pairs math card with a compact neutral APPLICATION status card (not a new Tutor message), titled 'Session restored' and text 'Your conversation and assignment are back. Lean is rechecking the saved source.' Under it show one historical Tutor message 'A conjunction needs evidence for both parts.' Remove every occurrence of P × Q, equivalence signs, pair notation, and projections. (2) The next User message stays 'Let’s try one without hints.' The next tutor exercise card is 'Swap the evidence', statement 'Given hP : P and hQ : Q, prove Q ∧ P.', and buttons 'Start this' and 'Stay with current proof'. Do not show its solution. (3) The center terminal must still show the PRIOR assignment, with code exactly 'example (P Q : Prop) (hP : P) (hQ : Q) : P ∧ Q := by' then '  constructor' then '  · exact hP' then '  · exact hQ'. Neovim status NORMAL assignment.lean. (4) The inspector is pending after restart: remove all displayed hypotheses/goals and any Fresh badge. Show a large amber pending card 'Rechecking current source…' with text 'Proof state will appear when Lean finishes.' (5) In history show 10:42 Applied suggestion collapsed, then 10:38 Edited proof expanded selected. Put the preview containing constructor / · exact hQ / · exact hQ and 'Rechecking this saved source…' under 10:38, not 10:42. Retain Restore in Neovim and Close. Keep this readable and polished.
```


