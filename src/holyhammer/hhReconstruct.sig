signature hhReconstruct =
sig

  include Abbrev
  val get_lemmas : (string * string) -> (string * string) list option
  val get_lemmas_new : (string * string) -> (string * string) list option
  val reconstruct : (string * string) -> goal -> tactic
  val reconstruct_stac : (string * string) -> goal -> string option
  val reconstruct_new : (string * string) -> goal -> tactic
  val reconstruct_flag : bool ref
  val lemmas_ref : string list option ref
  val status_ref : bool ref
  val rec_ref    : bool ref
  
end
