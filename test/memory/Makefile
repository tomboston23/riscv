include $(STEM)/test/common.mk

mem: basic-mem

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

gtk:
	gtkwave $(MEM_OUT_DIR)/waves/memory_simple.vcd