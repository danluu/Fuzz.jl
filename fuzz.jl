const max_rand_string_len = 100

# Filter types returned by names that we can't call.
# TODO: add some way to call non-generic fns.
function checkable_name(name)
    typeof(eval(name)) == Function && isgeneric(eval(name))
    # it should be possible to add support for 'DataType'
end

# get list of functions to avoid calling.
# includes things that create files, allocate memory, etc.
# TODO: run in a sandbox and allow calls to those fns.
function get_fn_exclusion_list(fname)
    banned = Set{Symbol}()
    f = open(fname)
    line = chomp(readline(f))
    while line != ""
        stripped = replace(line, r"\s*#.*", "") # remove comments.
        push!(banned, symbol(stripped))
        line = chomp(readline(f))
    end
    close(f)
    return banned
end

# MethodTable doesn't provide any means of indexing.
# Iterate through methods and pick one at random.
function get_rand_method(mt::MethodTable)
    some_method = start(mt)
    n = rand(1:length(mt))
    for i in 2:n
        some_method = some_method.next
    end
    return some_method
end

# Given a name, get a random function with args (as string).
function gen_rand_fn(name)
    # println("gen_rand_fn $name")
    # Note that this won't work for functions that take no args. That seems ok since those 
    # are unlikely to crash julia or hang.
    args = ""
    methods_of_name = methods(eval(name))

    some_sig = get_rand_method(methods_of_name).sig
    args = generate_rand_data(some_sig)
    if args != ""
        return("$name($args) #$some_sig\n")
    else
        return ""
    end
end

# generate and call a random function with eval(parse(_))
function call_rand_fn(fn_log, banned_fns::Set{Symbol})
    potential_names = sort(names(Base)) # names are returned in a random order.
    potential_names = filter(checkable_name, potential_names)
    potential_names = filter(x -> !in(x, banned_fns), potential_names)
    fn_text = ""
    while fn_text == ""
        name = potential_names[rand(1:end)]
        fn_text = gen_rand_fn(name)
    end
    write(fn_log, "$fn_text")
    flush(fn_log)
    res = eval(parse(fn_text))
    write(fn_log, "# $res\n")
    flush(fn_log)
end

# Generate a random float
# TODO: generate more denorms and interesting numbers.
function rand_float(t)
    if t == Float64
        return string(reinterpret(Float64, rand(Uint64)))
    elseif t == Float32
        return string(reinterpret(Float32, rand(Uint32)))
    elseif t == Float16
        return string(reinterpret(Float16, rand(Uint16)))
    else
        throw(ErrorException("Bad float type"))
    end
    assert(false)
end

function rand_char_raw()
    if rand(0:1) == 0
        return char(rand(Uint8))
    elseif rand(0:1) == 0
        return char(rand(Uint16))
    else
        return char(rand(Uint32))
    end
    assert(false)
end

function rand_char()
    return string("'",rand_char_raw(),"'") 
end

function rand_string_raw(n::Integer)
    len = rand(1:n)
    if rand(0:1) == 0
        return randstring(rand(1:len))
    else         
        arr = Array(Char, len)
        for i in 1:len
            arr[i] = rand_char_raw()
        end
        return join(arr)
    end
    assert(false)
end

function rand_string(n::Integer)
    return string("\"",rand_string_raw(n),"\"")
end

# Walk down tree until we get to a concrete type.
function get_concrete_type(t::DataType)
    # println("get_concrete_type $t")
    if length(subtypes(t)) == 0
        return t
    elseif length(subtypes(t)) == 1 && subtypes(t)[1] == t # some types are cyclic.
        return t
    else 
        return get_concrete_type(subtypes(t)[rand(1:end)])
    end
end

