open HolKernel bossLib boolLib MiniMLTheory evaluateEquationsTheory compileTerminationTheory count_expTheory listTheory lcsymtacs

val _ = new_theory "compileCorrectness"

val FINITE_free_vars = store_thm(
"FINITE_free_vars",
``∀t. FINITE (free_vars t)``,
ho_match_mp_tac free_vars_ind >>
rw[free_vars_def] >>
qmatch_rename_tac `FINITE (FOLDL XXX YYY ls)` ["XXX","YYY"] >>
qmatch_abbrev_tac `FINITE (FOLDL ff s0 ls)` >>
qsuff_tac `∀s0. FINITE s0 ⇒ FINITE (FOLDL ff s0 ls)` >- rw[Abbr`s0`] >>
Induct_on `ls` >> rw[Abbr`s0`] >>
first_assum (ho_match_mp_tac o MP_CANON) >>
rw[Abbr`ff`] >>
TRY (Cases_on `h` >> rw[]) >>
metis_tac[])

(* TODO: move where? *)

val type_es_every_map = store_thm(
"type_es_every_map",
``∀tenvC tenv es ts. type_es tenvC tenv es ts = (LENGTH es = LENGTH ts) ∧ EVERY (UNCURRY (type_e tenvC tenv)) (ZIP (es,ts))``,
ntac 2 gen_tac >>
Induct >- (
  rw[Once type_v_cases] >>
  Cases_on `ts` >> rw[] ) >>
rw[Once type_v_cases] >>
Cases_on `ts` >> rw[] >>
metis_tac[])

val type_vs_every_map = store_thm(
"type_vs_every_map",
``∀tenvC vs ts. type_vs tenvC vs ts = (LENGTH vs = LENGTH ts) ∧ EVERY (UNCURRY (type_v tenvC)) (ZIP (vs,ts))``,
gen_tac >>
Induct >- (
  rw[Once type_v_cases] >>
  Cases_on `ts` >> rw[] ) >>
rw[Once type_v_cases] >>
Cases_on `ts` >> rw[] >>
metis_tac[])

(* TODO: Where should these go? *)

val well_typed_def = Define`
  well_typed env exp = ∃tenvC tenv t.
    type_env tenvC env tenv ∧
    type_e tenvC tenv exp t`;

val (subexp_rules,subexp_ind,subexp_cases) = Hol_reln`
  (MEM e es ⇒ subexp e (Con cn es)) ∧
  (subexp e1 (App op e1 e2)) ∧
  (subexp e2 (App op e1 e2))`

val well_typed_subexp_lem = store_thm(
"well_typed_subexp_lem",
``∀env e1 e2. subexp e1 e2 ⇒ well_typed env e2 ⇒ well_typed env e1``,
gen_tac >>
ho_match_mp_tac subexp_ind >>
fs[well_typed_def] >>
strip_tac >- (
  rw[Once (List.nth (CONJUNCTS type_v_cases, 1))] >>
  fs[type_es_every_map] >>
  qmatch_assum_rename_tac `EVERY X (ZIP (es,MAP f ts))` ["X"] >>
  fs[MEM_EL] >> rw[] >>
  `MEM (EL n es, f (EL n ts)) (ZIP (es, MAP f ts))` by (
    rw[MEM_ZIP] >> qexists_tac `n` >> rw[EL_MAP] ) >>
  fs[EVERY_MEM] >> res_tac >>
  fs[] >> metis_tac []) >>
strip_tac >- (
  rw[Once (List.nth (CONJUNCTS type_v_cases, 1))] >>
  metis_tac [] ) >>
strip_tac >- (
  rw[Once (List.nth (CONJUNCTS type_v_cases, 1))] >>
  metis_tac [] ))

val well_typed_Con_subexp = store_thm(
"well_typed_Con_subexp",
``∀env cn es. well_typed env (Con cn es) ⇒ EVERY (well_typed env) es``,
rw[EVERY_MEM] >>
match_mp_tac (MP_CANON well_typed_subexp_lem) >>
qexists_tac `Con cn es` >>
rw[subexp_rules])

