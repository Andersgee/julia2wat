readwat(name) = println(open(f->read(f, String), string(name,".wat")))

function compilewat(name)
    cmd = string("./wasm.sh ",name,".wat ",name,".wasm -O4")
    run(`sh -c $cmd`)

    #readwat(name)
    println("INFO: saved binaryen optimized ",name,".wasm")
    println("(also translated back and overwritten ",name,".wat)")
    return nothing
end

function savewat(moduletext, name)
    wattext = join(["(module \$", name, "\n", JSimports(), join(moduletext), "\n)"])
    open(string(name,".wat"), "w") do io
        for t in wattext
            write(io, t)
        end
    end
    println("INFO: saved ",name,".wat")
    return nothing
end