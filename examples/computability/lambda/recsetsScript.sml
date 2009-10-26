open HolKernel Parse bossLib boolLib

val _ = new_theory "recsets"

open recfunsTheory reductionEval
open binderLib
open stepsTheory
open churchlistTheory churchDBTheory

fun Store_thm(trip as (n,t,tac)) = store_thm trip before export_rewrites [n]

val recursive_def = Define`
  recursive s = ∃M. ∀e. Phi M e = SOME (if e ∈ s then 1 else 0)
`;

val empty_recursive = Store_thm(
  "empty_recursive",
  ``recursive {}``,
  SRW_TAC [][recursive_def, Phi_def] THEN
  Q.EXISTS_TAC `dBnum (fromTerm (LAM v (church 0)))` THEN
  SIMP_TAC (bsrw_ss()) [normal_orderTheory.bnf_bnf_of]);

val univ_recursive = Store_thm(
  "univ_recursive",
  ``recursive UNIV``,
  SRW_TAC [][recursive_def, Phi_def] THEN
  Q.EXISTS_TAC `dBnum (fromTerm (LAM v (church 1)))` THEN
  SIMP_TAC (bsrw_ss()) [normal_orderTheory.bnf_bnf_of]);

val union_recursive_I = Store_thm(
  "union_recursive_I",
  ``recursive s₁ ∧ recursive s₂ ⇒ recursive (s₁ ∪ s₂)``,
  SRW_TAC [][recursive_def] THEN
  SIMP_TAC (srw_ss()) [Phi_def] THEN
  Q.EXISTS_TAC
    `dBnum (fromTerm
      (LAM z (cor @@ (ceqnat @@ (church 1)
                             @@ (UM @@ (cnpair @@ church M @@ VAR z)))
                  @@ (ceqnat @@ (church 1)
                             @@ (UM @@ (cnpair @@ church M' @@ VAR z)))
                  @@ church 1
                  @@ church 0)))` THEN
  Q.X_GEN_TAC `n` THEN
  REPEAT (FIRST_X_ASSUM (Q.SPEC_THEN `n` STRIP_ASSUME_TAC)) THEN
  IMP_RES_TAC PhiSOME_UM_I THEN
  ASM_SIMP_TAC (bsrw_ss()) [churchnumTheory.cnpair_behaviour,
                            churchnumTheory.ceqnat_behaviour] THEN
  Cases_on `n ∈ s₁` THEN Cases_on `n ∈ s₂` THEN
  ASM_SIMP_TAC (bsrw_ss()) [churchboolTheory.cor_behaviour,
                            churchboolTheory.cB_behaviour,
                            normal_orderTheory.bnf_bnf_of]);

val inter_recursive_I = Store_thm(
  "inter_recursive_I",
  ``recursive s₁ ∧ recursive s₂ ⇒ recursive (s₁ ∩ s₂)``,
  SRW_TAC [][recursive_def] THEN
  SIMP_TAC (srw_ss()) [Phi_def] THEN
  Q.EXISTS_TAC `
    dBnum (fromTerm
      (LAM z (cmult @@ (UM @@ (cnpair @@ church M @@ VAR z))
                    @@ (UM @@ (cnpair @@ church M' @@ VAR z)))))` THEN
  Q.X_GEN_TAC `n` THEN
  REPEAT (FIRST_X_ASSUM (Q.SPEC_THEN `n` STRIP_ASSUME_TAC)) THEN
  IMP_RES_TAC PhiSOME_UM_I THEN
  ASM_SIMP_TAC (bsrw_ss()) [churchnumTheory.cnpair_behaviour,
                            churchnumTheory.cmult_behaviour,
                            normal_orderTheory.bnf_bnf_of] THEN
  Cases_on `n ∈ s₁` THEN SRW_TAC [][]);

val compl_recursive_I = store_thm(
  "compl_recursive_I",
  ``recursive s ⇒ recursive (COMPL s)``,
  SRW_TAC [][recursive_def] THEN
  SIMP_TAC (srw_ss()) [Phi_def] THEN
  Q.EXISTS_TAC `
    dBnum (fromTerm
      (LAM z (cminus @@ (church 1)
                     @@ (UM @@ (cnpair @@ church M @@ VAR z)))))` THEN
  Q.X_GEN_TAC `n` THEN
  POP_ASSUM (Q.SPEC_THEN `n` STRIP_ASSUME_TAC) THEN
  IMP_RES_TAC PhiSOME_UM_I THEN
  ASM_SIMP_TAC (bsrw_ss()) [churchnumTheory.cnpair_behaviour,
                            churchnumTheory.cminus_behaviour,
                            normal_orderTheory.bnf_bnf_of] THEN
  Cases_on `n ∈ s` THEN SRW_TAC [][]);

