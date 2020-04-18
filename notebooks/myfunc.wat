(module $myfunc
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

(func $f (export "f") (param $a f32) (param $b f32) (param $c f32) (param $d f32) (result f32)
(call $log(call $pow(f32.mul(call $sqrt(f32.add(local.get $a)(local.get $b)))(call $exp(f32.add(local.get $c)(local.get $d))))(f32.const 7.0)))
)

)