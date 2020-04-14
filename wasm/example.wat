(module
  (type (;0;) (func (param f32) (result f32)))
  (type (;1;) (func (param f32 f32 f32) (result f32)))
  (type (;2;) (func (param i32 f32 f32 f32 f32 f32)))
  (type (;3;) (func (param f32)))
  (type (;4;) (func (param f32 f32) (result f32)))
  (type (;5;) (func (param f32 f32 f32 f32) (result f32)))
  (import "imports" "consolelog" (func (;0;) (type 3)))
  (import "imports" "pow" (func (;1;) (type 4)))
  (import "imports" "sin" (func (;2;) (type 0)))
  (import "imports" "cos" (func (;3;) (type 0)))
  (import "imports" "asin" (func (;4;) (type 0)))
  (import "imports" "atan" (func (;5;) (type 0)))
  (import "imports" "mem" (memory (;0;) 1))
  (func (;6;) (type 5) (param f32 f32 f32 f32) (result f32)
    local.get 1
    f32.const 0x1.5c28f6p-3 (;=0.17;)
    f32.const 0x1.921fb6p+3 (;=12.5664;)
    local.get 0
    f32.const 0x1.4p+6 (;=80;)
    f32.sub
    f32.mul
    f32.const 0x1.75p+8 (;=373;)
    f32.div
    call 2
    f32.mul
    f32.add
    f32.const 0x1.083126p-3 (;=0.129;)
    f32.const 0x1.921fb6p+2 (;=6.28319;)
    local.get 0
    f32.const 0x1p+3 (;=8;)
    f32.sub
    f32.mul
    f32.const 0x1.63p+8 (;=355;)
    f32.div
    call 2
    f32.mul
    f32.sub
    f32.const 0x1.8p+3 (;=12;)
    local.get 2
    local.get 3
    f32.sub
    f32.mul
    f32.const 0x1.921fb6p+1 (;=3.14159;)
    f32.div
    f32.add)
  (func (;7;) (type 1) (param f32 f32 f32) (result f32)
    f32.const 0x1.921fb6p+0 (;=1.5708;)
    local.get 2
    call 2
    local.get 1
    call 2
    f32.mul
    local.get 2
    call 3
    local.get 1
    call 3
    f32.mul
    f32.const 0x1.921fb6p+1 (;=3.14159;)
    local.get 0
    f32.mul
    f32.const 0x1.8p+3 (;=12;)
    f32.div
    call 3
    f32.mul
    f32.sub
    call 4
    f32.sub)
  (func (;8;) (type 1) (param f32 f32 f32) (result f32)
    local.get 1
    call 3
    f32.neg
    f32.const 0x1.921fb6p+1 (;=3.14159;)
    local.get 0
    f32.mul
    f32.const 0x1.8p+3 (;=12;)
    f32.div
    local.tee 0
    call 2
    f32.mul
    local.get 2
    call 3
    local.get 1
    call 2
    f32.mul
    local.get 2
    call 2
    local.get 1
    call 3
    f32.mul
    local.get 0
    call 3
    f32.mul
    f32.sub
    f32.div
    call 5)
  (func (;9;) (type 2) (param i32 f32 f32 f32 f32 f32)
    (local i32 f32)
    local.get 0
    i32.const 4
    i32.add
    local.tee 6
    local.get 1
    local.get 2
    local.get 5
    local.get 3
    call 6
    f32.const 0x1.a31f8ap-2 (;=0.4093;)
    f32.const 0x1.921fb6p+2 (;=6.28319;)
    local.get 1
    f32.const 0x1.44p+6 (;=81;)
    f32.sub
    f32.mul
    f32.const 0x1.7p+8 (;=368;)
    f32.div
    local.tee 7
    call 2
    f32.mul
    f32.const 0x1.0cccccp+2 (;=4.2;)
    call 1
    local.get 4
    call 7
    f32.store
    local.get 0
    i32.const 8
    i32.add
    local.tee 0
    local.get 1
    local.get 2
    local.get 5
    local.get 3
    call 6
    f32.const 0x1.a31f8ap-2 (;=0.4093;)
    local.get 7
    call 2
    f32.mul
    local.get 4
    call 8
    f32.store
    local.get 6
    f32.load
    call 0
    local.get 0
    f32.load
    call 0)
  (export "solartime" (func 6))
  (export "solarzenith" (func 7))
  (export "solarazimuth" (func 8))
  (export "solarposition" (func 9)))