val compl_recursive = Store_thm(
  "compl_recursive",
  ``recursive (COMPL s) ⇔ recursive s``,
  METIS_TAC [pred_setTheory.COMPL_COMPL, compl_recursive_I]);

val finite_recursive = Store_thm(
  "finite_recursive",
  ``∀s. FINITE s ==> recursive s``,
  HO_MATCH_MP_TAC pred_setTheory.FINITE_INDUCT THEN
  SRW_TAC [][] THEN
  FULL_SIMP_TAC (srw_ss()) [recursive_def] THEN
  SIMP_TAC (srw_ss()) [Phi_def] THEN
  Q.EXISTS_TAC `
    dBnum (fromTerm
      (LAM z (cor @@ (ceqnat @@ VAR z @@ church e)
                  @@ (ceqnat @@ church 1
                             @@ (UM @@ (cnpair @@ church M @@ VAR z)))
                  @@ church 1
                  @@ church 0)))` THEN
  Q.X_GEN_TAC `n` THEN FIRST_X_ASSUM (Q.SPEC_THEN `n` STRIP_ASSUME_TAC) THEN
  IMP_RES_TAC PhiSOME_UM_I THEN
  ASM_SIMP_TAC (bsrw_ss()) [churchnumTheory.cnpair_behaviour,
                            churchnumTheory.ceqnat_behaviour,
                            churchboolTheory.cor_behaviour] THEN
  Cases_on `n = e` THEN
  ASM_SIMP_TAC (bsrw_ss()) [churchboolTheory.cB_behaviour,
                            normal_orderTheory.bnf_bnf_of] THEN
  Cases_on `n ∈ s` THEN
  ASM_SIMP_TAC (bsrw_ss()) [churchboolTheory.cB_behaviour,
                            normal_orderTheory.bnf_bnf_of]);

(* an r.e. set is one that can be enumerated.  In this world, I take enumerable
   to mean there exists a function that returns values at successive indices.
*)
val re_def = Define`
  re s = ∃Mi. ∀e. e ∈ s ⇔ ∃j. Phi Mi j = SOME e
`;

(* if a set s is r.e., then there is a machine that terminates on only those
   elements of the set (and fails to terminate on non-members)

   Say the machine we have that enumerates s is Mi.  Then we want one that
   will correctly terminate on element e of s.
   For increasing n, construct the list of n elements corresponding to
   evaluating [Mi 0, Mi 1, Mi 2, ... Mi n] for n steps.  For all the bnfs in
   this list, see if one of them is equal to e.  If so, terminate.
*)
val enum2semibody_def = Define`
  enum2semibody Mi e loop n j =
    LAM loop (LAM n
      (cmem @@ e
            @@ (cmap @@ cforce_num
                     @@ (cfilter
                           @@ cbnf
                           @@ (ctabulate
                                 @@ (csuc @@ VAR n)
                                 @@ (LAM j
                                       (csteps
                                          @@ VAR n
                                          @@ (cdAPP
                                                @@ (cnumdB @@ church Mi)
                                                @@ (cchurch @@ VAR j)))))))
            @@ church 0
            @@ (VAR loop @@ (csuc @@ VAR n))))
`;

val enum2semi_def = Define`
  enum2semi Mi e =
    let loop = NEW (FV e) in
    let n = NEW ({loop} ∪ FV e) in
    let j = NEW {n}
    in
       enum2semibody Mi e loop n j
`;

val FV_enum2semi = prove(
  ``FV (enum2semi n t) = FV t``,
  SRW_TAC [][enum2semi_def, LET_THM, pred_setTheory.EXTENSION,
             enum2semibody_def] THEN
  binderLib.NEW_ELIM_TAC THEN REPEAT GEN_TAC THEN
  binderLib.NEW_ELIM_TAC THEN SRW_TAC [][] THEN
  METIS_TAC []);

