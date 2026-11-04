/- Move the cursor through the proof and watch the standard Lean Infoview.
   Try replacing `hP` with `hQ` below to see an error, then undo it. -/

#check Nat

example (P Q : Prop) (hP : P) (hQ : Q) : P ∧ Q := by
  constructor
  · exact hP
  · exact hQ

#eval (List.range 5).map (fun n => n * n)
