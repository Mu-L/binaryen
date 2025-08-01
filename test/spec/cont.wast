;; Unhandled tags & guards

(module
  (tag $exn)
  (tag $e1)
  (tag $e2)

  (type $f1 (func))
  (type $k1 (cont $f1))

  (func $f1 (export "unhandled-1")
    (suspend $e1)
  )

  (func (export "unhandled-2")
    (resume $k1 (cont.new $k1 (ref.func $f1)))
  )

  (func (export "unhandled-3")
    (block $h (result (ref $k1))
      (resume $k1 (on $e2 $h) (cont.new $k1 (ref.func $f1)))
      (unreachable)
    )
    (drop)
  )

  (func (export "handled")
    (block $h (result (ref $k1))
      (resume $k1 (on $e1 $h) (cont.new $k1 (ref.func $f1)))
      (unreachable)
    )
    (drop)
  )

  (elem declare func $f2)
  (func $f2
    (throw $exn)
  )

  (func (export "uncaught-1")
    (block $h (result (ref $k1))
      (resume $k1 (on $e1 $h) (cont.new $k1 (ref.func $f2)))
      (unreachable)
    )
    (drop)
  )

  (func (export "uncaught-2")
    (block $h (result (ref $k1))
      (resume $k1 (on $e1 $h) (cont.new $k1 (ref.func $f1)))
      (unreachable)
    )
    (resume_throw $k1 $exn)
  )

  (elem declare func $f3)
  (func $f3
    (call $f4)
  )
  (func $f4
    (suspend $e1)
  )

  (func (export "uncaught-3")
    (block $h (result (ref $k1))
      (resume $k1 (on $e1 $h) (cont.new $k1 (ref.func $f3)))
      (unreachable)
    )
    (resume_throw $k1 $exn)
  )

  (elem declare func $r0 $r1)
  (func $r0)
  (func $r1 (suspend $e1) (suspend $e1))

  (func $nl1 (param $k (ref $k1))
    (resume $k1 (local.get $k))
    (resume $k1 (local.get $k))
  )
  (func $nl2 (param $k (ref $k1))
    (block $h (result (ref $k1))
      (resume $k1 (on $e1 $h) (local.get $k))
      (unreachable)
    )
    (resume $k1 (local.get $k))
    (unreachable)
  )
  (func $nl3 (param $k (ref $k1))
    (local $k' (ref null $k1))
    (block $h1 (result (ref $k1))
      (resume $k1 (on $e1 $h1) (local.get $k))
      (unreachable)
    )
    (local.set $k')
    (block $h2 (result (ref $k1))
      (resume $k1 (on $e1 $h2) (local.get $k'))
      (unreachable)
    )
    (resume $k1 (local.get $k'))
    (unreachable)
  )
  (func $nl4 (param $k (ref $k1))
    (drop (cont.bind $k1 $k1 (local.get $k)))
    (resume $k1 (local.get $k))
  )

  (func (export "non-linear-1")
    (call $nl1 (cont.new $k1 (ref.func $r0)))
  )
  (func (export "non-linear-2")
    (call $nl2 (cont.new $k1 (ref.func $r1)))
  )
  (func (export "non-linear-3")
    (call $nl3 (cont.new $k1 (ref.func $r1)))
  )
  (func (export "non-linear-4")
    (call $nl4 (cont.new $k1 (ref.func $r1)))
  )
)

(assert_suspension (invoke "unhandled-1") "unhandled")
(assert_suspension (invoke "unhandled-2") "unhandled")
(assert_suspension (invoke "unhandled-3") "unhandled")
(assert_return (invoke "handled"))

(assert_exception (invoke "uncaught-1"))
;; TODO: resume_throw (assert_exception (invoke "uncaught-2"))
;; TODO: resume_throw (assert_exception (invoke "uncaught-3"))

(assert_trap (invoke "non-linear-1") "continuation already consumed")
(assert_trap (invoke "non-linear-2") "continuation already consumed")
(assert_trap (invoke "non-linear-3") "continuation already consumed")
;; TODO: cont.bind (assert_trap (invoke "non-linear-4") "continuation already consumed")

(assert_invalid
  (module
    (type $ft (func))
    (func
      (cont.new $ft (ref.null $ft))
      (drop)))
  "non-continuation type 0")

(assert_invalid
  (module
    (type $ft (func))
    (type $ct (cont $ft))
    (func
      (resume $ft (ref.null $ct))
      (unreachable)))
  "non-continuation type 0")

(assert_invalid
  (module
    (type $ft (func))
    (type $ct (cont $ft))
    (tag $exn)
    (func
      (resume_throw $ft $exn (ref.null $ct))
      (unreachable)))
  "non-continuation type 0")

(assert_invalid
  (module
    (type $ft (func))
    (type $ct (cont $ft))
    (func
      (cont.bind $ft $ct (ref.null $ct))
      (unreachable)))
  "non-continuation type 0")

(assert_invalid
  (module
    (type $ft (func))
    (type $ct (cont $ft))
    (func
      (cont.bind $ct $ft (ref.null $ct))
      (unreachable)))
  "non-continuation type 0")

(assert_invalid
  (module
    (type $ft (func))
    (type $ct (cont $ft))
    (tag $foo)
    (func
      (block $on_foo (result (ref $ft))
        (resume $ct (on $foo $on_foo) (ref.null $ct))
        (unreachable)
      )
      (drop)))
  "non-continuation type 0")

(assert_invalid
  (module
    (type $ft (func))
    (type $ct (cont $ft))
    (tag $foo)
    (func
      (block $on_foo (result (ref $ct) (ref $ft))
        (resume $ct (on $foo $on_foo) (ref.null $ct))
        (unreachable)
      )
      (drop)
      (drop)))
  "non-continuation type 0")

(assert_invalid
  (module
    (type $ct (cont $ct)))
  "non-function type 0")

(assert_invalid
  (module
    (rec
      (type $s0 (struct (field (ref 0) (ref 1) (ref $s0) (ref $s1))))
      (type $s1 (struct (field (ref 0) (ref 1) (ref $s0) (ref $s1))))
    )
    (type $ct (cont $s0)))
  "non-function type 0")

(module
  (rec
    (type $f1 (func (param (ref $f2))))
    (type $f2 (func (param (ref $f1))))
  )
  (type $c1 (cont $f1))
  (type $c2 (cont $f2))
)

