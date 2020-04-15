# julia2wat
```julia
function f(a,b,c,d)
  k=sqrt(a+b)*exp(c+d)
  return log(k^7)
end
```
```julia
using julia2wat
@code_wat f(1.0, 2.0, 3.0, 4.0) "myfunc"
#INFO: saved myfunc.wat
```
Contents of myfunc.wat now looks something like this:
```wat
(module $myfunc
(memory (import "imports" "mem") 1)
(func $sqrt (import "imports" "sqrt") (param f32) (result f32))
(func $exp (import "imports" "exp") (param f32) (result f32))
(func $log (import "imports" "log") (param f32) (result f32))
(func $pow (import "imports" "pow") (param f32 f32) (result f32))

(func $f (export "f") (param $a f32) (param $b f32) (param $c f32) (param $d f32) (result f32)
(call $log(call $pow(f32.mul(call $sqrt(f32.add(local.get $a)(local.get $b)))(call $exp(f32.add(local.get $c)(local.get $d))))(f32.const 7.0)))
)

)
```
See notebooks/example.ipynb for a slightly more involved example using a module and multiple functions.

## Usage on a website
unrelated to this repo, to use webassembly on a website we need to convert .wat to .wasm and instantiate it in javascript
* convert to wasm [wat2wasm](https://github.com/WebAssembly/wabt)
* (recommended) optimize wasm [wasm-opt](https://github.com/WebAssembly/binaryen)

```julia
compilewat("myfunc") #call a bash script that does wat2wasm, wasm-opt and wasm2wat
#INFO: saved binaryen optimized myfunc.wasm
#(also translated back and overwritten myfunc.wat)
```
Contents of myfunc.wat now looks like this:
```wat
(module
  (type (;0;) (func (param f32) (result f32)))
  (type (;1;) (func (param f32 f32) (result f32)))
  (type (;2;) (func (param f32 f32 f32 f32) (result f32)))
  (import "imports" "sqrt" (func (;0;) (type 0)))
  (import "imports" "exp" (func (;1;) (type 0)))
  (import "imports" "log" (func (;2;) (type 0)))
  (import "imports" "pow" (func (;3;) (type 1)))
  (func (;4;) (type 2) (param f32 f32 f32 f32) (result f32)
    local.get 0
    local.get 1
    f32.add
    call 0
    local.get 2
    local.get 3
    f32.add
    call 1
    f32.mul
    f32.const 0x1.cp+2 (;=7;)
    call 3
    call 2)
  (export "f" (func 4)))
```

Calling the function from javascript:
```js
async function webassembly(filename) {
  var memory = new WebAssembly.Memory({initial:37, maximum:37});
  var imports = {
    mem: memory,
    pow: (x,y) => {return Math.pow(x,y)},
    sqrt: x => {return Math.sqrt(x)},
    exp: x => {return Math.exp(x)},
    log: x => {return Math.log(x)},
  }
  var {instance} = await WebAssembly.instantiateStreaming(fetch(filename), {imports});

  var wasm = {};
  wasm.mem = memory.buffer;
  wasm.f = instance.exports.f;
  return wasm;
}

webassembly("myfunc.wasm").then(wasm=>{
  var result = wasm.f(1.0, 2.0, 3.0, 4.0)
  console.log(result)
})
```
