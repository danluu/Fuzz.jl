function err_result(s::String)
    beginswith(s, "# CAUGHT:")
end

function canonicalize_path(s::String)
    # check istext to work around issue with bad strings.
    if istext(s)
        println("canon-debug")
        print(s)
        s = replace(s, r"/Users/danluu","")
        println("canon-debug2")
        print(s)
        s = replace(s, r"/home/dluu","")
    else
    end
    s
end

function check_logs(fname1::String, fname2::String)
    f1 = open(fname1)
    f2 = open(fname2)
    line1 = readline(f1)
    line2 = readline(f2)
    i = 0
    while line1 != ""  && line2 != ""
        i += 1
        line1 = canonicalize_path(line1)
        line2 = canonicalize_path(line2)
    	if err_result(line1) || err_result(line2)
            # maybe do something here.
        elseif line1 != line2
            print("MISMATCH $i\n$line1 $line2")
        end
        line1 = readline(f1)
        line2 = readline(f2)
    end
end

check_logs("linux-arm32", "linux-x64")
