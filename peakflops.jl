# peakflops often seems to cause a hang. What happens if we just try it a lot?

function wheee0()
    i = 0
    while true
        try
            if i == 0
                print(".")
            end
            i += 1
            peakflops(1954784290346684782)
        catch
        end
    end
end

function wheee1()
    i = 0
    while true
        try
            i += 1
            if i == 1
                print(".")
            end
            peakflops(1954784290346684782)
        catch
        end
    end
end

function mid_inc()
    i = 0
    try
        if i == 0
            print(".")
        end
        i += 1
        peakflops(1954784290346684782)
    catch
        print(i)
    end
end


function pre_inc()
    i = 0
    try
        i += 1
        if i == 1
            print(".")
        end
        peakflops(1954784290346684782)
    catch
        print(i)
    end
end


print(code_typed(wheee0, ()))
print(code_llvm(wheee0, ()))

print(code_typed(wheee1, ()))
print(code_llvm(wheee1, ()))


# mid_inc()
# pre_inc()

# wheee0()
