component :features do 
    feature "f_magic_memory",                   1
    feature "f_init_file",                      ENV['OUT_HOME'] + "/program/program.hex"
    feature "f_riscv_exit_inst_present",        1
    feature "f_riscv_exit_inst",                0xf0002013
end