val enum2semi_fresh = prove(
  ``loop ∉ FV e ∧ n ≠ loop ∧ n ∉ FV e ∧ j ≠ n ⇒
     (enum2semi Mi e = enum2semibody Mi e loop n j)``,
  SRW_TAC [][enum2semi_def, LET_THM] THEN
  binderLib.NEW_ELIM_TAC THEN REPEAT STRIP_TAC THEN
  binderLib.NEW_ELIM_TAC THEN REPEAT STRIP_TAC THEN
  binderLib.NEW_ELIM_TAC THEN REPEAT STRIP_TAC THEN
  SRW_TAC [][enum2semibody_def, termTheory.LAM_eq_thm,
             termTheory.tpm_fresh] THEN
  Cases_on `loop = v` THEN SRW_TAC [][] THEN1
    (SRW_TAC [][basic_swapTheory.swapstr_def] THEN METIS_TAC []) THEN
  Cases_on `v = n` THEN SRW_TAC [][] THEN
  Cases_on `loop = n` THEN SRW_TAC [][] THENL [
    Cases_on `loop = j` THEN SRW_TAC [][] THEN
    SRW_TAC [][basic_swapTheory.swapstr_def, termTheory.tpm_fresh] THEN
    METIS_TAC [],

    Cases_on `loop = j` THEN SRW_TAC [][] THEN1
      (SRW_TAC [][basic_swapTheory.swapstr_def, termTheory.tpm_fresh] THEN
       METIS_TAC []) THEN
    Cases_on `v = j` THEN SRW_TAC [][] THEN
    SRW_TAC [][basic_swapTheory.swapstr_def, termTheory.tpm_fresh] THEN
    METIS_TAC []
  ]);

(* val enum2semi_eqn = brackabs.brackabs_equiv [] (SPEC_ALL enum2semi_def) *)

val enum2semi_SUB = store_thm(
  "enum2semi_SUB",
  ``[N/v] (enum2semi n t) = enum2semi n ([N/v]t)``,
  Q_TAC (NEW_TAC "loop") `FV N ∪ {v} ∪ FV t` THEN
  Q_TAC (NEW_TAC "m") `FV N ∪ {v; loop} ∪ FV t` THEN
  Q_TAC (NEW_TAC "j") `FV N ∪ {v;m}` THEN
  `enum2semi n t = enum2semibody n t loop m j`
     by METIS_TAC [enum2semi_fresh] THEN
  `enum2semi n ([N/v]t) = enum2semibody n ([N/v]t) loop m j`
     by (MATCH_MP_TAC enum2semi_fresh THEN
         SRW_TAC [][chap2Theory.NOT_IN_FV_SUB]) THEN
  SRW_TAC [][enum2semibody_def, termTheory.lemma14b]);

val freshlemma = prove(
  ``NEW (FV e) ∉ FV e ∧ NEW (FV e ∪ {NEW (FV e)}) ≠ NEW (FV e) ∧
    NEW (FV e ∪ {NEW (FV e)}) ∉ FV e ∧
    NEW {NEW (FV e ∪ {NEW (FV e)})} ≠ NEW (FV e ∪ {NEW (FV e)})``,
  binderLib.NEW_ELIM_TAC THEN NTAC 2 STRIP_TAC THEN
  binderLib.NEW_ELIM_TAC THEN NTAC 2 STRIP_TAC THEN
  binderLib.NEW_ELIM_TAC);

val enum2semi_eqn =
    enum2semi_fresh
      |> REWRITE_RULE [enum2semibody_def]
      |> UNDISCH
      |> brackabs.brackabs_equiv
          (CONJUNCTS
               (ASSUME ``loop ∉ FV e ∧ n ≠ loop ∧ n ∉ FV e ∧ j ≠ n``))
      |> DISCH_ALL
      |> Q.INST [`j` |-> `NEW {n}`]
      |> Q.INST [`loop` |-> `NEW (FV e)`, `n` |-> `NEW (FV e ∪ {NEW (FV e)})`]
      |> C MP freshlemma

