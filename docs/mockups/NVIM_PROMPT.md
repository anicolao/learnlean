# Neovim-first mockup prompt

Asset: [nvim-embedded.png](nvim-embedded.png)

Generated and refined with the built-in `image_gen` tool. This is an illustrative design concept, not a running implementation or evidence of graphics compatibility.

## Initial generation

```text
Use case: ui-mockup. High-fidelity conceptual screenshot of Neovim running directly inside a macOS Kitty terminal window, landscape 1536x1024. No browser, no web app chrome, no outer chat application. A sophisticated dark terminal theme, crisp monospace text, thin split dividers, real Neovim tabline/statusline and line-number gutter. Primary wide left 72% is a NORMAL EDITABLE FILE named evidence.lean, right 28% is Lean infoview. Main file is an ordinary Lean source buffer whose tutor annotations are plugin-rendered blocks placed BETWEEN source lines, with blank line-number gutter beside annotation pixels. Top small tabs evidence.lean and Tutor history. Source near top:
-- Building a conjunction
example (P Q : Prop) (hP : P) (hQ : Q) : P ∧ Q := by
  constructor
  · exact hP
  · exact hQ
Highlight constructor in source. Below source show one collapsed text annotation heading '▸ Tutor · Why does exact work?'. Then one expanded annotation headed '▾ Tutor · Two goals after constructor'. Annotation contains plain text 'To prove a conjunction, provide evidence for both parts.' and a REAL GRAPHICAL IMAGE embedded inside terminal: rendered rounded rectangle P ∧ Q with lines branching down to rounded rectangles P and Q, teal and soft blue accents, smooth antialiased edges; it must look like a pixel graphic not ASCII. Caption 'Graphic · text alternative available'. Annotation block is visibly different dark shade; no line numbers in annotation. Right infoview 'After constructor · current source', 'Hypotheses', 'P Q : Prop', 'hP : P', 'hQ : Q', 'Goals (2)', '⊢ P', '⊢ Q'. Lower-right small 'Lean messages' 'No errors'. Statusline NORMAL evidence.lean · Lean connected · Recorded.
At bottom-center OVER the source show a modest Neovim floating text input window about 65% width, heading 'Ask tutor', context chip 'evidence.lean · after constructor'. Text question 'Why are there two goals here?'. Footer 'Ctrl-Enter Send · Esc Close'. It must look like a real Neovim float, simple thin border and monospace text, not web UI rounded composer. Preserve visible graphic above float. Screenshot represents a proposed UX, not implementation evidence. No invented keyboard keys beyond specified. All text legible. Small tasteful macOS traffic-light title bar 'Kitty — LearnLean'.
```

## Final refinement

```text
Edit this Neovim concept mockup only to correct source-line numbering and composer help. Tutor annotations and graphical rows are VIRTUAL, not source: remove gutter line numbers 7 and 8 next to both Tutor headers, leaving their gutter completely blank. The blank source line below the graphical block currently numbered 9 should be 7; the comment currently numbered 10 should be 8; the #check line currently numbered 11 should be 9. All annotation and graphic rows must have NO source line numbers. Replace composer footer 'Ctrl-Enter Send · Esc Close' with 'Ctrl-Enter Send · Normal: q Close'. Preserve every other element, layout, diagram, code, text and colors exactly.
```

