macro code_wat(ex,name="")
	#code_wat(function, types.(args))
	#code_wat(weather.solartime, Tuple{Float64, Float64, Float64, Float64})
	:(code_wat($(esc(ex.args[1])), Base.typesof($(esc.(ex.args[2:end])...)),$name))
end

function exA2functext(ex, A; doexport=true)
	cinfo, R = code_typed(ex, A, optimize=true)[1]
	#dump(cinfo.code) #debug
	SSA=[]
    for item in cinfo.code
        s=[]
        parseitem(s,cinfo, item)
        push!(SSA,s)
    end
    
    #inlinephivalues(SSA) #debug

    functext = join(["\n",functiondeclaration(cinfo, A, R, doexport), "\n",inlinessa(SSA),"\n)\n"])
    return functext
end

moduletext = [];

function code_wat(ex, A, name="")
	println("DEBUGINFO: ex=",ex, " A=",A)
	println()
	global moduletext	
	moduletext = [];	 
	push!(moduletext, exA2functext(ex, A))


    if (name != "")
        open(string(name,".wat"), "w") do io
            write(io, "(module \$",name,"\n")
            write(io, JSimports())
            for t in moduletext
            	write(io, t)
            end
            write(io, "\n)")
        end
        println("\nINFO: saved ",name,".wat")
        return
    else
        println.(moduletext)
        return
    end
end

parseitem(s,cinfo, item, head=:(call)) = isa(item, Expr) ? parseexpr(s,cinfo, item) : parsearg(s,cinfo, item, head)
parseitems(s, cinfo, items, head=:(call)) = parseitem.((s,), (cinfo,), items, (head,))

function parseexpr(s,cinfo, e)
    #some special ops for entire expressions go here
    if (e.head == :(invoke) && isa(e.args[1],MethodInstance) && e.args[1].def.name == :(println))
        ex_println(s, cinfo, e.args)
    elseif (isa(e.args[1],GlobalRef) && e.args[1].name == :(ifelse))
        ex_ifelse(s, cinfo, e.args)
    elseif (isa(e.args[1],GlobalRef) && e.args[1].name == :(arrayref))
        ex_arrayref(s, cinfo, e.args)
    elseif (isa(e.args[1],GlobalRef) && e.args[1].name == :(arrayset))
        ex_arrayset(s, cinfo, e.args)
    elseif (isa(e.args[1],GlobalRef) && e.args[1].name == :(tuple)) && e.args[2][1:7] == "declare"
        ex_llvm(s,cinfo, e.args)
    #elseif (e.head == :(gotoifnot))
    #	ex_gotoifnot(s,cinfo, e.args)
    else
        parseitems(s,cinfo, e.args, e.head)
    end
end

function parsearg(s,cinfo, a, head=:(call))
	if isa(a,SSAValue)
        push!(s,a)
    elseif isa(a,SlotNumber)
        op_get(s,cinfo,a)
    elseif isa(a,GlobalRef)
    	if (a.name in keys(op))
    		push!(s,op[a.name])
    	else
    		println("DEBUGINFO: ",head," GlobalRef ", a) #getfield(a, :(mod)) ,getfield(a, :(name))
    	end
	elseif isa(a,Number)
        op_number(s,cinfo,a)
    
    #elseif isa(a,String)
    #    push!(s,a) #need way more shenanigans for this to work in wasm
    
    elseif isa(a,MethodInstance)
        def = a.def
        method_specialized_signature = getfield(getfield(def, :(specializations)), :(sig))
        argtypes = getfield(method_specialized_signature,3)[2:end] #argtypes
		
        fname = getfield(def, :(name))
        if (fname in keys(op))
	    	#already dealt with
        #elseif !(fname in keys(op))
    	else
    		m = getfield(def, Symbol("module"))

    		if (string(m) == "Base")
    			println("DEBUGINFO: ", head," IGNORING MethodInstance ",a)
    		else
	    		println("DEBUGINFO: ", head," MethodInstance ",a)
		        ex = getfield(getfield(def, Symbol("module")), fname) #function name as a real reference rather than string or some such
		        A = Tuple{argtypes...}
		        println("DEBUGINFO: ex=",ex, " A=",A)
	        	push!(s, string("call \$",fname))
	        	global moduletext
	        	push!(moduletext, exA2functext(ex, A))
        	end
		end

    elseif isa(a,Symbol)
        #push!(s,head," Symbol ",a)
        println("DEBUGINFO: ",head," Symbol ",a)
    elseif isa(a,IntrinsicFunction)
        println("DEBUGINFO: ",head," IntrinsicFunction ",a)
    elseif isa(a,Type)
    	#not ever needed?
        #println("DEBUGINFO: ",head, " Type ",a)
    #=
    elseif isa(a,PhiNode)
    	println("DEBUGINFO: ",head," PhiNode.edges ",a.edges)
    	println("DEBUGINFO: ",head," PhiNode.values ",a.values)
    	push!(s, a)
    	#push!(s, "(local \$tmp i32)") #tmp=cinfo.slotnames[i] ..somehow
    elseif isa(a,GotoNode)
    	println("DEBUGINFO: ",head," GotoNode ",a)
    	push!(s, "goto",a.label)
    =#
	else
		println("DEBUGINFO: ",head," ELSE_ARG ",a)
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
            println("WARNING! this function is type unstable. meaning the wat code might not be correct")
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

