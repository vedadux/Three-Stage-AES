SV2V = sv2v
YOSYS = yosys
VERILATOR = verilator
CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -pedantic

SV_DIR = rtl
V_DIR = tmp
TB_DIR = tb
CPP_DIR = cpp
OBJ_DIR = obj

SV_PACKAGE = $(SV_DIR)/aes128_package.sv
SOURCES = $(wildcard $(SV_DIR)/*.sv)
SV_FILES = $(filter-out $(SV_PACKAGE), $(SOURCES))
V_FILES = $(patsubst $(SV_DIR)/%.sv, $(V_DIR)/%.v,$(SV_FILES))
CPP_FILES = $(wildcard $(CPP_DIR)/*.cpp)
# OBJ_FILES = $(patsubst $(CPP_DIR)/%.cpp, $(OBJ_DIR)/%.o,$(CPP_FILES))
SIM_FILES = $(patsubst $(SV_DIR)/%.sv, $(OBJ_DIR)/V%,$(SV_FILES))

TOP_MODULE = bv8_front_basis
OUTPUT_FILE = $(V_DIR)/netlist.v

.PHONY = all sv2v clean test_%

all: $(OUTPUT_FILE) $(SIM_FILES)

sv2v: $(SV_PACKAGE) $(SV_FILES) tmp
	$(SV2V) -w $(V_DIR) -I rtl $(SV_PACKAGE) $(SV_FILES)

$(V_FILES): sv2v
	base="$$(basename -s .v $@)"; \
	echo "$$base"; \
	files="$$(find $$V_DIR -name "$$base\_*.v")"; \
	echo "$$files"; \
	for file in $$files; do \
        echo "Processing $$file"; \
		base2="$$(basename -s .v $$file)"; \
		if [ ! -e "$@" ] || ! grep -q "$$base2" $@ ; then \
			echo "\`include \"$$file\"" >> $@ ; \
		fi \
    done

tmp:
	mkdir -p tmp

$(OBJ_DIR)/V%: $(SV_DIR)/%.sv $(TB_DIR)/tb_%.cpp $(CPP_FILES)
	$(VERILATOR) --Mdir $(OBJ_DIR) -CFLAGS -I../cpp -cc -sv -Irtl --exe --build -Wall $^ --top-module $$(basename -s .sv $<)

$(OUTPUT_FILE): $(V_FILES)
	IN_FILES="$(V_FILES)" OUT_FILE="$(OUTPUT_FILE)" TOP_MODULE="$(TOP_MODULE)" $(YOSYS) synth.tcl

clean:
	rm -rf $(V_DIR) $(OBJ_DIR)