;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.

;; RUN: foreach %s %t wasm-opt -all --instrument-branch-hints --roundtrip -S -o - | filecheck %s

;; Two imports exist here, and instrument-branch-hints will add another. The
;; name "fimport$2" happens to be the name that would be chosen for that new
;; import, leading to a situation that the existing import has a forced name
;; from the names section (it is named here in the wat) while we pick an
;; internal name (not from the name section) that overlaps with it, causing an
;; error if we do not make sure to avoid duplication between import and non-
;; import names.

(module
 ;; CHECK:      (type $0 (func (param i64)))

 ;; CHECK:      (type $1 (func (param f32)))

 ;; CHECK:      (type $2 (func (param i32 i32 i32)))

 ;; CHECK:      (import "fuzzing-support" "log-i64" (func $fimport$2 (type $0) (param i64)))
 (import "fuzzing-support" "log-i64" (func $fimport$2 (param i64)))
 ;; CHECK:      (import "fuzzing-support" "log-f32" (func $fimport$3 (type $1) (param f32)))
 (import "fuzzing-support" "log-f32" (func $fimport$3 (param f32)))
)
;; CHECK:      (import "fuzzing-support" "log-branch" (func $fimport$2_2 (type $2) (param i32 i32 i32)))
