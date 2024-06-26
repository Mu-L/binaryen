;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.

;; Test that splitting succeeds even if there are no active segments for the function table.

;; RUN: wasm-split %s --split-funcs=foo -g -o1 %t.1.wasm -o2 %t.2.wasm
;; RUN: wasm-dis %t.1.wasm | filecheck %s --check-prefix PRIMARY
;; RUN: wasm-dis %t.2.wasm | filecheck %s --check-prefix SECONDARY

(module
 (table 0 funcref)
 (export "foo" (func $foo))
 ;; SECONDARY:      (type $0 (func))

 ;; SECONDARY:      (import "primary" "table" (table $timport$0 1 funcref))

 ;; SECONDARY:      (elem $0 (i32.const 0) $foo)

 ;; SECONDARY:      (func $foo
 ;; SECONDARY-NEXT:  (nop)
 ;; SECONDARY-NEXT: )
 (func $foo
  (nop)
 )
)
;; PRIMARY:      (type $0 (func))

;; PRIMARY:      (import "placeholder" "0" (func $placeholder_0))

;; PRIMARY:      (table $0 1 funcref)

;; PRIMARY:      (elem $0 (i32.const 0) $placeholder_0)

;; PRIMARY:      (export "foo" (func $0))

;; PRIMARY:      (export "table" (table $0))

;; PRIMARY:      (func $0
;; PRIMARY-NEXT:  (call_indirect (type $0)
;; PRIMARY-NEXT:   (i32.const 0)
;; PRIMARY-NEXT:  )
;; PRIMARY-NEXT: )
