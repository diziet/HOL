signature hhsMinimize =
sig

  include Abbrev

  datatype Proof = 
    Tactic of (string * goal)
  | Then   of (Proof * Proof)
  | Thenl  of (Proof * Proof list)

  val hhs_prettify_flag : bool ref
  val hhs_minimize_flag : bool ref
  val minimize : Proof -> Proof
  val reconstruct : goal -> Proof -> string

end
