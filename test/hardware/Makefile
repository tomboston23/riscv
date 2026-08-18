include $(STEM)/test/common.mk

hw: basic-hw

clean-hw:
	@rm -rf $(HW_OUT_DIR)

basic-hw: basic-compile-hw basic-run-hw 
# compiles hw and ram rtl and runs cpu testbench 

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
	GDK_DPI_SCALE=1.5 gtkwave $(HW_OUT_DIR)/waves/cpu_simple.vcd 

spike-compile-hw:
	@mkdir -p $(HW_OUT_DIR)
	@mkdir -p $(HW_SIM)
	@mkdir -p $(PROGRAM_HOME)/logs
	@mkdir -p $(HW_OUT_DIR)/logs
	@$(VERILATOR) \
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
		> $(PROGRAM_HOME)/logs/spike_compile.log 2>&1
	@make -C $(HW_SIM) -f Vcpu_simple_tb.mk \
		> $(HW_OUT_DIR)/logs/Vcpu_simple_tb.log 2>&1
	@echo "Verilator compilation completed successfully."

verilator-compile-hw:
	@mkdir -p $(HW_OUT_DIR)
	@mkdir -p $(HW_SIM)
	@mkdir -p $(PROGRAM_HOME)/logs
	@mkdir -p $(HW_OUT_DIR)/logs
	@$(VERILATOR) \
		--cc \
		--timing \
		--sv \
		-DDEBUG \
		--trace \
		--timescale 1ns/1ps \
		--Mdir $(HW_SIM) \
		-I$(OUT_HOME)/features \
		--top-module cpu_simple_tb \
		$(VERILATOR_DEFINES) -DTB_PRINT_DUMP=1 \
		$(HW_SRC) \
		> $(PROGRAM_HOME)/logs/verilator_compile.log 2>&1
	@make -C $(HW_SIM) -f Vcpu_simple_tb.mk \
		> $(HW_OUT_DIR)/logs/Vcpu_simple_tb.log 2>&1
	@echo "Verilator compilation completed successfully."

CXX=g++

SPIKE=/home/thboston/tools/riscv-isa-sim

CFLAGS=-std=c++20 \
       -iquote $(SPIKE)/riscv \
       -iquote $(SPIKE)/fesvr \
       -I/home/thboston/tools/ELFIO \
       -I$(OUT_HOME)/features \
       -I$(HW_SIM) \
       -I$(VERILATOR_ROOT)/include

VERILATOR_LDFLAGS= $(HW_SIM)/Vcpu_simple_tb__ALL.o \
        $(HW_SIM)/verilated.o \
        $(HW_SIM)/verilated_threads.o \
        $(HW_SIM)/verilated_timing.o \
        $(HW_SIM)/verilated_vcd_c.o

SPIKE_LDFLAGS=-L$(SPIKE)/build \
        -Wl,-rpath,$(SPIKE)/build \
        -lriscv \
        -lfesvr \
        -lpthread \
        -ldl \
        $(VERILATOR_LDFLAGS)

SIM_DIR = $(STEM)/test/sim
SIM_SRC := $(wildcard $(SIM_DIR)/*.cpp)
SIM_INCLUDES := -I$(SIM_DIR)

SPIKE_SRC := $(wildcard $(SIM_DIR)/spike/*.cpp)
VERILATOR_SRC := $(wildcard $(SIM_DIR)/verilator/*.cpp)

SPIKE_SRC += $(SIM_SRC)
VERILATOR_SRC += $(SIM_SRC)

.PHONY: spike verilator

spike: spike-compile-hw
	@mkdir -p $(PROGRAM_HOME)/run
	@touch $(PROGRAM_HOME)/run/program_run.log
	@touch $(PROGRAM_HOME)/run/print_dump.log

	@$(CXX) $(CFLAGS) \
	    $(SPIKE_SRC) \
		$(SIM_INCLUDES) \
	    -o $(PROGRAM_HOME)/spike_test \
	    $(SPIKE_LDFLAGS)

	@$(PROGRAM_HOME)/spike_test \
	    $(PROGRAM_HOME)/program.elf \
	    $(PROGRAM_HOME)/run/program_run.log \
		$(PROGRAM_HOME)/run/print_dump.log 
	
	@echo "Spike simulation completed successfully."

verilator: verilator-compile-hw
	@mkdir -p $(PROGRAM_HOME)/run
	@touch $(PROGRAM_HOME)/run/program_run.log
	@touch $(PROGRAM_HOME)/run/print_dump.log

	@$(CXX) $(CFLAGS) \
	    $(VERILATOR_SRC) \
		$(SIM_INCLUDES) \
	    -o $(PROGRAM_HOME)/verilator_test \
		$(VERILATOR_LDFLAGS)

	@$(PROGRAM_HOME)/verilator_test \
	    $(PROGRAM_HOME)/program.elf \
	    $(PROGRAM_HOME)/run/program_run.log \
		$(PROGRAM_HOME)/run/print_dump.log 
	
	@echo "Verilator simulation completed successfully."
