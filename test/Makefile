OBJDUMP = riscv64-unknown-elf-objdump
RAM_ORIGIN = 0x80000000
TOHOST = 0xFFFF0000
STEM ?= $(abspath $(CURDIR)/..)
OUT_HOME ?= $(abspath $(CURDIR)/../out)
ENTRY_INFO := $(OUT_HOME)/program/entry.mk
RUN_RESULT := $(shell ruby $(STEM)/run.rb)

-include $(ENTRY_INFO)

ifndef TEST_FILE
	TEST_FILE = cp1.s
endif

clean:
	@rm -rf $(OUT_HOME)/program

build: elf hex dis

elf:
	@mkdir -p $(OUT_HOME)/program
	riscv64-unknown-elf-gcc \
		-march=rv32i \
		-mabi=ilp32 \
		-nostdlib \
		-I$(OUT_HOME)/features \
		-Wl,-defsym,RAM_ORIGIN=$(RAM_ORIGIN) \
		-T $(STEM)/test/linker.ld \
		-o $(OUT_HOME)/program/program.elf \
		$(STEM)/test/test_files/$(TEST_FILE)

bin:
	riscv64-unknown-elf-objcopy -O binary $(OUT_HOME)/program/program.elf $(OUT_HOME)/program/program.bin

hex: 
	@mkdir -p $(dir $@)
	python3 $(STEM)/test/parse_elf.py --elf_file $(OUT_HOME)/program/program.elf --out_file $(OUT_HOME)/program/program.hex --entry_file $(ENTRY_INFO)

dis: 
	$(OBJDUMP) -d $(OUT_HOME)/program/program.elf > $(OUT_HOME)/program/program.dis

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
HW_SRC := $(shell find $(STEM)/src/hardware -name "*.sv" -or -name "*.v")
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
		--cc \
		--timing  \
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

spike:
	@mkdir -p $(OUT_HOME)/program
	@mkdir -p $(OUT_HOME)/program/run
	@touch $(OUT_HOME)/program/run/program_run.log

	$(CXX) $(CFLAGS) \
	    $(STEM)/test/spike/main.cpp \
	    -o $(OUT_HOME)/program/spike_test \
	    $(LDFLAGS)

	$(OUT_HOME)/program/spike_test \
	    $(OUT_HOME)/program/program.elf \
	    $(OUT_HOME)/program/run/program_run.log