# Given a type, produce an appropriate string of random data.
function generate_rand_data(t::DataType)
    # println("generate_rand_data $t")
    # First, try to generate data based on the type.
    # If we can't and it's an abstract type, pick a random concrete type and try again.
    if t == String
        return rand_string(max_rand_string_len)
    elseif t == Char
        return rand_char()
    elseif t == Symbol
        return  string(symbol(rand_string(max_rand_string_len)))
    elseif t == Int # Try to stop 32/64-bit rand divergence
        return string(rand(Int64))
    elseif t == Uint128 || t == Uint64 || t == Uint32 || t == Uint16 || t == Uint8 ||
        t == Int128 || t == Int64 || t == Int32 || t == Int16 || t == Int8
        return string(rand(t))
    elseif t == Float16 || t == Float32 || t == Float64
        return rand_float(t)
    elseif t == Integer        
        return string(rand(Int128))        
    elseif t == Unsigned
        return string(rand(Uint128))
    elseif t == Signed
        return string(rand(Int128))
    elseif t == BigInt
        return string("big(",rand(Int128),")")
    elseif t == BigFloat
        return string("big(",rand(Float64),")")
    elseif t == Bool
        return string(rand(0:1) == 0)
    elseif t == Float32
        return string(rand(Float32))
    elseif t == Number || t == FloatingPoint
        return string(rand(Float64))
    elseif t == Function
        return "x -> x" # TODO: generate a random function
    # issue #8570
    # elseif t == IntSet
    #     # TODO: randomize array
    #     numbers = Array(Int, rand(1:16), 1)
    #     num_str = join(numbers, ",")
    #     return "IntSet($num_str)"
    elseif t == Regex
        regex_str = rand_string(max_rand_string_len)
        return "r\"$regex_str\""
    end

    if length(subtypes(t)) > 0 && !(length(subtypes(t)) == 1 && subtypes(t)[1] == t)
        return generate_rand_data(get_concrete_type(t))
    else        
        # print("# Don't know how to generate $t\n")
        return ""
    end
    assert(false)
end

# Given a tuple, produce a string of rand data for each type in the tuple.
function generate_rand_data(sig::Tuple)
    can_generate = true
    args = ""
    for t in sig        
        if typeof(t) == DataType
            randarg = generate_rand_data(t)
            if randarg != ""
                args = "$args$randarg,"
            else
                return ""
            end
        else
            # Likely a union type, which should be handled
            # by picking one of its types.
            return ""
        end
    end
        
    if can_generate
        # delete trailing comma.    
        return args[1:end-1]
    else
        return ""
    end
end

# Helper function to try to track down non-deterministic bug with `displayable`
function bogus_displayable(fn_log)
    text = gen_rand_fn(:displayable)
    write(fn_log, text)
    flush(fn_log)
    eval(parse(text))
end

# Call random fns in try/catch.
# There is a bug with try/catch that will cause this to randomly fail
# and let exceptions inside the try kill the script.
function try_fns(banned_fns::Set{Symbol})
    i = 0
    fn_log = open("log","w")
#    (err_in, err_out) = redirect_stderr()
#    close(err_out)
    while true
        i += 1
#        i > 10000 && exit()
        try
            # try to catch unreproducible displayable bug more quickly
            # calling displayable by itself isn't sufficient.
            if (rand(1:100) == 1)
                bogus_displayable(fn_log)
            else
                call_rand_fn(fn_log, banned_fns)
            end
        catch err
            if is(err, ErrorException)
                exit()
            else
                write(fn_log, string("# CAUGHT: ", err,"\n"))
            end
        end
    end
    close(fn_log)
end

# We often get a hang when we call displayable after someting has happened.
# Is displayable alone sufficient or do we need something else first?
# A single call is never sufficient, but maybe we can build up some funny 
# state with a lot of calls?
function try_displayable()
    srand(1)
    fn_log = open("log","w")
    while true
        try
            text = gen_rand_fn(:displayable)
            write(fn_log, text)
            flush(fn_log)
            eval(parse(text))
        catch
        end
    end
    close(fn_log)
end

# Generate a file with random characters.
const test_dir = "jl_input"
function generate_rand_strings(n::Int64)
    for i in 1:n
        len = rand(1:2^18)
        f = open("$(test_dir)/$(i)","w")
#        write(f, randstring(len))
        write(f, rand_string_raw(len))
        close(f)
    end
end

# top level function.
function fuzz_fns(args)
    srand(int(args[1])) # rand seed is arg
    banned_fns = get_fn_exclusion_list("../../banned.txt")
    try_fns(banned_fns)
end

# generate_rand_strings(20)
fuzz_fns(ARGS)
# try_displayable()
