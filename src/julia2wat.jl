module julia2wat

using Core: CodeInfo, SlotNumber, SSAValue, IntrinsicFunction, MethodInstance, PhiNode, GotoNode
export @code_wat, compilewat

include("parser.jl")
include("ops.jl")

end
