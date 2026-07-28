OBJDUMP = riscv64-unknown-elf-objdump
RAM_ORIGIN = 0x80000000
TOHOST = 0xFFFF0000
PROGRAM_HOME := $(OUT_HOME)/program
ENTRY_INFO := $(PROGRAM_HOME)/entry.mk
RUN_RESULT := $(shell ruby $(STEM)/run.rb)
$(info RUN_RESULT: $(RUN_RESULT))

-include $(ENTRY_INFO)

ifndef TEST_FILE
	TEST_FILE = cp1.s
endif

clean:
	@rm -rf $(PROGRAM_HOME)

build: elf hex dis

elf:
	@mkdir -p $(PROGRAM_HOME)
	riscv64-unknown-elf-gcc \
		-march=rv32i \
		-mabi=ilp32 \
		-nostdlib \
		-I$(OUT_HOME)/features \
		-Wl,-defsym,RAM_ORIGIN=$(RAM_ORIGIN) \
		-T $(PROGRAM_HOME)/linker.ld \
		-o $(PROGRAM_HOME)/program.elf \
		$(STEM)/test/test_files/$(TEST_FILE)

bin:
	riscv64-unknown-elf-objcopy -O binary $(PROGRAM_HOME)/program.elf $(PROGRAM_HOME)/program.bin

hex: 
	@mkdir -p $(dir $@)
	python3 $(STEM)/test/parse_elf.py --elf_file $(PROGRAM_HOME)/program.elf --out_file $(PROGRAM_HOME)/program.hex --entry_file $(ENTRY_INFO)

dis: 
	$(OBJDUMP) -d $(PROGRAM_HOME)/program.elf > $(PROGRAM_HOME)/program.dis

VERILATOR := verilator
VERILATOR_ROOT := /usr/share/verilator
MEM_OUT_DIR := $(OUT_HOME)/memory
VERILATOR_DEFINES := -DOUT_HOME=\"$(OUT_HOME)\" -DRAM_ORIGIN=$(RAM_ORIGIN) -DELF_ENTRY=$(ELF_ENTRY)
MEM_SRC := $(shell find $(STEM)/src/memory -name "*.sv" -or -name "*.v")

clean-mem:
	@rm -rf $(MEM_OUT_DIR)

basic-mem: basic-compile-mem basic-run-mem

basic-run-mem:
	@mkdir -p $(MEM_OUT_DIR)/waves
	$(MEM_OUT_DIR)/basic-mem/Vmemory_simple_tb

basic-compile-mem:	
	@mkdir -p $(MEM_OUT_DIR)
	@mkdir -p $(MEM_OUT_DIR)/basic-mem
	$(VERILATOR) \
		--binary \
		--sv \
		--trace \
		--Mdir $(MEM_OUT_DIR)/basic-mem \
		-I$(OUT_HOME)/features \
		--top-module memory_simple_tb \
		$(VERILATOR_DEFINES) \
		$(MEM_SRC) \

HW_OUT_DIR := $(OUT_HOME)/hardware
HW_SIM=$(OUT_HOME)/hardware/basic-hw
HW_SRC := $(shell find $(STEM)/src/hardware/pkg -name "*.sv" -or -name "*.v")
HW_SRC += $(shell find $(STEM)/src/hardware/rtl -name "*.sv" -or -name "*.v")
HW_SRC += $(shell find $(STEM)/src/hardware/sim -name "*.sv" -or -name "*.v")
HW_SRC += $(shell find $(STEM)/src/memory/rtl -name "*.sv" -or -name "*.v")

clean-hw:
	@rm -rf $(HW_OUT_DIR)

basic-hw: build basic-compile-hw basic-run-hw 
# basic-hw builds hex file, compiles hw and ram rtl and runs cpu testbench 

basic-run-hw:
	@mkdir -p $(HW_OUT_DIR)/waves
	$(HW_OUT_DIR)/basic-hw/Vcpu_simple_tb

basic-compile-hw:	
	@mkdir -p $(HW_OUT_DIR)
	@mkdir -p $(HW_SIM)
	$(VERILATOR) \
		--binary \
		--timing \
		--sv \
		-DDEBUG \
		--trace \
		--timescale 1ns/1ps \
		--Mdir $(HW_SIM) \
		-I$(OUT_HOME)/features \
		--top-module cpu_simple_tb \
		$(VERILATOR_DEFINES) -DTB_DRIVE_CLOCKS=1 \
		$(HW_SRC)

gtk:
	gtkwave $(HW_OUT_DIR)/waves/cpu_simple.vcd 

spike-compile-hw:
	@mkdir -p $(HW_OUT_DIR)
	@mkdir -p $(HW_SIM)
	$(VERILATOR) \
		--cc \
		--timing \
		--sv \
		-DDEBUG \
		--trace \
		--timescale 1ns/1ps \
		--Mdir $(HW_SIM) \
		-I$(OUT_HOME)/features \
		--top-module cpu_simple_tb \
		$(VERILATOR_DEFINES) \
		$(HW_SRC) \
	&& make -C $(HW_SIM) -f Vcpu_simple_tb.mk

CXX=g++

SPIKE=/home/thboston/tools/riscv-isa-sim

CFLAGS=-std=c++20 \
       -iquote $(SPIKE)/riscv \
       -iquote $(SPIKE)/fesvr \
       -I/home/thboston/tools/ELFIO \
       -I$(OUT_HOME)/features \
       -I$(HW_SIM) \
       -I$(VERILATOR_ROOT)/include

LDFLAGS=-L$(SPIKE)/build \
        -Wl,-rpath,$(SPIKE)/build \
        -lriscv \
        -lfesvr \
        -lpthread \
        -ldl \
        $(HW_SIM)/Vcpu_simple_tb__ALL.o \
        $(HW_SIM)/verilated.o \
        $(HW_SIM)/verilated_threads.o \
        $(HW_SIM)/verilated_timing.o \
        $(HW_SIM)/verilated_vcd_c.o

.PHONY: spike

spike: build spike-compile-hw
	@mkdir -p $(PROGRAM_HOME)/run
	@touch $(PROGRAM_HOME)/run/program_run.log

	$(CXX) $(CFLAGS) \
	    $(STEM)/test/spike/spike.cpp \
	    -o $(PROGRAM_HOME)/spike_test \
	    $(LDFLAGS)

	$(PROGRAM_HOME)/spike_test \
	    $(PROGRAM_HOME)/program.elf \
	    $(PROGRAM_HOME)/run/program_run.log
