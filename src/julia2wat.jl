module julia2wat

using Core: CodeInfo, SlotNumber, SSAValue, IntrinsicFunction, MethodInstance, PhiNode, GotoNode
export @code_wat, compilewat, readwat

include("parser.jl")
include("ops.jl")
include("utils.jl")

end