val well_typed_App_subexp = store_thm(
"well_typed_App_subexp",
``∀env op e1 e2. well_typed env (App op e1 e2) ⇒ well_typed env e1 ∧ well_typed env e2``,
rw[] >> match_mp_tac (MP_CANON well_typed_subexp_lem) >>
metis_tac [subexp_rules])

(* TODO: move? *)

val lookup_ALOOKUP = store_thm(
"lookup_ALOOKUP",
``lookup = combin$C ALOOKUP``,
fs[FUN_EQ_THM] >> gen_tac >> Induct >- rw[] >> Cases >> rw[])
val _ = export_rewrites["lookup_ALOOKUP"];

(* nicer induction theorem for evaluate *)
(* TODO: move? *)

val (evaluate_list_with_rules,evaluate_list_with_ind,evaluate_list_with_cases) = Hol_reln [ANTIQUOTE(
evaluate_rules |> SIMP_RULE (srw_ss()) [] |> concl |>
strip_conj |>
Lib.filter (fn tm => tm |> strip_forall |> snd |> strip_imp |> snd |> strip_comb |> fst |> same_const ``evaluate_list``) |>
let val t1 = ``evaluate cenv env``
    val t2 = ``evaluate_list cenv env``
    val tP = type_of t1
    val P = mk_var ("P",tP)
    val ew = mk_comb(mk_var("evaluate_list_with",tP --> type_of t2),P)
in List.map (fn tm => tm |> strip_forall |> snd |>
                   subst [t1|->P, t2|->ew])
end |> list_mk_conj)]

val evaluate_list_with_evaluate = store_thm(
"evaluate_list_with_evaluate",
``∀cenv env. evaluate_list cenv env = evaluate_list_with (evaluate cenv env)``,
ntac 2 gen_tac >>
simp_tac std_ss [Once FUN_EQ_THM] >>
Induct >>
rw[FUN_EQ_THM] >-
  rw[Once evaluate_cases,Once evaluate_list_with_cases] >>
rw[Once evaluate_cases] >>
rw[Once evaluate_list_with_cases,SimpRHS] >>
PROVE_TAC[])

val (evaluate_match_with_rules,evaluate_match_with_ind,evaluate_match_with_cases) = Hol_reln [ANTIQUOTE(
evaluate_rules |> SIMP_RULE (srw_ss()) [] |> concl |>
strip_conj |>
Lib.filter (fn tm => tm |> strip_forall |> snd |> strip_imp |> snd |> strip_comb |> fst |> same_const ``evaluate_match``) |>
let val t1 = ``evaluate``
    val t2 = ``evaluate_match``
    val tP = type_of t1
    val P = mk_var ("P",tP)
    val ew = mk_comb(mk_var("evaluate_match_with",tP --> type_of t2),P)
in List.map (fn tm => tm |> strip_forall |> snd |>
                   subst [t1|->P, t2|->ew])
end |> list_mk_conj)]

val evaluate_match_with_evaluate = store_thm(
"evaluate_match_with_evaluate",
``evaluate_match = evaluate_match_with evaluate``,
simp_tac std_ss [FUN_EQ_THM] >>
ntac 3 gen_tac >>
Induct >-
  rw[Once evaluate_cases,Once evaluate_match_with_cases] >>
rw[Once evaluate_cases] >>
rw[Once evaluate_match_with_cases,SimpRHS] >>
PROVE_TAC[])

val evaluate_nice_ind = save_thm(
"evaluate_nice_ind",
evaluate_ind
|> Q.SPECL [`P`,`λcenv env. evaluate_list_with (P cenv env)`,`evaluate_match_with P`] |> SIMP_RULE (srw_ss()) []
|> UNDISCH_ALL
|> CONJUNCTS
|> List.hd
|> DISCH_ALL
|> Q.GEN `P`
|> SIMP_RULE (srw_ss()) [])

(* TODO: save in compileTerminationTheory? *)
val Cevaluate_cases = CompileTheory.Cevaluate_cases
val Cevaluate_rules = CompileTheory.Cevaluate_rules
val extend_def = CompileTheory.extend_def
val exp_Cexp_ind = CompileTheory.exp_Cexp_ind
val v_Cv_ind = CompileTheory.v_Cv_ind
val v_Cv_cases = CompileTheory.v_Cv_cases
val sort_Cenv_def = CompileTheory.sort_Cenv_def

