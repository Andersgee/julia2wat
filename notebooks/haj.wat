(module $haj
(memory (import "imports" "mem") 1)
(func $consolelog (import "imports" "consolelog") (param f32))
(func $sqrt (import "imports" "sqrt") (param f32) (result f32))
(func $exp (import "imports" "exp") (param f32) (result f32))
(func $log (import "imports" "log") (param f32) (result f32))
(func $pow (import "imports" "pow") (param f32 f32) (result f32))
(func $powi (import "imports" "pow") (param i32 i32) (result i32))
(func $sin (import "imports" "sin") (param f32) (result f32))
(func $cos (import "imports" "cos") (param f32) (result f32))
(func $asin (import "imports" "asin") (param f32) (result f32))
(func $acos (import "imports" "acos") (param f32) (result f32))
(func $atan (import "imports" "atan") (param f32) (result f32))

(func $a (export "a") (param $x f32) (result f32)
(br_if15(i32.eqtrue))(f32.add(local.get $x))(br_if8(i32.eq(i32.eq(i32.const 10))))(i32.add(i32.const 1))(br_if15(i32.eq(i32.ne)))
)

)