const test_dir = "jl_input"

# Note that it takes a really long time for julia
# to construct a huge string. Seems like a super
# low priority performance bug to debug someday.
function generate_tests(n::Int, string::Bool)
    for i in 1:n
        len = 2^i
        f = open("$(test_dir)/$(i)","w")
        if string
            write(f,"\"")
        end
        write(f, randstring(len))
        if string
            write(f,"\"")
        end
        close(f)
    end
end

# generate_tests(20, false)

# find shorter PCRE bug.
# This turned out to be a bug in pcregrep and not pcre itself.
function pcregrep_fail_check()
    prefix_len = rand(0:8000000)
    postfix_len = rand(0:80)
    text = "not defined"
    regex = r"not defined"
    dut = string(randstring(prefix_len),text,randstring(postfix_len))
    if !ismatch(regex, dut)
        print("ERROR: $dut")
    end
end

# inspried by the above. Seems ok.
function randstring_len_test()
    n = rand(0:2^28)
    s = randstring(n)
    if !(length(s) == n)
        print("ERROR: $n $s\n")
    end
end

# while true
#     pcregrep_fail_check()
#     randstring_len_test()
# end

function shrink_UTFstr_bug()
    wat = '䏏'
    print(wat)

    f = open("log", "w")
    write(f, wat)
    flush(f)
    close(f)
end

shrink_UTFstr_bug()
