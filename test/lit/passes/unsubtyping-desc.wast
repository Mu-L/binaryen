;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.
;; RUN: foreach %s %t wasm-opt -all --closed-world --preserve-type-order \
;; RUN:     --unsubtyping --remove-unused-types -all -S -o - | filecheck %s

(module
  (rec
    ;; CHECK:      (rec
    ;; CHECK-NEXT:  (type $A (sub (descriptor $A.desc (struct))))
    (type $A (sub (descriptor $A.desc (struct))))
    ;; CHECK:       (type $A.desc (sub (describes $A (struct))))
    (type $A.desc (sub (describes $A (struct))))
    ;; CHECK:       (type $B (sub (descriptor $B.desc (struct))))
    (type $B (sub $A (descriptor $B.desc (struct))))
    ;; CHECK:       (type $B.desc (sub (describes $B (struct))))
    (type $B.desc (sub $A.desc (describes $B (struct))))
  )

  ;; There is nothing requiring the subtype relationship, so we should optimize.
  ;; CHECK:      (global $A (ref null $A) (ref.null none))
  (global $A (ref null $A) (ref.null none))
  ;; CHECK:      (global $B (ref null $B) (ref.null none))
  (global $B (ref null $B) (ref.null none))
)

(module
  (rec
    ;; CHECK:      (rec
    ;; CHECK-NEXT:  (type $A (sub (descriptor $A.desc (struct))))
    (type $A (sub (descriptor $A.desc (struct))))
    ;; CHECK:       (type $A.desc (sub (describes $A (struct))))
    (type $A.desc (sub (describes $A (struct))))
    ;; CHECK:       (type $B (sub $A (descriptor $B.desc (struct))))
    (type $B (sub $A (descriptor $B.desc (struct))))
    ;; CHECK:       (type $B.desc (sub $A.desc (describes $B (struct))))
    (type $B.desc (sub $A.desc (describes $B (struct))))
  )

  ;; Now we require B <: A, which implies B.desc <: A.desc.
  ;; CHECK:      (global $B (ref null $B) (ref.null none))
  (global $B (ref null $B) (ref.null none))
  ;; CHECK:      (global $A (ref null $A) (global.get $B))
  (global $A (ref null $A) (global.get $B))
)

(module
  (rec
    ;; CHECK:      (rec
    ;; CHECK-NEXT:  (type $A (sub (descriptor $A.desc (struct))))
    (type $A (sub (descriptor $A.desc (struct))))
    ;; CHECK:       (type $A.desc (sub (describes $A (struct))))
    (type $A.desc (sub (describes $A (struct))))
    ;; CHECK:       (type $B (sub (descriptor $B.desc (struct))))
    (type $B (sub $A (descriptor $B.desc (struct))))
    ;; CHECK:       (type $B.desc (sub $A.desc (describes $B (struct))))
    (type $B.desc (sub $A.desc (describes $B (struct))))
  )

  ;; Now we directly require B.desc <: A.desc. This does *not* imply B <: A, so
  ;; we can optimize $B (but not $B.desc).
  ;; CHECK:      (global $B.desc (ref null $B.desc) (ref.null none))
  (global $B.desc (ref null $B.desc) (ref.null none))
  ;; CHECK:      (global $A.desc (ref null $A.desc) (global.get $B.desc))
  (global $A.desc (ref null $A.desc) (global.get $B.desc))
)

(module
  (rec
    ;; CHECK:      (rec
    ;; CHECK-NEXT:  (type $top (sub (descriptor $top.desc (struct))))
    (type $top (sub (descriptor $top.desc (struct))))
    ;; CHECK:       (type $mid (sub $top (descriptor $mid.desc (struct))))
    (type $mid (sub $top (descriptor $mid.desc (struct))))
    ;; CHECK:       (type $bot (sub $mid (descriptor $bot.desc (struct))))
    (type $bot (sub $mid (descriptor $bot.desc (struct))))
    ;; CHECK:       (type $top.desc (sub (describes $top (struct))))
    (type $top.desc (sub (describes $top (struct))))
    ;; CHECK:       (type $mid.desc (sub $top.desc (describes $mid (struct))))
    (type $mid.desc (sub $top.desc (describes $mid (struct))))
    ;; CHECK:       (type $bot.desc (sub $mid.desc (describes $bot (struct))))
    (type $bot.desc (sub $mid.desc (describes $bot (struct))))
  )

  ;; top -> top.desc
  ;; ^
  ;; |(2) mid -> mid.desc
  ;; |            ^ (1)
  ;; bot -> bot.desc
  ;;
  ;; bot <: top implies bot.desc <: top.desc, but we already have
  ;; bot.desc <: mid.desc, so that gives us bot.desc <: mid.desc <: top.desc.
  ;; This is only valid if we also have bot <: mid <: top.

  ;; CHECK:      (global $bot-mid-desc (ref null $mid.desc) (struct.new_default $bot.desc))
  (global $bot-mid-desc (ref null $mid.desc) (struct.new $bot.desc))
  ;; CHECK:      (global $bot-top (ref null $top) (struct.new_default $bot
  ;; CHECK-NEXT:  (ref.null none)
  ;; CHECK-NEXT: ))
  (global $bot-top (ref null $top) (struct.new $bot (ref.null none)))
)

(module
  (rec
    ;; CHECK:      (rec
    ;; CHECK-NEXT:  (type $top (sub (descriptor $top.desc (struct))))
    (type $top (sub (descriptor $top.desc (struct))))
    ;; CHECK:       (type $mid (sub $top (descriptor $mid.desc (struct))))
    (type $mid (sub $top (descriptor $mid.desc (struct))))
    ;; CHECK:       (type $bot (sub $mid (descriptor $bot.desc (struct))))
    (type $bot (sub $mid (descriptor $bot.desc (struct))))
    ;; CHECK:       (type $top.desc (sub (describes $top (struct))))
    (type $top.desc (sub (describes $top (struct))))
    ;; CHECK:       (type $mid.desc (sub $top.desc (describes $mid (struct))))
    (type $mid.desc (sub $top.desc (describes $mid (struct))))
    ;; CHECK:       (type $bot.desc (sub $mid.desc (describes $bot (struct))))
    (type $bot.desc (sub $mid.desc (describes $bot (struct))))
  )

  ;; Same as above, but the order of the initial subtypings is reversed.
  ;;
  ;; top -> top.desc
  ;; ^
  ;; |(1) mid -> mid.desc
  ;; |            ^ (2)
  ;; bot -> bot.desc
  ;;
  ;; bot <: top implies bot.desc <: top.desc. When we add bot.desc <: mid.desc,
  ;; that gives us bot.desc <: mid.desc <: top.desc. This is only valid if we
  ;; also have bot <: mid <: top.

  ;; CHECK:      (global $bot-top (ref null $top) (struct.new_default $bot
  ;; CHECK-NEXT:  (ref.null none)
  ;; CHECK-NEXT: ))
  (global $bot-top (ref null $top) (struct.new $bot (ref.null none)))
  ;; CHECK:      (global $bot-mid-desc (ref null $mid.desc) (struct.new_default $bot.desc))
  (global $bot-mid-desc (ref null $mid.desc) (struct.new $bot.desc))
)
