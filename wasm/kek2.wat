(module
  (type (;0;) (func (param f32) (result f32)))
  (func (;0;) (type 0) (param f32) (result f32)
    (local i32 f32)
    loop  ;; label = @1
      local.get 1
      i32.const 10
      i32.ge_s
      i32.eqz
      if  ;; label = @2
        local.get 1
        i32.const 1
        i32.add
        local.set 1
        local.get 2
        local.get 0
        f32.add
        local.set 2
        br 1 (;@1;)
      end
    end
    local.get 2
    f32.const 0x1.0cccccp+1 (;=2.1;)
    f32.add)
  (export "f" (func 0)))
