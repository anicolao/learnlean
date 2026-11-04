/-!
# Proving a conjunction

Lean checks your proof as you edit. Move the cursor through the tactics below
and watch the **goals and hypotheses** in the Infoview.

- Use `constructor` to split a conjunction into two goals.
- Use `exact` to supply a proof of each goal.
- Press `zo` on this preview to edit its Markdown; `zc` closes the source again.

Your explanations and proofs stay together in this ordinary `.lean` file.
-/

#check Nat

/-- Return the **square** of a natural number. -/
def square (n : Nat) : Nat := n * n

/-!
## Try the proof

Replace `exact hP` with `exact hQ` to see a type error, then undo.
The source stays editable while the Infoview displays Lean's feedback.
-/
example (P Q : Prop) (hP : P) (hQ : Q) : P ∧ Q := by
  constructor
  · exact hP
  · exact hQ

#eval (List.range 5).map square
