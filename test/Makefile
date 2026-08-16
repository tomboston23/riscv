include common.mk

$(info RUN_RESULT: $(RUN_RESULT))

ifndef TEST_FILE
	TEST_FILE = cp1.s
endif

clean:
	@rm -rf $(PROGRAM_HOME)

build: elf hex dis

elf:
	@mkdir -p $(PROGRAM_HOME)
	@mkdir -p $(PROGRAM_HOME)/logs
	@riscv64-unknown-elf-gcc \
		-march=rv32im_zicsr \
		-mabi=ilp32 \
		-nostdlib \
		-I$(OUT_HOME)/features \
		$(FW_INCLUDES) \
		-Wl,-defsym,RAM_ORIGIN=$(RAM_ORIGIN) \
		-T $(PROGRAM_HOME)/linker.ld \
		-o $(PROGRAM_HOME)/program.elf \
		$(STEM)/test/test_files/$(TEST_FILE) \
		$(TESTCODE_INCLUDES) \
		> $(PROGRAM_HOME)/logs/program_compile.log 2>&1
	@echo "ELF compilation completed successfully."

hex: 
	@mkdir -p $(dir $@)
	@python3 $(STEM)/test/parse_elf.py --elf_file $(PROGRAM_HOME)/program.elf --out_file $(PROGRAM_HOME)/program.hex --entry_file $(ENTRY_INFO)
	@echo "Hex file generation completed successfully."

dis: 
	@$(OBJDUMP) -d $(PROGRAM_HOME)/program.elf > $(PROGRAM_HOME)/program.dis
	@echo "Disassembly generation completed successfully."

mem:
	@make -f memory/Makefile mem

hw: build
	@make -f hardware/Makefile hw

spike: build
	@make -f hardware/Makefile spike
