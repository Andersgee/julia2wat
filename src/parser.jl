macro code_wat(ex, name)
	:(code_wat($(esc(ex.args[1])), Base.typesof($(esc.(ex.args[2:end])...)), $name))
end

function phi2dict(cinfo, firstslotnum)
    d=Dict()
    slotnum = firstslotnum
    for SSAid=1:length(cinfo.code)
        if isa(cinfo.code[SSAid],PhiNode)
            pn = cinfo.code[SSAid]
            k = Dict(pn.edges .=> pn.values)
            k[0] = string("\$",string(cinfo.slotnames[slotnum]))
            d[SSAid] = k
            println(d)
            slotnum+=1;
        end
    end
    return d
end

function exA2functext(ex, A; doexport=true)
	#cinfo, R = code_typed(ex, A, optimize=true)[1]
    

    cinfo, R = code_typed(ex, A, optimize=true)[1]
	#dump(cinfo.code) #debug

    global phidict = Dict()
    phidict = phi2dict(cinfo, length(getfield(A,3))+2)

	SSA=[]
    for SSAid=1:length(cinfo.code)
        s=[]
        parseitem(s,cinfo, cinfo.code[SSAid], SSAid)
        push!(SSA,s)
    end
    functext = join(["\n",functiondeclaration(cinfo, A, R, doexport), "\n",inlinessa(SSA),"\n)\n"])
    return functext
end

moduletext = [];
phidict = Dict()
function code_wat(ex, A, name)

    resetinfo()
	info("DEBUGINFO: ex=",ex, " A=",A)
	global moduletext	
	moduletext = [];
	push!(moduletext, exA2functext(ex, A))
    savewat(moduletext, name)
end

parseitem(s,cinfo, item, SSAid, head=:(call)) = isa(item, Expr) ? parseexpr(s,cinfo, item, SSAid) : parsearg(s,cinfo, item, SSAid, head)
parseitems(s, cinfo, items, SSAid, head=:(call)) = parseitem.((s,), (cinfo,), items, (SSAid,), (head,))

function parseexpr(s,cinfo, e, SSAid)
    #some special ops for entire expressions go here
    if (e.head == :(invoke) && isa(e.args[1],MethodInstance) && e.args[1].def.name == :(info))
        ex_println(s, cinfo, e.args, SSAid)
    elseif (isa(e.args[1],GlobalRef) && e.args[1].name == :(ifelse))
        ex_ifelse(s, cinfo, e.args, SSAid)
    elseif (isa(e.args[1],GlobalRef) && e.args[1].name == :(arrayref))
        ex_arrayref(s, cinfo, e.args, SSAid)
    elseif (isa(e.args[1],GlobalRef) && e.args[1].name == :(arrayset))
        ex_arrayset(s, cinfo, e.args, SSAid)
    elseif (isa(e.args[1],GlobalRef) && e.args[1].name == :(tuple)) && e.args[2][1:7] == "declare"
        ex_llvm(s,cinfo, e.args, SSAid)
    elseif (e.head == :(gotoifnot)) #conditional branch, aka continue aka br_if but.. br_if egzero(condition) instead of gotoif condition ?
    	ex_gotoifnot(s,cinfo, e.args, SSAid)
    #elseif e.head == :(=) #assignment in the IR
    #   local.set ? 
    else
        parseitems(s,cinfo, e.args, SSAid, e.head)
    end
end

