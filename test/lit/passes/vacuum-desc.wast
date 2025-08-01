;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.

;; RUN: wasm-opt -all %s --vacuum -S -o - | filecheck %s
;; RUN: wasm-opt -all %s --vacuum --ignore-implicit-traps -S -o - | filecheck %s --check-prefix=CKIIT
;; RUN: wasm-opt -all %s --vacuum --traps-never-happen -S -o - | filecheck %s --check-prefix=CKTNH

(module
  (rec
    ;; CHECK:      (rec
    ;; CHECK-NEXT:  (type $struct (descriptor $desc (struct)))
    ;; CKIIT:      (rec
    ;; CKIIT-NEXT:  (type $struct (descriptor $desc (struct)))
    ;; CKTNH:      (rec
    ;; CKTNH-NEXT:  (type $struct (descriptor $desc (struct)))
    (type $struct (descriptor $desc (struct)))
    ;; CHECK:       (type $desc (describes $struct (struct)))
    ;; CKIIT:       (type $desc (describes $struct (struct)))
    ;; CKTNH:       (type $desc (describes $struct (struct)))
    (type $desc (describes $struct (struct)))
  )

  ;; CHECK:      (func $new-null-desc (type $5) (param $desc nullref)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_default $struct
  ;; CHECK-NEXT:    (local.get $desc)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; CKIIT:      (func $new-null-desc (type $5) (param $desc nullref)
  ;; CKIIT-NEXT:  (drop
  ;; CKIIT-NEXT:   (struct.new_default $struct
  ;; CKIIT-NEXT:    (local.get $desc)
  ;; CKIIT-NEXT:   )
  ;; CKIIT-NEXT:  )
  ;; CKIIT-NEXT: )
  ;; CKTNH:      (func $new-null-desc (type $5) (param $desc nullref)
  ;; CKTNH-NEXT:  (nop)
  ;; CKTNH-NEXT: )
  (func $new-null-desc (param $desc nullref)
    (drop
      (struct.new $struct
        (local.get $desc)
      )
    )
  )

  ;; CHECK:      (func $new-nullable-desc (type $6) (param $desc (ref null (exact $desc)))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_default $struct
  ;; CHECK-NEXT:    (local.get $desc)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; CKIIT:      (func $new-nullable-desc (type $6) (param $desc (ref null (exact $desc)))
  ;; CKIIT-NEXT:  (nop)
  ;; CKIIT-NEXT: )
  ;; CKTNH:      (func $new-nullable-desc (type $6) (param $desc (ref null (exact $desc)))
  ;; CKTNH-NEXT:  (nop)
  ;; CKTNH-NEXT: )
  (func $new-nullable-desc (param $desc (ref null (exact $desc)))
    (drop
      (struct.new $struct
        (local.get $desc)
      )
    )
  )

  ;; CHECK:      (func $new-non-nullable-desc (type $7) (param $desc (ref (exact $desc)))
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  ;; CKIIT:      (func $new-non-nullable-desc (type $7) (param $desc (ref (exact $desc)))
  ;; CKIIT-NEXT:  (nop)
  ;; CKIIT-NEXT: )
  ;; CKTNH:      (func $new-non-nullable-desc (type $7) (param $desc (ref (exact $desc)))
  ;; CKTNH-NEXT:  (nop)
  ;; CKTNH-NEXT: )
  (func $new-non-nullable-desc (param $desc (ref (exact $desc)))
    (drop
      (struct.new $struct
        (local.get $desc)
      )
    )
  )

  ;; CHECK:      (func $cast-null-desc (type $2) (param $ref anyref) (param $desc nullref)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block ;; (replaces unreachable RefCast we can't emit)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (local.get $ref)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (local.get $desc)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; CKIIT:      (func $cast-null-desc (type $2) (param $ref anyref) (param $desc nullref)
  ;; CKIIT-NEXT:  (drop
  ;; CKIIT-NEXT:   (block ;; (replaces unreachable RefCast we can't emit)
  ;; CKIIT-NEXT:    (drop
  ;; CKIIT-NEXT:     (local.get $ref)
  ;; CKIIT-NEXT:    )
  ;; CKIIT-NEXT:    (drop
  ;; CKIIT-NEXT:     (local.get $desc)
  ;; CKIIT-NEXT:    )
  ;; CKIIT-NEXT:    (unreachable)
  ;; CKIIT-NEXT:   )
  ;; CKIIT-NEXT:  )
  ;; CKIIT-NEXT: )
  ;; CKTNH:      (func $cast-null-desc (type $2) (param $ref anyref) (param $desc nullref)
  ;; CKTNH-NEXT:  (nop)
  ;; CKTNH-NEXT: )
  (func $cast-null-desc (param $ref anyref) (param $desc nullref)
    (drop
      (ref.cast_desc (ref null $struct)
        (local.get $ref)
        (local.get $desc)
      )
    )
  )

  ;; CHECK:      (func $cast-nullable-desc (type $3) (param $ref anyref) (param $desc (ref null $desc))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast_desc (ref null $struct)
  ;; CHECK-NEXT:    (local.get $ref)
  ;; CHECK-NEXT:    (local.get $desc)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; CKIIT:      (func $cast-nullable-desc (type $3) (param $ref anyref) (param $desc (ref null $desc))
  ;; CKIIT-NEXT:  (nop)
  ;; CKIIT-NEXT: )
  ;; CKTNH:      (func $cast-nullable-desc (type $3) (param $ref anyref) (param $desc (ref null $desc))
  ;; CKTNH-NEXT:  (nop)
  ;; CKTNH-NEXT: )
  (func $cast-nullable-desc (param $ref anyref) (param $desc (ref null $desc))
    (drop
      (ref.cast_desc (ref null $struct)
        (local.get $ref)
        (local.get $desc)
      )
    )
  )

  ;; CHECK:      (func $cast-non-nullable-desc (type $4) (param $ref anyref) (param $desc (ref $desc))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast_desc (ref null $struct)
  ;; CHECK-NEXT:    (local.get $ref)
  ;; CHECK-NEXT:    (local.get $desc)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; CKIIT:      (func $cast-non-nullable-desc (type $4) (param $ref anyref) (param $desc (ref $desc))
  ;; CKIIT-NEXT:  (nop)
  ;; CKIIT-NEXT: )
  ;; CKTNH:      (func $cast-non-nullable-desc (type $4) (param $ref anyref) (param $desc (ref $desc))
  ;; CKTNH-NEXT:  (nop)
  ;; CKTNH-NEXT: )
  (func $cast-non-nullable-desc (param $ref anyref) (param $desc (ref $desc))
    (drop
      ;; The cast can still trap on failure, so by default we cannot remove it.
      (ref.cast_desc (ref null $struct)
        (local.get $ref)
        (local.get $desc)
      )
    )
  )

  ;; CHECK:      (func $br-on-cast-null-desc (type $2) (param $ref anyref) (param $desc nullref)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block $l (result anyref)
  ;; CHECK-NEXT:    (block ;; (replaces unreachable BrOn we can't emit)
  ;; CHECK-NEXT:     (drop
  ;; CHECK-NEXT:      (local.get $ref)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:     (drop
  ;; CHECK-NEXT:      (local.get $desc)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:     (unreachable)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; CKIIT:      (func $br-on-cast-null-desc (type $2) (param $ref anyref) (param $desc nullref)
  ;; CKIIT-NEXT:  (drop
  ;; CKIIT-NEXT:   (block $l (result anyref)
  ;; CKIIT-NEXT:    (block ;; (replaces unreachable BrOn we can't emit)
  ;; CKIIT-NEXT:     (drop
  ;; CKIIT-NEXT:      (local.get $ref)
  ;; CKIIT-NEXT:     )
  ;; CKIIT-NEXT:     (drop
  ;; CKIIT-NEXT:      (local.get $desc)
  ;; CKIIT-NEXT:     )
  ;; CKIIT-NEXT:     (unreachable)
  ;; CKIIT-NEXT:    )
  ;; CKIIT-NEXT:   )
  ;; CKIIT-NEXT:  )
  ;; CKIIT-NEXT: )
  ;; CKTNH:      (func $br-on-cast-null-desc (type $2) (param $ref anyref) (param $desc nullref)
  ;; CKTNH-NEXT:  (nop)
  ;; CKTNH-NEXT: )
  (func $br-on-cast-null-desc (param $ref anyref) (param $desc nullref)
    (drop
      (block $l (result anyref)
        (br_on_cast_desc $l anyref (ref null $struct)
          (local.get $ref)
          (local.get $desc)
        )
      )
    )
  )

  ;; CHECK:      (func $br-on-cast-nullable-desc (type $3) (param $ref anyref) (param $desc (ref null $desc))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block $l (result anyref)
  ;; CHECK-NEXT:    (br_on_cast_desc $l anyref (ref null $struct)
  ;; CHECK-NEXT:     (local.get $ref)
  ;; CHECK-NEXT:     (local.get $desc)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; CKIIT:      (func $br-on-cast-nullable-desc (type $3) (param $ref anyref) (param $desc (ref null $desc))
  ;; CKIIT-NEXT:  (nop)
  ;; CKIIT-NEXT: )
  ;; CKTNH:      (func $br-on-cast-nullable-desc (type $3) (param $ref anyref) (param $desc (ref null $desc))
  ;; CKTNH-NEXT:  (nop)
  ;; CKTNH-NEXT: )
  (func $br-on-cast-nullable-desc (param $ref anyref) (param $desc (ref null $desc))
    (drop
      (block $l (result anyref)
        (br_on_cast_desc $l anyref (ref null $struct)
          (local.get $ref)
          (local.get $desc)
        )
      )
    )
  )

  ;; CHECK:      (func $br-on-cast-non-nullable-desc (type $4) (param $ref anyref) (param $desc (ref $desc))
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  ;; CKIIT:      (func $br-on-cast-non-nullable-desc (type $4) (param $ref anyref) (param $desc (ref $desc))
  ;; CKIIT-NEXT:  (nop)
  ;; CKIIT-NEXT: )
  ;; CKTNH:      (func $br-on-cast-non-nullable-desc (type $4) (param $ref anyref) (param $desc (ref $desc))
  ;; CKTNH-NEXT:  (nop)
  ;; CKTNH-NEXT: )
  (func $br-on-cast-non-nullable-desc (param $ref anyref) (param $desc (ref $desc))
    (drop
      (block $l (result anyref)
        (br_on_cast_desc $l anyref (ref null $struct)
          (local.get $ref)
          (local.get $desc)
        )
      )
    )
  )
)