val MEM_GENLIST = prove(
  ``MEM e (GENLIST f n) = ∃i. i < n ∧ (e = f i)``,
  Q.ID_SPEC_TAC `f` THEN
  Induct_on `n` THEN1 SRW_TAC [][rich_listTheory.GENLIST] THEN
  SRW_TAC [][GENLIST_ALT, EQ_IMP_THM] THENL [
    Cases_on `e = f 0` THENL [
      Q.EXISTS_TAC `0` THEN SRW_TAC [][],
      FULL_SIMP_TAC (srw_ss()) [] THEN Q.EXISTS_TAC `SUC i` THEN
      SRW_TAC [][]
    ],
    `∃m. i = SUC m` by METIS_TAC [TypeBase.nchotomy_of ``:num``] THEN
    Q.EXISTS_TAC `m` THEN SRW_TAC [ARITH_ss][]
  ]);


val cmem_cvlist = prove(
  ``(∀e. MEM e l ⇒ ∃n. e == church n) ⇒
    cmem @@ church m @@ cvlist l ==
    cB (EXISTS (λt. ceqnat @@ church m @@ t == cB T) l)``,
  Induct_on `l` THEN
  ASM_SIMP_TAC (bsrw_ss()) [cmem_behaviour] THEN REPEAT STRIP_TAC THEN
  FIRST_ASSUM (Q.SPEC_THEN `h`
                           (STRIP_ASSUME_TAC o SIMP_RULE (srw_ss()) [])) THEN
  ASM_SIMP_TAC (bsrw_ss()) [cmem_behaviour, Cong cvcons_cong,
                            churchnumTheory.ceqnat_behaviour] THEN
  Cases_on `m = n` THEN SRW_TAC [][]);

val EXISTS_FILTER = prove(
  ``EXISTS P (FILTER Q l) = EXISTS (λe. Q e ∧ P e) l``,
  Induct_on `l` THEN SRW_TAC [][]);

val EXISTS_GENLIST = prove(
  ``∀n f. EXISTS P (GENLIST f n) = ∃i. i < n ∧ P (f i)``,
  Induct THEN1 SRW_TAC [][rich_listTheory.GENLIST] THEN
  SRW_TAC [][GENLIST_ALT, EQ_IMP_THM] THENL [
    Q.EXISTS_TAC `0` THEN SRW_TAC [][],
    Q.EXISTS_TAC `SUC i` THEN SRW_TAC [][],
    Cases_on `i` THEN SRW_TAC [][] THEN
    DISJ2_TAC THEN Q.EXISTS_TAC `n'` THEN SRW_TAC [ARITH_ss][]
  ]);

