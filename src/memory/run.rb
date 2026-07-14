require_relative '../run'

env_check()
generate_feature_file()

def run_mem()
    system("make clean")
    system("make basic-mem")
end

run_mem()