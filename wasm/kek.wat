(module $../wasm/kek
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

(func $f (export "f") (param $N f32) (result f32)
((block (loop (br_if 1 (i32.eqz(i32.lt_s(i32.const 10)))))(i32.add(i32.const 1))(f32.add(local.get $N))(br 0)))
)

)