VERILATOR := verilator
OUT_DIR := $(OUT_HOME)/memory
VERILATOR_DEFINES := -DOUT_HOME=\"$(OUT_HOME)\"
SRC := $(shell find . -name "*.sv" -or -name "*.v")

clean:
	@rm -rf $(OUT_DIR)

basic-mem:
	make basic-compile && make basic-run

basic-run:
	@mkdir -p $(OUT_DIR)/waves
	$(OUT_DIR)/basic-mem/Vmemory_simple_tb

basic-compile:	
	@mkdir -p $(OUT_DIR)
	@mkdir -p $(OUT_DIR)/basic-mem
	$(VERILATOR) \
		--binary \
		--sv \
		--trace \
		--Mdir $(OUT_DIR)/basic-mem \
		--top-module memory_simple_tb \
		$(VERILATOR_DEFINES) \
		$(SRC) \