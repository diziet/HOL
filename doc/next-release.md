% Release notes for HOL4, ??????

<!-- search and replace ?????? strings corresponding to release name -->
<!-- indent code within bulleted lists to column 11 -->

(Released: ???)

We are pleased to announce the ?????? release of HOL 4.

Contents
--------

-   [New features](#new-features)
-   [Bugs fixed](#bugs-fixed)
-   [New theories](#new-theories)
-   [New tools](#new-tools)
-   [New Examples](#new-examples)
-   [Incompatibilities](#incompatibilities)

New features:
-------------

*   We have implemented new syntaxes for `store_thm` and `save_thm`, which better satisfy the recommendation that `name1` and `name2` below should be the same:

           val name1 = store_thm("name2", tm, tac);

    Now we can remove the “code smell” by writing either

           Theorem name tm-quotation tac

    which will typically look like

           Theorem name
             ‘∀x. P x ⇒ Q x’
             (rpt strip_tac >> ...);

    or by writing with the general pattern

           Theorem name: term-syntax
           Proof tac
           QED

    which might look like

           Theorem name:
             ∀x. P x ⇒ Q x
           Proof
             rpt strip_tac >> ...
           QED

    This latter form must have the `Proof` and `QED` keywords in column 0 in order for the lexing machinery to detect the end of the term and tactic respectively.
    Both forms map to applications of `Q.store_thm` underneath, with an ML binding also made to the appropriate name.
    Both forms allow for theorem attributes to be associated with the name, so that one can write

           Theorem ADD0[simp]: ∀x. x + 0 = x
           Proof tactic
           QED

    Finally, to replace

           val nm = save_thm(“nm”, thm_expr);

    one can now write

           Theorem nm = thm_expr

    These names can also be given attributes in the same way.

-   Holmake now understands targets whose suffixes are the string `Theory` to be instructions to build all of the files associated with a theory.
    Previously, to specifically get `fooTheory` built, it was necessary to write

           Holmake fooTheory.uo

    which is not particularly intuitive.

    Thanks to Magnus Myreen for the feature suggestion.

-   Users can now remove rewrites from simpsets, adjusting the behaviour of the simplifier.
    This can be done with the `-*` operator

           SIMP_TAC (bool_ss -* [“APPEND_ASSOC”]) [] >> ...

    or with the `Excl` form in a theorem list:

           simp[Excl “APPEND_ASSOC”] >> ...

    The stateful simpset (which is behind `srw_ss()` and tactics such as `simp`, `rw` and `fs`) can also be affected more permanently by making calls to `delsimps`:

           val _ = delsimps [“APPEND_ASSOC”]

    Such a call will affect the stateful simpset for the rest of the containing script-file and in all scripts that inherit this theory.
    As is typical, there is a `temp_delsimps` that removes the rewrite for the containing script-file only.

-   Users can now require that a simplification tactic use particular rewrites.
    This is done with the `Req0` and `ReqD` special forms.
    The `Req0` form requires that the goalstate(s) pertaining after the application of the tactic have no sub-terms that match the pattern of the theorems’ left-hand sides.
    The `ReqD` form requires that the number of matching sub-terms should have decreased.
    (This latter is implicitly a requirement that the original goal *did* have some matching sub-terms.)
    We hope that both forms will be useful in creating maintainable tactics.
    See the DESCRIPTION manual for more details.

    Thanks to Magnus Myreen for this feature suggestion ([Github issue](https://github.com/HOL-Theorem-Prover/HOL/issues/680)).

Bugs fixed:
-----------

New theories:
-------------

*   `real_topologyTheory`: a rather complete theory of Elementary
    Topology in Euclidean Space, ported by Muhammad Qasim and Osman
    Hasan from HOL-light (up to 2015). The part of General Topology
    (independent of `realTheory`) is now available at
    `topologyTheory`; the old `topologyTheory` is renamed to
    `metricTheory`.

    There is a minor backwards-incompatibility: old proof scripts using
    the metric-related results in previous `topologyTheory` should now
    open `metricTheory` instead. (Thanks to Chun Tian for this work.)

*   Holmakefiles can now refer to the new variable `DEFAULT_TARGETS` in order to generate a list of the targets in the current directory that Holmake would attempt to build by default.
    This provides an easier way to adjust makefiles than that suggested in the [release notes for Kananaskis-10](http://hol-theorem-prover.org/kananaskis-10.release.html).

New tools:
----------

New examples:
---------

Incompatibilities:
------------------

*   The `term` type is now declared so that it is no longer what SML refers to as an “equality type”.
    This means that SML code that attempts to use `=` or `<>` on types that include terms will now fail to compile.
    Unlike in Haskell, we cannot redefine the behaviour of equality and must accept the SML implementation’s best guess as to what equality is.
    Unfortunately, the SML equality on terms is *not* correct.
    As has long been appreciated, it distinguishes `“λx.x”` and `“λy.y”`, which is bad enough.
    However, in the standard kernel, where explicit substitutions may be present in a term representation, it can also distinguish terms that are not only semantically identical, but also even print the same.

    This incompatibility will mostly affect people writing SML code.
    If broken code is directly calling `=` on terms, the `~~` infix operator can be used instead (this is the tupled version of `aconv`).
    Similarly, `<>` can be replaced by `!~`.
    If broken code includes something like `expr <> NONE` and `expr` has type `term option`, then combinators from `Portable` for building equality tests should be used.
    In particular, the above could be rewritten to

           not (option_eq aconv expr NONE)

    It is possible that a tool will want to compare terms for exact syntactic equality up to choice of bound names.
    The `identical` function can be used for this.
    Note that we strongly believe that uses of this function will only occur in very niche cases.
    For example, it is used just twice in the distribution as of February 2019.

    There are a number of term-specific helper functions defined in `boolLib` to help in writing specific cases.
    For example

           val memt : term list -> term -> bool
           val goal_eq : (term list * term) -> (term list * term) -> bool
           val tassoc : term -> (term * ‘a) list -> ‘a
           val xtm_eq : (‘’a * term) -> (‘’a * term) -> bool

*   The `Holmake` tool now behaves with the `--qof` behaviour enabled by default.
    This means that script files which have a tactic failure occur will cause the building of the corresponding theory to fail, rather than having the build continue with the theorem “cheated”.
    We think this will be less confusing for new users.
    Experts who *do* want to have script files continue past such errors can use the `--noqof` option to enable the old behaviour.

*   When running with Poly/ML, we now require at least version 5.7.0.

*   The `type_abbrev` function now affects only the type parser.
    The pretty-printer will not use the new abbreviation when printing types.
    If the old behaviour of printing the abbreviations as well as parsing them is desired, the new entrypoint `type_abbrev_pp` should be used.

*   The `Globals.priming` reference variable has been removed.
    All priming done by the kernel is now by appending extra prime (apostrophe) characters to the names of variables.
    This also means that this is the only form of variation introduced by the `variant` function.
    However, there is also a new `numvariant` function, which makes the varying function behave as if the old `Globals.priming` was set to `SOME ""` (introduces and increments a numeric suffix).

*   By default, goals are now printed with the trace variable `"Goalstack.print_goal_at_top"` set to false.
    This means goals now print like

            0.  p
            1.  q
           ------------------------------------
                r

    The motivation is that when goal-states are very large, the conclusion (which we assume is the most important part of the state) runs no risk of disappearing off the top of the screen.
    We also believe that having the conclusion and most recent assumption at the bottom of the screen is easier for human eyes to track.
    The trace variable can be changed back to the old behaviour with:

           val _ = set_trace "Goalstack.print_goal_at_top" 1;

    This instruction can be put into script files, or (better) put into your `~/.hol-config.sml` file so that all interactive sessions are automatically adjusted.

*   This is arguably also a bug-fix: it is now impossible to rebind a theorem to a name that was associated with a definition, and have the new theorem silently be added to the `EVAL` compset for future theories’ benefit.
    In other words, it was previously possible to do

           val _ = Define`foo x = x + 1`;
           EVAL “foo 6”;     (* returns ⊢ foo 6 = 7 *)

           val _ = Q.save_thm (“foo_def”, thm);

    and have the effect be that `thm` goes into `EVAL`’s compset in descendent theories.

    Now, when this happens, the change to the persistent compset is dropped.
    If the user wants the new `foo_def` to appear in the `EVAL`-compset in future theories, they must change the call to `save_thm` to use the name `"foo_def[compute]"`.
    Now, as before, the old `foo_def` cannot be seen by future theories at all, and so certainly will not be in the `EVAL`-compset.

* * * * *

<div class="footer">
*[HOL4, ??????](http://hol-theorem-prover.org)*

[Release notes for the previous version](kananaskis-12.release.html)

</div>
