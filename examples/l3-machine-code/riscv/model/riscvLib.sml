(* riscvLib - generated by L3 - Sat Feb 09 15:17:33 2019 *)
structure riscvLib :> riscvLib =
struct
open HolKernel boolLib bossLib
open utilsLib riscvTheory
val () = (numLib.prefer_num (); wordsLib.prefer_word ())
fun riscv_compset thms =
   utilsLib.theory_compset (thms, riscvTheory.inventory)
end