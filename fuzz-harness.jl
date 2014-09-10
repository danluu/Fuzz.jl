const input_dir = "jl_input"
const output_dir = "logs"

input_files = readdir(input_dir)

for input in input_files
    if success(`julia $input_dir/$input` .> "$output_dir/$input.log")
        print("ERROR: $input didn't fail\n")
    end
end
