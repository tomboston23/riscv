OBJDUMP = riscv64-unknown-elf-objdump
RAM_ORIGIN = 0x80000000
PROGRAM_HOME := $(OUT_HOME)/program
ENTRY_INFO := $(PROGRAM_HOME)/entry.mk
-include $(ENTRY_INFO)
RUN_RESULT := $(shell ruby $(STEM)/run.rb)
VERILATOR := verilator
VERILATOR_ROOT := /usr/share/verilator
VERILATOR_DEFINES := -DOUT_HOME=\"$(OUT_HOME)\" -DRAM_ORIGIN=$(RAM_ORIGIN) -DELF_ENTRY=$(ELF_ENTRY)

MEM_RTL := $(shell find $(STEM)/src/memory/rtl -name "*.sv" -or -name "*.v")
MEM_SRC := $(MEM_RTL)
MEM_SRC += $(shell find $(STEM)/src/memory/sim -name "*.sv" -or -name "*.v")
MEM_OUT_DIR := $(OUT_HOME)/memory

HW_OUT_DIR := $(OUT_HOME)/hardware
HW_SIM=$(OUT_HOME)/hardware/basic-hw
HW_SRC := $(shell find $(STEM)/src/hardware/pkg -name "*.sv" -or -name "*.v")
HW_SRC += $(shell find $(STEM)/src/hardware/rtl -name "*.sv" -or -name "*.v")
HW_SRC += $(shell find $(STEM)/src/hardware/sim -name "*.sv" -or -name "*.v")
HW_SRC += $(MEM_RTL)

TESTCODE_INCLUDES := $(STEM)/test/test_files/_start/_start.s