function parsearg(s,cinfo, a, SSAid, head=:(call))
	if isa(a,SSAValue)
        if isa(cinfo.code[a.id], PhiNode)
            target = a.id
            global phidict
            locallabel = phidict[target][0]
            push!(s, "(local.get ",locallabel,")")
            #pn = cinfo.code[a.id]; #phinode
            #d = Dict(pn.edges .=> pn.values) #phinode dict
            
        else
            push!(s,a)
        end
    elseif isa(a,SlotNumber)
        op_get(s, cinfo, a)
    elseif isa(a,GlobalRef)
    	if (a.name in keys(op))
    		push!(s,op[a.name])
    	else
    		info("DEBUGINFO: ",head," GlobalRef ", a) #getfield(a, :(mod)) ,getfield(a, :(name))
    	end
	elseif isa(a,Number)
        op_number(s,cinfo,a)
    elseif isa(a,Type)
        info("DEBUGINFO: ",head, " Type ",a)
    elseif isa(a,MethodInstance)
        def = a.def
        fname = getfield(def, :(name))
        if (fname in keys(op))
	    	#already dealt with
    	else
    		method_specialized_signature = getfield(getfield(def, :(specializations)), :(sig))
        	argtypes = getfield(method_specialized_signature,3)[2:end] #argtypes
    		m = getfield(def, Symbol("module"))

    		if (string(m) == "Base")
    			info("DEBUGINFO: ", head," IGNORING MethodInstance ",a)
    		else
	    		info("DEBUGINFO: ", head," MethodInstance ",a)
		        ex = getfield(getfield(def, Symbol("module")), fname) #function name as a real reference rather than string or some such
		        A = Tuple{argtypes...}
		        info("DEBUGINFO: ex=",ex, " A=",A)
	        	push!(s, string("call \$",fname))
	        	global moduletext
	        	push!(moduletext, exA2functext(ex, A))
        	end
		end

    elseif isa(a,Symbol)
        #push!(s,head," Symbol ",a)
        info("DEBUGINFO: ",head," Symbol ",a)
    elseif isa(a,IntrinsicFunction)
        info("DEBUGINFO: ",head," IntrinsicFunction ",a)
    elseif isa(a,GotoNode)
        push!(s, "(br 0)))") #aka continue loop
    elseif isa(a,PhiNode)
        info("DEBUGINFO: ",head," PhiNode.edges ",a.edges)
        info("DEBUGINFO: ",head," PhiNode.values ",a.values)
        global phidict
        println("ISA PHINODE:")
        println(phidict)
        locallabel = phidict[SSAid][0]
        push!(s, string("(local ",locallabel," ",type2str(cinfo.ssavaluetypes[SSAid]),") (local.set ",locallabel,")"))
        #prepend!(s, [join(["(local ",locallabel," ",type2str(cinfo.ssavaluetypes[SSAid]),")"])])
        #push!(s, string(" (local.set ",locallabel,")"))
    elseif isa(a,PiNode)
        op_number(s,cinfo,a.val)
    #elseif isa(a,String)
        #push!(s,a) #need way more shenanigans for this to work in wasm
    #=
    elseif isa(a,PhiNode)
    	info("DEBUGINFO: ",head," PhiNode.edges ",a.edges)
    	info("DEBUGINFO: ",head," PhiNode.values ",a.values)
    	push!(s, a)
    	#push!(s, "(local \$tmp i32)") #tmp=cinfo.slotnames[i] ..somehow
    elseif isa(a,GotoNode)
    	info("DEBUGINFO: ",head," GotoNode ",a)
    	push!(s, "goto",a.label)
        push!(s, "(br 0)))")

    elseif isa(a,QuoteNode)
        push!(s, eval(a) #quotenode holds arbitrary value as reference instead of value (such as symbols)
    elsied isa(a,GotoNode)
        push!(s, "br") #unconditional branch, this needs to be an end parenthesis for loop, and make sure that 
        #a.label targets a block..
    =#

	else
		info("DEBUGINFO: ",head," ELSE_ARG ",a)
	end
end


function functiondeclaration(cinfo, A, R, doexport=false, opt=true)
    s=[]
    paramtypes = getfield(A,3)
    funcname = string(cinfo.linetable[1].method)
    push!(s, string("(func \$",funcname))

    if (doexport)
        push!(s, string(" (export \"",funcname,"\")"))
    end

    for i=1:length(paramtypes)
        if paramtypes[i] <: AbstractFloat
            push!(s, string(" (param \$",cinfo.slotnames[i+1]," f32)"))
        else
            push!(s, string(" (param \$",cinfo.slotnames[i+1]," i32)"))
        end
    end
    
    if string(R) != "Nothing"
        if R <: Integer
            push!(s, string(" (result i32)"))
        elseif R <: AbstractFloat
            push!(s, string(" (result f32)"))
        elseif R <: Any
            info("WARNING! this function is type unstable. meaning the wat code might not be correct")
            push!(s, string(" (result f32)"))
        end
    end

    #declare locals?
    if opt==false
        for i=length(paramtypes)+1:length(cinfo.slotnames)-1
            if cinfo.slottypes[i+1] <: AbstractFloat
                push!(s, string("\n (local \$",cinfo.slotnames[i+1]," f32) "))
            else
                push!(s, string("\n (local \$",cinfo.slotnames[i+1]," i32) "))
            end
        end
    end
    
    return join(s)
end

function printSSA(SSA)
    info("SSA:")
    for i=1:length(SSA)
        info("%",i,": ",join(string.(SSA[i])," "))
    end
end

function inlinessa(SSA)
    

    used=[]

    #add parenthesis
    for i=1:length(SSA)
    	if length(SSA[i]) > 1
    		SSA[i] = vcat("(",SSA[i],")")
    	end
    end

    printSSA(SSA)

    #copy paste from SSA
    for i=1:length(SSA), j=1:length(SSA[i])
        if isa(SSA[i][j],SSAValue)
            c = SSA[i][j].id
            if (isa(SSA[c],PhiNode)) && (SSAValue(i) in SSA[c].values)
                locallabel = phidict[c][0]
                prepend!(SSA[i], ["local.set ",locallabel," ("])
                push!(SSA[i], ")")
            end

            SSA[i][j] = join(SSA[c])
            push!(used, c)
            
        end
    end

    #delete used SSA (do after so copy paste can work multiple times)
    for i=1:length(SSA)
        if (i in used)
            SSA[i] = ""
        end
    end

    return join(join.(SSA))
end