(*
val re_semirecursive1 = prove(
  ``re s ⇒ ∃N. ∀e. e ∈ s ⇔ ∃m. Phi N e = SOME m``,
  SRW_TAC [][re_def] THEN
  Q.EXISTS_TAC
    `dBnum (fromTerm
              (LAM "e" (chap2$Y @@ enum2semi Mi (VAR "e") @@ church 0)))` THEN
  SRW_TAC [][Phi_def, EQ_IMP_THM] THENL [
    SIMP_TAC (bsrw_ss()) [churchDBTheory.cnumdB_behaviour,
                          Once chap2Theory.lameq_Y, enum2semi_SUB] THEN
    `toTerm (numdB Mi) @@ church j -n->* z ∧ bnf z`
       by METIS_TAC [normal_orderTheory.bnf_of_SOME] THEN
    `∃n. steps n (toTerm (numdB Mi) @@ church j) = z`
       by METIS_TAC [stepsTheory.bnf_steps] THEN
    Q.MATCH_ABBREV_TAC
      `∃r. bnf_of (E @@ (chap2$Y @@ E) @@ church 0) = SOME r` THEN
    Q_TAC SUFF_TAC `∀st. st ≤ MAX (j + 1) n ⇒
                         E @@ (chap2$Y @@ E) @@ church st == church 0`
          THEN1 (DISCH_THEN (Q.SPEC_THEN `0` MP_TAC) THEN
                 SIMP_TAC (bsrw_ss()) [normal_orderTheory.bnf_bnf_of]) THEN
    Q_TAC SUFF_TAC
          `∀m st. (m = MAX (j + 1) n - st) ∧
                  st ≤ MAX (j + 1) n ⇒
                  E @@ (chap2$Y @@ E) @@ church st == church 0`
          THEN1 METIS_TAC [] THEN
    Induct THEN REPEAT STRIP_TAC THENL [
      `st = MAX (j + 1) n` by DECIDE_TAC THEN
      POP_ASSUM SUBST_ALL_TAC THEN
      SIMP_TAC (bsrw_ss()) [Abbr`E`, enum2semi_eqn] THEN
      FULL_SIMP_TAC (srw_ss()) [] THEN
      ASM_SIMP_TAC (bsrw_ss() ++ boolSimps.DNF_ss)
                   [ctabulate_cvlist, Cong cvlist_genlist_cong,
                    churchnumTheory.csuc_behaviour,
                    cchurch_behaviour, cnumdB_behaviour,
                    cdAPP_behaviour, csteps_behaviour,
                    cfilter_cvlist, MEM_GENLIST, cbnf_behaviour,
                    cmap_cvlist, cmem_cvlist, listTheory.MEM_MAP,
                    listTheory.MEM_FILTER, cforce_num_behaviour] THEN
      ASM_SIMP_TAC (srw_ss()) [listTheory.EXISTS_MAP,
                               EXISTS_FILTER, EXISTS_GENLIST] THEN
      Q.MATCH_ABBREV_TAC `cB P @@ church 0 @@ X == church 0` THEN
      Q_TAC SUFF_TAC `P` THEN1
        SIMP_TAC (bsrw_ss()) [churchboolTheory.cB_behaviour] THEN
      markerLib.UNABBREV_ALL_TAC THEN
      Q.EXISTS_TAC `j` THEN
      SIMP_TAC (bsrw_ss()) [cforce_num_behaviour,
                            churchnumTheory.ceqnat_behaviour,
                            cbnf_behaviour] THEN
      `steps (MAX (j + 1) n) (toTerm (numdB Mi) @@ church j) = z`
         by (SRW_TAC [][] THEN Cases_on `MAX (j + 1) n = n`
               THEN1 SRW_TAC [][] THEN
             MATCH_MP_TAC bnf_steps_upwards_closed THEN
             FULL_SIMP_TAC (srw_ss() ++ ARITH_ss)
                           [arithmeticTheory.MAX_DEF]) THEN
      SRW_TAC [ARITH_ss][arithmeticTheory.MAX_DEF],

      `st < MAX (j + 1) n` by DECIDE_TAC THEN
      SIMP_TAC (bsrw_ss()) [Abbr`E`, Once enum2semi_eqn] THEN
      ASM_SIMP_TAC (bsrw_ss() ++ boolSimps.DNF_ss)
                   [ctabulate_cvlist, Cong cvlist_genlist_cong,
                    churchnumTheory.csuc_behaviour,
                    cchurch_behaviour, cnumdB_behaviour,
                    cdAPP_behaviour, csteps_behaviour,
                    cfilter_cvlist, MEM_GENLIST, cbnf_behaviour,
                    cmap_cvlist, cmem_cvlist, listTheory.MEM_MAP,
                    listTheory.MEM_FILTER, cforce_num_behaviour] THEN
      ASM_SIMP_TAC (srw_ss()) [listTheory.EXISTS_MAP,
                               EXISTS_FILTER, EXISTS_GENLIST] THEN
      Q.ABBREV_TAC `MX = MAX (j + 1) n`  THEN
      FIRST_X_ASSUM (Q.SPEC_THEN `SUC st` MP_TAC) THEN
      ASM_SIMP_TAC (srw_ss() ++ ARITH_ss) [] THEN
      STRIP_TAC THEN
      ASM_SIMP_TAC (bsrw_ss()) [Once chap2Theory.lameq_Y] THEN
      Q.MATCH_ABBREV_TAC `cB P @@ X @@ X == X` THEN
      Cases_on `P` THEN
      ASM_SIMP_TAC (bsrw_ss()) [churchboolTheory.cB_behaviour]
    ],

    (* other direction *)
    FULL_SIMP_TAC (bsrw_ss()) [enum2semi_SUB] THEN
    FULL_SIMP_TAC (bsrw_ss()) [bnf_steps] THEN
    NTAC 2 (POP_ASSUM MP_TAC) THEN POP_ASSUM (K ALL_TAC) THEN
    Q.ID_SPEC_TAC `n` THEN completeInduct_on `n` THEN


*)
(*
val recursive_re = store_thm(
  "recursive_re",
  ``recursive s ⇒ re s``,
  SRW_TAC [][recursive_def, re_def] THEN
  `dBnum (fromTerm

*)




val _ = export_theory ()