(* Cevaluate functional equations *)

val Cevaluate_raise = store_thm(
"Cevaluate_raise",
``∀env err res. Cevaluate env (CRaise err) res = (res = Rerr (Rraise err))``,
rw[Once Cevaluate_cases])

val Cevaluate_val = store_thm(
"Cevaluate_val",
``∀env v res. Cevaluate env (CVal v) res = (res = Rval v)``,
rw[Once Cevaluate_cases])

val Cevaluate_var = store_thm(
"Cevaluate_var",
``∀env vn res. Cevaluate env (CVar vn) res = (res = Rval (env ' vn))``,
rw[Once Cevaluate_cases])

val _ = export_rewrites["Cevaluate_raise","Cevaluate_val","Cevaluate_var"]

val Cevaluate_con = store_thm(
"Cevaluate_con",
``∀env cn es res. Cevaluate env (CCon cn es) res =
(∃vs. Cevaluate_list env es (Rval vs) ∧ (res = Rval (CConv cn vs))) ∨
(∃err. Cevaluate_list env es (Rerr err) ∧ (res = Rerr err))``,
rw[Once Cevaluate_cases] >> PROVE_TAC[])

val (Cevaluate_list_with_rules,Cevaluate_list_with_ind,Cevaluate_list_with_cases) = Hol_reln [ANTIQUOTE(
Cevaluate_rules |> SIMP_RULE (srw_ss()) [] |> concl |>
strip_conj |>
Lib.filter (fn tm => tm |> strip_forall |> snd |> strip_imp |> snd |> strip_comb |> fst |> same_const ``Cevaluate_list``) |>
let val t1 = ``Cevaluate env``
    val t2 = ``Cevaluate_list env``
    val tP = type_of t1
    val P = mk_var ("P",tP)
    val ew = mk_comb(mk_var("Cevaluate_list_with",tP --> type_of t2),P)
in List.map (fn tm => tm |> strip_forall |> snd |>
                   subst [t1|->P, t2|->ew])
end |> list_mk_conj)]

val Cevaluate_list_with_Cevaluate = store_thm(
"Cevaluate_list_with_Cevaluate",
``∀env. Cevaluate_list env = Cevaluate_list_with (Cevaluate env)``,
gen_tac >>
simp_tac std_ss [Once FUN_EQ_THM] >>
Induct >>
rw[FUN_EQ_THM] >-
  rw[Once Cevaluate_cases,Once Cevaluate_list_with_cases] >>
rw[Once Cevaluate_cases] >>
rw[Once Cevaluate_list_with_cases,SimpRHS] >>
PROVE_TAC[])

val evaluate_list_with_nil = store_thm(
"evaluate_list_with_nil",
``∀f res. evaluate_list_with f [] res = (res = Rval [])``,
rw[Once evaluate_list_with_cases])
val _ = export_rewrites["evaluate_list_with_nil"];

val evaluate_list_with_cons = store_thm(
"evaluate_list_with_cons",
``∀f e es res. evaluate_list_with f (e::es) res =
  (∃v vs. f e (Rval v) ∧ evaluate_list_with f es (Rval vs) ∧ (res = Rval (v::vs))) ∨
  (∃v err. f e (Rval v) ∧ evaluate_list_with f es (Rerr err) ∧ (res = Rerr err)) ∨
  (∃err. f e (Rerr err) ∧ (res = Rerr err))``,
rw[Once evaluate_list_with_cases] >> PROVE_TAC[])

val Cevaluate_list_with_nil = store_thm(
"Cevaluate_list_with_nil",
``∀f res. Cevaluate_list_with f [] res = (res = Rval [])``,
rw[Once Cevaluate_list_with_cases])
val _ = export_rewrites["Cevaluate_list_with_nil"];

val Cevaluate_list_with_cons = store_thm(
"Cevaluate_list_with_cons",
``∀f e es res. Cevaluate_list_with f (e::es) res =
  (∃v vs. f e (Rval v) ∧ Cevaluate_list_with f es (Rval vs) ∧ (res = Rval (v::vs))) ∨
  (∃v err. f e (Rval v) ∧ Cevaluate_list_with f es (Rerr err) ∧ (res = Rerr err)) ∨
  (∃err. f e (Rerr err) ∧ (res = Rerr err))``,
rw[Once Cevaluate_list_with_cases] >> PROVE_TAC[])

val good_cm_cw_def = Define`
  good_cm_cw cm cw =
  (FDOM cw = FRANGE cm) ∧
  (FRANGE cw = FDOM cm) ∧
  (∀x. x ∈ FDOM cm ⇒ (cw ' (cm ' x) = x)) ∧
  (∀y. y ∈ FDOM cw ⇒ (cm ' (cw ' y) = y))`

val good_cmaps_def = Define`
good_cmaps cenv cm cw =
  (∀cn n. do_con_check cenv cn n ⇒ cn IN FDOM cm) ∧
  good_cm_cw cm cw`

(*
val observable_v_def = tDefine "observable_v"`
  (observable_v (Lit l) = T) ∧
  (observable_v (Conv cn vs) = EVERY observable_v vs) ∧
  (observable_v _ = F)`(
WF_REL_TAC `measure v_size` >>
rw[MiniMLTerminationTheory.exp9_size_thm] >>
Q.ISPEC_THEN `v_size` imp_res_tac SUM_MAP_MEM_bound >>
srw_tac[ARITH_ss][])
val _ = export_rewrites["observable_v_def"]

val observable_Cv_def = tDefine "observable_Cv"`
  (observable_Cv (CLit l) = T) ∧
  (observable_Cv (CConv cn vs) = EVERY observable_Cv vs) ∧
  (observable_Cv _ = F)`(
WF_REL_TAC `measure Cv_size` >>
rw[Cexp8_size_thm] >>
Q.ISPEC_THEN `Cv_size` imp_res_tac SUM_MAP_MEM_bound >>
srw_tac[ARITH_ss][])
val _ = export_rewrites["observable_Cv_def"]
*)

val good_G_def = Define`
  good_G G =
    (∀cm v Cv. v_Cv G cm v Cv ⇒ G cm v Cv) ∧
    (∀cm v Cv cw.
      good_cm_cw cm cw ∧
      G cm v Cv ⇒ ((v_to_ov v) = (Cv_to_ov cw) Cv))`

val a_good_G_exists = store_thm(
"a_good_G_exists",
``∃G. good_G G``,
qexists_tac `v_Cv (K (K (K F)))` >>
rw[good_G_def] >- (
  qsuff_tac `∀G cm v Cv. v_Cv G cm v Cv ⇒ (G = v_Cv (K(K(K F)))) ⇒ v_Cv (K(K(K F))) cm v Cv` >- rw[] >>
  ho_match_mp_tac v_Cv_ind >>
  rw[] >>
  rw[v_Cv_cases] >>
  fsrw_tac[boolSimps.ETA_ss][] ) >>
qsuff_tac `∀G cm v Cv. v_Cv G cm v Cv ⇒ (G = K(K(K F))) ∧ good_cm_cw cm cw ⇒ (v_to_ov v = Cv_to_ov cw Cv)` >- (rw[] >> PROVE_TAC[]) >>
ho_match_mp_tac v_Cv_ind >>
rw[] >- fs[good_cm_cw_def] >>
pop_assum mp_tac >>
srw_tac[boolSimps.ETA_ss][] >>
rw[MAP_EQ_EVERY2] >>
PROVE_TAC[EVERY2_LENGTH])

(* Soundness(?) of exp_Cexp *)

(*
val exp_Cexp_thm = store_thm(
"exp_Cexp_thm",``
∀G cm env Cenv exp Cexp. exp_Cexp G cm env Cenv exp Cexp ⇒
  good_G G ⇒
  ∀cenv res.
    evaluate cenv env exp res ⇒
    ∀cw. good_cmaps cenv cm cw ⇒
      ∃Cres.
        Cevaluate Cenv Cexp Cres ∧
        (map_result (Cv_to_ov cw) Cres =
         map_result v_to_ov res)``,
ho_match_mp_tac exp_Cexp_ind >>
rw[] >- (
  fs[good_G_def,good_cmaps_def] >>
  PROVE_TAC[] )
>- (
*)

(*
val exp_Cexp_thm = store_thm(
"exp_Cexp_thm",``
∀cm env Cenv exp Cexp. exp_Cexp cm env Cenv exp Cexp ⇒
  ∀cenv res.
    evaluate cenv env exp res ⇒
    ∀cw. good_cmaps cenv cm cw ⇒
      ∃Cres.
        Cevaluate Cenv Cexp Cres ∧
        (map_result (Cv_to_ov cw) Cres =
         map_result v_to_ov res)``,
ho_match_mp_tac exp_Cexp_ind >>
rw[]
*)

(* Prove compiler phases preserve semantics *)

val good_envs_def = Define`
  good_envs env s s' Cenv = s.cmap SUBMAP s'.cmap`

(*
val exp_to_Cexp_cmap_SUBMAP = store_thm(
"exp_to_Cexp_cmap_SUBMAP",
``∀b cm s exp s' Cexp.
  (exp_to_Cexp b cm (s,exp) = (s',Cexp)) ⇒
  s.m SUBMAP s'.m``,
qsuff_tac `∀b cm s exp s' Cexp.
  (exp_to_Cexp b cm (s,exp) = (s',Cexp)) ⇒
  (FST (s,exp)).m SUBMAP s'.m` >- rw[] >>
ho_match_mp_tac exp_to_Cexp_ind >>
rw[exp_to_Cexp_def,extend_def]
*)

val good_cmap_def = Define`
good_cmap cenv cm =
  (∀cn n. do_con_check cenv cn n ⇒ cn IN FDOM cm)`

val good_exp_to_Cexp_state_def = Define`
  good_exp_to_Cexp_state env s =
  INJ (FAPPLY s.m) (set (MAP FST env)) UNIV`

(* TODO: move? *)
val QSORT_eq_if_PERM = store_thm(
"QSORT_eq_if_PERM",
``!R l1 l2. total R /\ transitive R /\ antisymmetric R /\ PERM l1 l2 ==> (QSORT R l1 = QSORT R l2)``,
PROVE_TAC[sortingTheory.QSORT_PERM,sortingTheory.QSORT_SORTED,sortingTheory.SORTED_PERM_EQ,
          sortingTheory.PERM_TRANS,sortingTheory.PERM_SYM])

local open pred_setTheory relationTheory in
(* TODO: move, or use set_relation stuff? *)
val countable_has_linear_order = store_thm(
"countable_has_linear_order",
``countable (UNIV:'a set) ==>
  ?(r:'a->'a->bool). antisymmetric r /\ transitive r /\ total r``,
SRW_TAC[][countable_def,INJ_DEF] THEN
Q.EXISTS_TAC `inv_image $<= f` THEN
SRW_TAC[][antisymmetric_def,
          transitive_def,
          total_def,
          inv_image_def] THEN
METIS_TAC[arithmeticTheory.LESS_EQUAL_ANTISYM,
          arithmeticTheory.LESS_EQ_TRANS,
          arithmeticTheory.LESS_EQ_CASES])
end

(*
val exp_to_Cexp_thm1 = store_thm(
"exp_to_Cexp_thm1",
``∀tp cm Ps Pexp s exp s' Cexp cenv env res.
  ((Ps,Pexp) = (s,exp)) ∧
  good_exp_to_Cexp_state env s ∧
  (exp_to_Cexp tp cm (s,exp) = (s',Cexp)) ∧
  (tp = F) ∧
  evaluate cenv env exp res ∧
  (res ≠ Rerr Rtype_error) ∧
  good_cmap cenv cm ⇒
  Cevaluate (alist_to_fmap (MAP (λ(x,v). (s.m ' x, v_to_Cv cm (s,v))) env)) Cexp (map_result (λv. v_to_Cv cm (s,v)) res)``,
ho_match_mp_tac exp_to_Cexp_ind >>
strip_tac >-
  fs[exp_to_Cexp_def] >>
strip_tac >-
  fs[exp_to_Cexp_def,v_to_Cv_def] >>
strip_tac >- (
  fs[exp_to_Cexp_def] >>
  rw[Cevaluate_con,evaluate_con] >>
  fs[Cevaluate_list_with_Cevaluate,evaluate_list_with_evaluate] >>
  qpat_assum `do_con_check cenv cn (LENGTH es)` kall_tac >>
  rw[] >>
  TRY (qpat_assum `X Y Z (Rval vs)` mp_tac >> qid_spec_tac `vs`) >>
  Induct_on `es` >- (
    rw[Once evaluate_cases, Once Cevaluate_cases] ) >>
  fs[v_to_Cv_def] >- (
    rw[] >>
    fs[evaluate_list_with_cons] >- (
      rw[Cevaluate_list_with_cons] >>
      disj1_tac >>
      qmatch_assum_abbrev_tac `P ⇒ Q ⇒ R` >>
      `R` by metis_tac[] >>
      qpat_assum `Q` kall_tac >>
      qpat_assum `P ⇒ Q ⇒ R` kall_tac >>
      unabbrev_all_tac >>
      first_x_assum (qspec_then `h` mp_tac) >> rw[] >>
      first_x_assum (qspecl_then [`cenv`,`env`,`Rval v`] mp_tac) >> rw[] >>
      metis_tac[] ) >>
    rw[Cevaluate_list_with_cons] >>
    disj2_tac >>
    first_x_assum (qspec_then `h` mp_tac) >> rw[] >>
    first_x_assum (qspecl_then [`cenv`,`env`,`Rerr err`] mp_tac) >> rw[] ) >>
  rw[] >>
  fs[evaluate_list_with_cons] >>
  rw[Cevaluate_list_with_cons] >- (
    first_x_assum (qspec_then `h` mp_tac) >> rw[] >>
    first_x_assum (qspecl_then [`cenv`,`env`,`Rval v`] mp_tac) >> rw[] ) >>
  first_x_assum (match_mp_tac o MP_CANON) >>
  rw[] >>
  metis_tac[] ) >>
strip_tac >- (
  fs[exp_to_Cexp_def,evaluate_var] >>
  rw[] >> rw[] >>
  fs[good_exp_to_Cexp_state_def] >>
  qho_match_abbrev_tac `x = alist_to_fmap (MAP (λ(x,y). (f1 x, f2 y)) al) ' z` >>
  `f1 = FAPPLY s.m` by rw[Abbr`f1`,FUN_EQ_THM] >>
  rw[alistTheory.alist_to_fmap_MAP] >>
  `vn IN FDOM (f2 o_f alist_to_fmap al)` by (
    rw[MEM_MAP] >>
    imp_res_tac alistTheory.ALOOKUP_MEM >>
    qexists_tac `(vn,v)` >> rw[] ) >>
  rw[finite_mapTheory.MAP_KEYS_def,Abbr`z`] >>
  unabbrev_all_tac >>
  rw[finite_mapTheory.o_f_DEF] >>
  imp_res_tac alistTheory.ALOOKUP_SOME_FAPPLY_alist_to_fmap >>
  rw[] ) >>
strip_tac >- (
  fs[exp_to_Cexp_def] >>
  rw[v_to_Cv_def] >>
  fs[LET_THM] >>
  rw[Once Cevaluate_cases] >>
  rw[sort_Cenv_def] >>
  match_mp_tac QSORT_eq_if_PERM >>
  simp_tac(srw_ss())[CONJ_ASSOC] >>
  conj_tac >- (
    fs[fsetTheory.a_linear_order_def] >>
    SELECT_ELIM_TAC >> rw[] >>
    match_mp_tac countable_has_linear_order >>
    rw[pred_setTheory.countable_def] >>
    qexists_tac `count_prod_aux count_num_aux count_Cv_aux` >>
    rw[pred_setTheory.INJ_DEF] ) >>
  rw[Once sortingTheory.PERM_SYM] >>
  match_mp_tac alistTheory.alist_to_fmap_to_alist_PERM >>
  rw[Abbr`Cenv`,MAP_MAP_o]
  good_exp_to_Cexp_state_def
*)

(*
val exp_to_Cexp_thm1 = store_thm(
"exp_to_Cexp_thm1",
``∀cenv env exp res.
   evaluate cenv env exp res ⇒
   is_source_exp exp ∧ (res ≠ Rerr Rtype_error) ⇒
   ∀cm s. ∃s' Cexp. (exp_to_Cexp F cm (s,exp) = (s',Cexp)) ∧
     ∀cw Cenv. (good_cmaps cenv cm cw) ∧
               (good_envs env s s' Cenv) ⇒
       ∃Cres. Cevaluate Cenv Cexp Cres ∧
              (map_result (Cv_to_ov cw) Cres =
               map_result v_to_ov res)``,
ho_match_mp_tac evaluate_nice_ind >>
strip_tac >- (
  rw[exp_to_Cexp_def,
     Once Cevaluate_cases]) >>
strip_tac >- (
  ntac 2 gen_tac >>
  Cases >> rw[is_source_exp_def] >>
  rw[exp_to_Cexp_def] >>
  rw[Once Cevaluate_cases]) >>
strip_tac >- (
  rw[exp_to_Cexp_def,good_cmaps_def] >>
  res_tac >>
  qpat_assum `do_con_check X Y Z` kall_tac >>
  fs[is_source_exp_def] >>
  Induct_on `es` >- (
    rw[Once evaluate_list_with_cases] >>
    rw[Once Cevaluate_cases] >>
    rw[Once Cevaluate_cases] >>
    qexists_tac `Rval (CConv (cm ' cn) [])` >>
    rw[] ) >>
  rw[Once evaluate_list_with_cases] >>
  fs[is_source_exp_def] >>
  first_x_assum (qspecl_then [`cm`,`s`] mp_tac) >>
  rw[] >> rw[] >>
  rw[Once Cevaluate_cases]
  ... ) >>
strip_tac >- (
  rw[exp_to_Cexp_def] ) >>
strip_tac >- (
  rw[exp_to_Cexp_def] >>
  rw[Once Cevaluate_cases] >>
  qexists_tac `Rerr err` >>
  rw[] >>
  fs[is_source_exp_def] >>
  qpat_assum `do_con_check X Y Z` kall_tac >>
  Induct_on `es` >>
  rw[Once evaluate_list_with_cases] >>
  fs[] >>
  first_x_assum (qspecl_then [`cm`,`s`] mp_tac) >>
  rw[] >>
  rw[Once Cevaluate_cases] >>
  first_x_assum (qspecl_then [`cw`,`Cenv`] mp_tac) >>
  rw[good_envs_def] >>
  Cases_on `Cres` >> fs[] >>
  PROVE_TAC[] ) >>
strip_tac >- (
  rw[]
*)

(*
let rec
v_to_ov cenv (Lit l) = OLit l
and
v_to_ov cenv (Conv cn vs) = OConv cn (List.map (v_to_ov cenv) vs)
and
v_to_ov cenv (Closure env vn e) = OFn
  (fun ov -> map_option (o (v_to_ov cenv) snd)
    (some (fun (a,r) -> v_to_ov cenv a = ov
           && evaluate cenv (bind vn a env) e (Rval r))))
and
v_to_ov cenv (Recclosure env defs n) = OFn
  (fun ov -> option_bind (optopt (find_recfun n defs))
    (fun (vn,e) -> map_option (o (v_to_ov cenv) snd)
      (some (fun (a,r) -> v_to_ov cenv a = ov
             && evaluate cenv (bind vn a (build_rec_env defs env)) e (Rval r)))))

let rec
Cv_to_ov m (CLit l) = OLit l
and
Cv_to_ov m (CConv cn vs) = OConv (Pmap.find cn m) (List.map (Cv_to_ov m) vs)
and
Cv_to_ov m (CClosure env ns e) = OFn
  (fun ov -> some
and
Cv_to_ov m (CRecClos env ns fns n) = OFn
*)


val _ = export_theory ()