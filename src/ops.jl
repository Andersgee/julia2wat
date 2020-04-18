import Base: llvmcall
import Base: sqrt, ^, min, max

#sqrt, min,max and ^ has some ifelse, signbit, isnan checks...
#pirate them to avoid the isnan check and make julia produce cleaner code_typed.

sqrt_llvm(x::Float64) = llvmcall(("declare double @llvm.sqrt.f64(double %Val)",
    "%2 = call double @llvm.sqrt.f64(double %0) ret double %2"), Float64, Tuple{Float64}, x)
pow_llvm(x::Float64, y::Float64) = llvmcall(("declare double @llvm.pow.f64(double %Val, double %Power)",
    "%3 = call double @llvm.pow.f64(double %0, double %1) ret double %3"), Float64, Tuple{Float64, Float64}, x,y)
min_llvm(x::Float64, y::Float64) = llvmcall(("declare double @llvm.minnum.f64(double %Val0, double %Val1)",
    "%3 = call double @llvm.minnum.f64(double %0, double %1) ret double %3"), Float64, Tuple{Float64, Float64}, x,y)
max_llvm(x::Float64, y::Float64) = llvmcall(("declare double @llvm.maxnum.f64(double %Val0, double %Val1)",
    "%3 = call double @llvm.maxnum.f64(double %0, double %1) ret double %3"), Float64, Tuple{Float64, Float64}, x,y)
#powi_llvm(x::Float64, y::Int64) = llvmcall(("declare double @llvm.powi.f64(double %Val, i32 %power)",
#    "%3 = call double @llvm.powi.f64(double %0, i32 %1) ret double %3"), Float64, Tuple{Float64, Int32}, x,Int32(y))

sqrt(x::Float64) = sqrt_llvm(x)
sqrt(x::Int64) = sqrt_llvm(Float64(x))

^(x::Float64,y::Float64) = pow_llvm(x,y)
^(x::Int64,y::Float64)  = pow_llvm(Float64(x),y)
^(x::Float64,y::Int64) = pow_llvm(x,Float64(y))
#^(x::Float64,y::Int64) = powi_llvm(x,y) #powi_llvm

min(x::Float64, y::Float64) = min_llvm(x,y)
max(x::Float64, y::Float64) = max_llvm(x,y)

min(x::Int64, y::Int64) = ifelse(x<y, x, y)
max(x::Int64, y::Int64) = ifelse(x<y, y, x)


#https://webassembly.github.io/spec/core/text/instructions.html

op=Dict(
#f32
:(sqrt_llvm)=>"f32.sqrt", #square root
:(min_llvm)=>"f32.min", #minimum (binary operator); if either operand is NaN, returns NaN
:(max_llvm)=>"f32.max", #maximum (binary operator); if either operand is NaN, returns NaN
:(add_float)=>"f32.add", #addition
:(sub_float)=>"f32.sub", #subtraction
:(mul_float)=>"f32.mul", #multiplication
:(div_float)=>"f32.div", #division
:(abs_float)=>"f32.abs", #absolute value
:(neg_float)=>"f32.neg", #negation
:(copysign_float)=>"f32.copysign", #copysign
:(ceil_llvm)=>"f32.ceil", #ceiling operator
:(floor_llvm)=>"f32.floor", #floor operator
:(trunc_llvm)=>"f32.trunc", #round to nearest integer towards zero
:(rint_llvm)=>"f32.nearest", #round to nearest integer, ties to even
:(eq_float)=>"f32.eq", #compare ordered and equal
:(ne_float)=>"f32.ne", #compare unordered or unequal
:(lt_float)=>"f32.lt", #compare ordered and less than
:(le_float)=>"f32.le", #compare ordered and less than or equal

#typecasting
:(sitofp)=>"f32.convert_s/i32", #convert a signed 32-bit integer to a 32-bit float
:(fptosi)=>"i32.trunc_s/f32", #truncate a 32-bit float to a signed 32-bit integer

#i32
#All comparison operators yield 32-bit integer results with 1 representing true and 0 representing false.
:(add_int)=>"i32.add", #sign-agnostic addition
:(sub_int)=>"i32.sub", #sign-agnostic subtraction
:(mul_int)=>"i32.mul", #sign-agnostic multiplication (lower 32-bits)
:(checked_sdiv_int)=>"i32.div_s", #signed division (result is truncated toward zero)
:(checked_srem_int)=>"i32.rem_s", #signed remainder (result has the sign of the dividend)
:(and_int)=>"i32.and", #sign-agnostic bitwise and
:(or_int)=>"i32.or", #sign-agnostic bitwise inclusive or
:(xor_int)=>"i32.xor", #sign-agnostic bitwise exclusive or
:(===)=>"i32.eq", #sign-agnostic compare equal
:(not_int)=>"i32.ne", #sign-agnostic compare unequal
:(slt_int)=>"i32.lt_s", #signed less than
:(sle_int)=>"i32.le_s", #signed less than or equal
#"i32.eqz", #compare equal to zero (return 1 if operand is zero, 0 otherwise)
#gotoifnot

#matmul? #using LinearAlgebra: mul!, dot
#:(gemm_wrapper!)=>"call \$matmul",
#:(gemv!)=>"call \$matvecmul",

:(pow_llvm)=>"call \$pow", #power
#:(power_by_squaring)=>"call \$powi", #power #int^int
:(^)=>"call \$powi", #power int^int

#JS imports
:(println)=>"call \$consolelog",
:(literal_pow)=>"call \$pow",
:(exp)=>"call \$exp",
:(log)=>"call \$log",
:(sin)=>"call \$sin",
:(cos)=>"call \$cos",
:(tan)=>"call \$tan",
:(asin)=>"call \$asin",
:(acos)=>"call \$acos",
:(atan)=>"call \$atan",
#:(add_sum)=>"call \$sum",
:(mapreduce_impl)=>"call \$sum",
:(arraylen)=>"i32.load",

)

