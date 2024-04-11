SV2V = sv2v
YOSYS = yosys
VERILATOR = verilator
CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -pedantic

SV_DIR = rtl
V_DIR = gen
TB_DIR = tb
CPP_DIR = cpp
OBJ_DIR = obj
SYN_DIR = syn

SV_PACKAGE = $(SV_DIR)/aes128_package.sv
SOURCES = $(wildcard $(SV_DIR)/*.sv)
SV_FILES = $(filter-out $(SV_PACKAGE), $(SOURCES))
V_FILES = $(patsubst $(SV_DIR)/%.sv, $(V_DIR)/%.v,$(SV_FILES))
CPP_FILES = $(wildcard $(CPP_DIR)/*.cpp)
SIM_FILES = $(patsubst $(SV_DIR)/%.sv, $(OBJ_DIR)/V%,$(SV_FILES))

TOP_MODULE = masked_bv8_inv
LIBERTY_FILE = stdcells.lib

.PHONY = all sv2v clean test_% syn_%

all: $(OUTPUT_FILE) $(SIM_FILES)

$(V_DIR) $(OBJ_DIR) $(SYN_DIR):
	mkdir -p $@

.PRECIOUS: $(V_DIR)/%.v
$(V_DIR)/%.v: $(SV_DIR)/%.sv $(SV_FILES) $(V_DIR)
	$(SV2V) -I $(SV_DIR) $< > $@

$(OBJ_DIR)/V%: $(SV_DIR)/%.sv $(TB_DIR)/tb_%.cpp $(CPP_FILES)
	$(VERILATOR) -pvalue+NUM_SHARES=4 --Mdir $(OBJ_DIR) -CFLAGS -I../cpp -cc -sv -Irtl --exe --build -Wall $^ --top-module $$(basename -s .sv $<)

syn_%: $(V_DIR)/%.v $(SYN_DIR)
	IN_FILES="$<" TOP_MODULE="$$(basename -s .v $<)" OUT_BASE="$(SYN_DIR)/$@" LIBERTY="$(LIBERTY_FILE)" $(YOSYS) synth.tcl

# $(SYN_DIR)/syn_%_pre.v $(SYN_DIR)/syn_%_post.v $(SYN_DIR)/syn_%_pre.json $(SYN_DIR)/syn_%_post.json $(SYN_DIR)/syn_%_stats.json: syn_%

clean:
	rm -rf $(V_DIR) $(OBJ_DIR) $(SYN_DIR)