;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.

;; RUN: wasm-opt %s -all --preserve-type-order --string-lowering -S -o - | filecheck %s

(module
  (rec
    ;; CHECK:      (type $0 (func))

    ;; CHECK:      (type $1 (func (param externref) (result i32)))

    ;; CHECK:      (type $2 (array (mut i16)))

    ;; CHECK:      (rec
    ;; CHECK-NEXT:  (type $struct-of-string (struct (field externref) (field i32) (field anyref)))
    (type $struct-of-string (struct (field stringref) (field i32) (field anyref)))

    ;; CHECK:       (type $struct-of-array (struct (field (ref $2))))
    (type $struct-of-array (struct (field (ref $array16))))

    ;; CHECK:       (type $array16-imm (array i32))
    (type $array16-imm (array i32))

    ;; CHECK:       (type $array32 (array (mut i32)))
    (type $array32 (array (mut i32)))

    ;; CHECK:       (type $array16-open (sub (array (mut i16))))
    (type $array16-open (sub (array (mut i16))))

    ;; CHECK:       (type $array16-child (sub $array16-open (array (mut i16))))
    (type $array16-child (sub $array16-open (array (mut i16))))

    ;; CHECK:       (type $array16 (array (mut i16)))
    (type $array16 (array (mut i16)))
  )

  ;; CHECK:       (type $10 (func (param (ref $2))))

  ;; CHECK:       (type $11 (func (param externref) (result i32)))

  ;; CHECK:       (type $12 (func (param externref externref) (result (ref extern))))

  ;; CHECK:       (type $13 (func (param externref (ref $2)) (result i32)))

  ;; CHECK:       (type $14 (func (param externref externref) (result i32)))

  ;; CHECK:       (type $15 (func (param externref) (result externref)))

  ;; CHECK:       (type $16 (func (param externref)))

  ;; CHECK:      (type $17 (func (result externref)))

  ;; CHECK:      (type $18 (func (param externref externref) (result i32)))

  ;; CHECK:      (type $19 (func (param externref i32 externref)))

  ;; CHECK:      (type $20 (func (param (ref null $2) i32 i32) (result (ref extern))))

  ;; CHECK:      (type $21 (func (param i32) (result (ref extern))))

  ;; CHECK:      (type $22 (func (param externref externref) (result (ref extern))))

  ;; CHECK:      (type $23 (func (param externref (ref null $2) i32) (result i32)))

  ;; CHECK:      (type $24 (func (param externref i32) (result i32)))

  ;; CHECK:      (type $25 (func (param externref i32 i32) (result (ref extern))))

  ;; CHECK:      (import "string.const" "0" (global $"string.const_\"exported\"" (ref extern)))

  ;; CHECK:      (import "string.const" "1" (global $"string.const_\"value\"" (ref extern)))

  ;; CHECK:      (import "colliding" "name" (func $fromCodePoint (type $0)))
  (import "colliding" "name" (func $fromCodePoint))


  ;; CHECK:      (import "wasm:js-string" "fromCharCodeArray" (func $fromCharCodeArray (type $20) (param (ref null $2) i32 i32) (result (ref extern))))

  ;; CHECK:      (import "wasm:js-string" "fromCodePoint" (func $fromCodePoint_19 (type $21) (param i32) (result (ref extern))))

  ;; CHECK:      (import "wasm:js-string" "concat" (func $concat (type $22) (param externref externref) (result (ref extern))))

  ;; CHECK:      (import "wasm:js-string" "intoCharCodeArray" (func $intoCharCodeArray (type $23) (param externref (ref null $2) i32) (result i32)))

  ;; CHECK:      (import "wasm:js-string" "equals" (func $equals (type $18) (param externref externref) (result i32)))

  ;; CHECK:      (import "wasm:js-string" "test" (func $test (type $1) (param externref) (result i32)))

  ;; CHECK:      (import "wasm:js-string" "compare" (func $compare (type $18) (param externref externref) (result i32)))

  ;; CHECK:      (import "wasm:js-string" "length" (func $length (type $1) (param externref) (result i32)))

  ;; CHECK:      (import "wasm:js-string" "charCodeAt" (func $charCodeAt (type $24) (param externref i32) (result i32)))

  ;; CHECK:      (import "wasm:js-string" "substring" (func $substring (type $25) (param externref i32 i32) (result (ref extern))))

  ;; CHECK:      (global $string externref (ref.null noextern))
  (global $string stringref (ref.null string)) ;; Test we update global nulls.

  ;; CHECK:      (export "export.1" (func $exported-string-returner))

  ;; CHECK:      (export "export.2" (func $exported-string-receiver))

  ;; CHECK:      (func $string.new.gc (type $10) (param $array16 (ref $2))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (call $fromCharCodeArray
  ;; CHECK-NEXT:    (local.get $array16)
  ;; CHECK-NEXT:    (i32.const 7)
  ;; CHECK-NEXT:    (i32.const 8)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.new.gc (param $array16 (ref $array16))
    (drop
      (string.new_wtf16_array
        (local.get $array16)
        (i32.const 7)
        (i32.const 8)
      )
    )
  )

  ;; CHECK:      (func $string.from_code_point (type $17) (result externref)
  ;; CHECK-NEXT:  (call $fromCodePoint_19
  ;; CHECK-NEXT:   (i32.const 1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.from_code_point (result stringref)
    (string.from_code_point
      (i32.const 1)
    )
  )

  ;; CHECK:      (func $string.concat (type $12) (param $0 externref) (param $1 externref) (result (ref extern))
  ;; CHECK-NEXT:  (call $concat
  ;; CHECK-NEXT:   (local.get $0)
  ;; CHECK-NEXT:   (local.get $1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.concat (param stringref stringref) (result (ref string))
   (string.concat
    (local.get 0)
    (local.get 1)
   )
  )

  ;; CHECK:      (func $string.encode (type $13) (param $ref externref) (param $array16 (ref $2)) (result i32)
  ;; CHECK-NEXT:  (call $intoCharCodeArray
  ;; CHECK-NEXT:   (local.get $ref)
  ;; CHECK-NEXT:   (local.get $array16)
  ;; CHECK-NEXT:   (i32.const 10)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.encode (param $ref stringref) (param $array16 (ref $array16)) (result i32)
    (string.encode_wtf16_array
      (local.get $ref)
      (local.get $array16)
      (i32.const 10)
    )
  )

  ;; CHECK:      (func $string.eq (type $14) (param $a externref) (param $b externref) (result i32)
  ;; CHECK-NEXT:  (call $equals
  ;; CHECK-NEXT:   (local.get $a)
  ;; CHECK-NEXT:   (local.get $b)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.eq (param $a stringref) (param $b stringref) (result i32)
    (string.eq
      (local.get $a)
      (local.get $b)
    )
  )

  ;; CHECK:      (func $string.compare (type $14) (param $a externref) (param $b externref) (result i32)
  ;; CHECK-NEXT:  (call $compare
  ;; CHECK-NEXT:   (local.get $a)
  ;; CHECK-NEXT:   (local.get $b)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.compare (param $a stringref) (param $b stringref) (result i32)
    (string.compare
      (local.get $a)
      (local.get $b)
    )
  )

  ;; CHECK:      (func $string-test (type $11) (param $str externref) (result i32)
  ;; CHECK-NEXT:  (call $test
  ;; CHECK-NEXT:   (local.get $str)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string-test (param $str externref) (result i32)
    (string.test
      (local.get $str)
    )
  )

  ;; CHECK:      (func $string.length (type $11) (param $ref externref) (result i32)
  ;; CHECK-NEXT:  (call $length
  ;; CHECK-NEXT:   (local.get $ref)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.length (param $ref stringref) (result i32)
    (string.measure_wtf16
      (local.get $ref)
    )
  )

  ;; CHECK:      (func $string.get_codeunit (type $11) (param $ref externref) (result i32)
  ;; CHECK-NEXT:  (call $charCodeAt
  ;; CHECK-NEXT:   (local.get $ref)
  ;; CHECK-NEXT:   (i32.const 2)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.get_codeunit (param $ref stringref) (result i32)
    (stringview_wtf16.get_codeunit
      (local.get $ref)
      (i32.const 2)
    )
  )

  ;; CHECK:      (func $string.slice (type $15) (param $ref externref) (result externref)
  ;; CHECK-NEXT:  (call $substring
  ;; CHECK-NEXT:   (local.get $ref)
  ;; CHECK-NEXT:   (i32.const 2)
  ;; CHECK-NEXT:   (i32.const 3)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.slice (param $ref stringref) (result stringref)
    (stringview_wtf16.slice
      (local.get $ref)
      (i32.const 2)
      (i32.const 3)
    )
  )

  ;; CHECK:      (func $if.string (type $15) (param $ref externref) (result externref)
  ;; CHECK-NEXT:  (if (result externref)
  ;; CHECK-NEXT:   (i32.const 0)
  ;; CHECK-NEXT:   (then
  ;; CHECK-NEXT:    (ref.null noextern)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (else
  ;; CHECK-NEXT:    (local.get $ref)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $if.string (param $ref stringref) (result stringref)
    (if (result stringref)
      (i32.const 0)
      (then
        (ref.null noextern) ;; The change from stringref to externref does not
                            ;; cause problems here, nothing needs to change.
      )
      (else
        (local.get $ref)
      )
    )
  )

  ;; CHECK:      (func $if.string.flip (type $15) (param $ref externref) (result externref)
  ;; CHECK-NEXT:  (if (result externref)
  ;; CHECK-NEXT:   (i32.const 0)
  ;; CHECK-NEXT:   (then
  ;; CHECK-NEXT:    (local.get $ref)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (else
  ;; CHECK-NEXT:    (ref.null noextern)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $if.string.flip (param $ref stringref) (result stringref)
    ;; As above but with flipped arms.
    (if (result stringref)
      (i32.const 0)
      (then
        (local.get $ref)
      )
      (else
        (ref.null noextern)
      )
    )
  )

  ;; CHECK:      (func $exported-string-returner (type $17) (result externref)
  ;; CHECK-NEXT:  (global.get $"string.const_\"exported\"")
  ;; CHECK-NEXT: )
  (func $exported-string-returner (export "export.1") (result stringref)
    ;; We should update the signature of this function even though it is public
    ;; (exported).
    (string.const "exported")
  )

  ;; CHECK:      (func $exported-string-receiver (type $19) (param $x externref) (param $y i32) (param $z externref)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $y)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $z)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $exported-string-receiver (export "export.2") (param $x stringref) (param $y i32) (param $z stringref)
    ;; We should update the signature of this function even though it is public
    ;; (exported).
    (drop
      (local.get $x)
    )
    (drop
      (local.get $y)
    )
    (drop
      (local.get $z)
    )
  )

  ;; CHECK:      (func $use-struct-of-array (type $0)
  ;; CHECK-NEXT:  (local $array16 (ref $2))
  ;; CHECK-NEXT:  (local $open (ref $array16-open))
  ;; CHECK-NEXT:  (local $child (ref $array16-child))
  ;; CHECK-NEXT:  (local $32 (ref $array32))
  ;; CHECK-NEXT:  (local $imm (ref $array16-imm))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (call $fromCharCodeArray
  ;; CHECK-NEXT:    (struct.get $struct-of-array 0
  ;; CHECK-NEXT:     (struct.new $struct-of-array
  ;; CHECK-NEXT:      (array.new_fixed $2 2
  ;; CHECK-NEXT:       (i32.const 10)
  ;; CHECK-NEXT:       (i32.const 20)
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 0)
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $use-struct-of-array
    ;; The array type here should switch to the new 16-bit array type that we
    ;; use for the new imports, so that it is compatible with them. Without
    ;; that, calling the import as we do below will fail.
    (local $array16 (ref $array16))

    ;; In comparison, the array16-open param should remain as it is: it is an
    ;; open type which is different then the one we care about.
    (local $open (ref $array16-open))

    ;; Likewise a child of that open type is also ignored.
    (local $child (ref $array16-child))

    ;; Another array size is also ignored.
    (local $32 (ref $array32))

    ;; An immutable array is also ignored.
    (local $imm (ref $array16-imm))

    (drop
      (string.new_wtf16_array
        (struct.get $struct-of-array 0
          (struct.new $struct-of-array
            (array.new_fixed $array16 2
              (i32.const 10)
              (i32.const 20)
            )
          )
        )
        (i32.const 0)
        (i32.const 1)
      )
    )
  )

  ;; CHECK:      (func $struct-of-string (type $0)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new $struct-of-string
  ;; CHECK-NEXT:    (ref.null noextern)
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (ref.null none)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new $struct-of-string
  ;; CHECK-NEXT:    (global.get $"string.const_\"value\"")
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (ref.null none)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_default $struct-of-string)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $struct-of-string
    ;; Test lowering of struct fields from stringref to externref. This was more
    ;; useful of a test when stringref was a subtype of anyref, but it is still
    ;; useful to verify nothing here goes wrong. (Now we convert stringref to
    ;; externref, a supertype, which is much simpler - same bottom type, etc.)
    (drop
      (struct.new $struct-of-string
        (ref.null noextern) ;; This null is already of the right type.
        (i32.const 10)
        (ref.null none) ;; Nothing to do here (field remains anyref).
      )
    )
    (drop
      (struct.new $struct-of-string
        (string.const "value") ;; Nothing to do besides change to a global.
        (i32.const 10)
        (ref.null none)
      )
    )
    (drop
      (struct.new_default $struct-of-string) ;; Nothing to do here.
    )
  )

  ;; CHECK:      (func $call-param-null (type $16) (param $str externref)
  ;; CHECK-NEXT:  (call $call-param-null
  ;; CHECK-NEXT:   (ref.null noextern)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $call-param-null (param $str stringref)
    ;; After the lowering this null must be an ext.
    (call $call-param-null
      (ref.null string)
    )
  )
)
