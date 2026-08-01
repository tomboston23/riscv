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

spike: spike-compile-hw
	@mkdir -p $(PROGRAM_HOME)/run
	@touch $(PROGRAM_HOME)/run/program_run.log

	$(CXX) $(CFLAGS) \
	    $(STEM)/test/spike/spike.cpp \
	    -o $(PROGRAM_HOME)/spike_test \
	    $(LDFLAGS)

	$(PROGRAM_HOME)/spike_test \
	    $(PROGRAM_HOME)/program.elf \
	    $(PROGRAM_HOME)/run/program_run.log