function JSimports()
	return """
(memory (import "imports" "mem") 1)
(func \$consolelog (import "imports" "consolelog") (param f32))
(func \$sqrt (import "imports" "sqrt") (param f32) (result f32))
(func \$exp (import "imports" "exp") (param f32) (result f32))
(func \$log (import "imports" "log") (param f32) (result f32))
(func \$pow (import "imports" "pow") (param f32 f32) (result f32))
(func \$powi (import "imports" "pow") (param i32 i32) (result i32))
(func \$sin (import "imports" "sin") (param f32) (result f32))
(func \$cos (import "imports" "cos") (param f32) (result f32))
(func \$asin (import "imports" "asin") (param f32) (result f32))
(func \$acos (import "imports" "acos") (param f32) (result f32))
(func \$atan (import "imports" "atan") (param f32) (result f32))
"""
end

## SPECIAL OPERATIONS

op_get(s,cinfo,a) = push!(s,string("(local.get \$",cinfo.slotnames[a.id],")"))
op_number(s,cinfo,a) = (typeof(a) <: AbstractFloat) ? push!(s, string("(f32.const ",a,")")) : push!(s, string("(i32.const ",a,")"))

type2str(t) = (t <: AbstractFloat) ? "f32" : "i32";

## SPECIAL EXPRESSIONS

#function ex_set()
#end

function ex_llvm(s, cinfo, as, SSAid)
    if (as[2]=="declare double @llvm.sqrt.f64(double %Val)")
        push!(s,"call \$sqrt")
    elseif (as[2]=="declare double @llvm.pow.f64(double %Val, double %Power)")
        push!(s,"call \$pow")
    elseif (as[2]=="declare double @llvm.minnum.f64(double %Val0, double %Val1)")
        push!(s,"f32.min")
    elseif (as[2]=="declare double @llvm.maxnum.f64(double %Val0, double %Val1)")
        push!(s,"f32.max")
    else
        println("DEBUGINFO: PIRATED",as)
    end
end

function ex_gotoifnot(s, cinfo, as, SSAid)
    #(block (loop (br_if 1 (i32.eqz (i32.lt_s (get_local $i) (i32.const 10))))
    push!(s, "(block (loop (br_if 1 (i32.eqz")
    parseitem(s, cinfo, as[1], SSAid)
    push!(s, "))") #end eqz, end block loop later at the gotonode
end

function ex_ifelse(s, cinfo, as, SSAid)
	push!(s, "select")
	parseitem(s, cinfo, as[3], SSAid)
	parseitem(s, cinfo, as[4], SSAid)
	parseitem(s, cinfo, as[2], SSAid)
end

function ex_println(s, cinfo, as, SSAid)
	push!(s, "call \$consolelog ")
	parseitems(s, cinfo, as[3:end], SSAid)
	#push!(s, ")")
end

function ex_arrayref(s, cinfo, as, SSAid)
    #as=[GlobalRef, Bool=true, arrayname, idx]
    #                                  3        4
    push!(s, string("f32.load"))
    if isa(as[4],Number)
        push!(s, string("(i32.add"))
        parseitem(s, cinfo, as[3], SSAid)
        push!(s, string("(i32.const ",4*as[4],"))"))
    else
        push!(s, string("(i32.add"))
        parseitem(s, cinfo, as[3], SSAid)
        push!(s, string("(i32.mul (i32.const 4)"))
        parseitem(s, cinfo, as[4], SSAid)
        push!(s, string("))"))
    end
    #push!(s, string(")"))
end

function ex_arrayset(s, cinfo, as, SSAid)
    #as= [GlobalRef, Bool=true, arrayname, value, idx]
    #                              3        4     5
    push!(s, string("f32.store"))
    if isa(as[5],Number)
        push!(s, string("(i32.add"))
        parseitem(s, cinfo, as[3], SSAid)
        push!(s, string("(i32.const ",4*as[5],"))"))
        parseitem(s, cinfo, as[4], SSAid)
        #ptr = string(" (i32.add (get_local \$",string(ex.args[2]),") (i32.const ",4*(ex.args[4]),"))")
    else
        push!(s, string("(i32.add"))
        parseitem(s, cinfo, as[3], SSAid)
        push!(s, string("(i32.mul (i32.const 4)"))
        parseitem(s, cinfo, as[5], SSAid)
        push!(s, string("))"))
        parseitem(s, cinfo, as[4], SSAid)
    end
    #push!(s, string(")"))
end