function inlinephivalues(SSA)
	#copy paste from SSA
	used=[]
    for i=1:length(SSA), j=1:length(SSA[i])
        if isa(SSA[i][j],PhiNode)
        	SSA[i][j] = Dict(SSA[i][j].edges .=> SSA[i][j].values) #PhiDict instead of PhiNode
        	
            for k in keys(SSA[i][j])
            	if isa(SSA[i][j][k],SSAValue)
            		push!(used, SSA[i][j][k].id)
            		SSA[i][j][k] = SSA[SSA[i][j][k].id]
            	elseif isa(SSA[i][j][k],Number)
            		SSA[i][j][k] = string("(local tmp f32) (local.set tmp f32.const ",SSA[i][j][k],")")
            	end
            end
        end
    end

    for i=1:length(SSA)
        if (i in used)
            SSA[i] = ""
        end
    end

end

function inlinessa(SSA)
    println("SSA:")
    for i=1:length(SSA)
    	println("%",i,": ",join(string.(SSA[i])," "))
    end

    used=[]

    #add parenthesis
    for i=1:length(SSA)
    	if length(SSA[i]) > 1
    		SSA[i] = vcat("(",SSA[i],")")
    	end
    end

    #copy paste from SSA
    for i=1:length(SSA), j=1:length(SSA[i])
        if isa(SSA[i][j],SSAValue)
            c = SSA[i][j].id
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

    #=
    #quality of life would be insert newline when brackets match..
    funcbody = string(join(join.(SSA)))
    body = funcbody[1:end]

    ob=0 #open brackets
    ib=0 #inserted brackets
    tabs=0
    for i=1:length(funcbody)
    	t=funcbody[i]
    	if (t=='(')
    		ob+=1
    		body = pushat(body,'\n',i+ib-1)
    		ib+=1
    		tabs+=1
    		body = pushat(body,repeat(" ",tabs),i+ib)
    		ib+=tabs
    	elseif (t==')')
    		ob-=1
    	end
    	
    	if (ob==0 && t==')')
    		tabs-=1
    		body = pushat(body,'\n',i+ib)
    		ib+=1
    	end
    end
    return body
    =#
end

pushat(v,c,i) = join([v[1:i],c,v[i+1:end]])

printwat(name) = println(open(f->read(f, String), string(name,".wat")))

function compilewat(name; optimize=true)
    if optimize
        cmd = string("./wasm.sh ",name,".wat ",name,".wasm -O4")
    else
        cmd = string("./wasm.sh ",name,".wat ",name,".wasm")
    end
    run(`sh -c $cmd`)


    printwat(name)
    println("\nINFO: saved ",name,".wat")
    println("INFO: saved ",name,".wasm")
    return nothing
end
