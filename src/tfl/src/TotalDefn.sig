signature TotalDefn =
sig

  type term     = Term.term
  type thm      = Thm.thm;
  type conv     = Abbrev.conv
  type tactic   = Abbrev.tactic
  type defn     = DefnBase.defn
  type 'a quotation = 'a Portable.frag list

   (* Support for automated termination proofs *)

   val guessR       : defn -> term list
   val proveTotal   : tactic -> defn -> defn 


   (* Support for interactive termination proofs *)

   val WF_TAC       : thm list -> tactic
   val TC_SIMP_CONV : thm list -> conv
   val TC_SIMP_TAC  : thm list -> thm list -> tactic
   val WF_REL_TAC   : term quotation -> tactic

   (* Definitions with automated termination proof support *)

   val primDefine   : defn -> thm
   val xDefine      : string -> term quotation -> thm
   val Define       : term quotation -> thm

end
