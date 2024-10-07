SV2V = sv2v
YOSYS = yosys
VERILATOR = verilator
CXX = g++

SV_DIR = rtl
V_DIR = gen
TB_DIR = tb
CPP_DIR = cpp
OBJ_DIR = obj
SYN_DIR = syn

VERILATOR_FLAGS = --Mdir $(OBJ_DIR) -CFLAGS -I$(shell pwd)/$(CPP_DIR) -cc -sv -I$(SV_DIR) --exe --build -Wall
VERILATOR_SYN_FLAGS = --Mdir $(OBJ_DIR) -CFLAGS -I$(shell pwd)/$(CPP_DIR) -cc --exe --build -Wall -Wno-unused -Wno-declfilename -Wno-unoptflat -Wno-undriven -O0

YOSYS_LOG_SUFFIX = __log.txt

SV_PACKAGE = $(SV_DIR)/aes128_package.sv
SOURCES = $(wildcard $(SV_DIR)/*.sv)
SV_FILES = $(filter-out $(SV_PACKAGE), $(SOURCES))
V_FILES = $(patsubst $(SV_DIR)/%.sv, $(V_DIR)/%.v,$(SV_FILES))
CPP_FILES = $(wildcard $(CPP_DIR)/*.cpp)
SIM_FILES = $(patsubst $(SV_DIR)/%.sv, $(OBJ_DIR)/V%,$(SV_FILES))

HPC1 = 0
HPC3 = 1
NEW_DESIGN      = 0
CANRIGHT_DESIGN = 1

TOP_MODULE = masked_3stage_bv8_inv
NUM_SHARES ?= 2
DEFAULT_LATENCY = 3
LATENCY    ?= $(DEFAULT_LATENCY)
DEFAULT_STAGE_TYPE = HPC3
STAGE_TYPE ?= $(DEFAULT_STAGE_TYPE)
DEFAULT_INVERTER_TYPE = NEW_DESIGN
INVERTER_TYPE ?= $(DEFAULT_INVERTER_TYPE)


LIBERTY_FILE = stdcells.lib

.PHONY = all sv2v clean test_% syn_%

all: $(OUTPUT_FILE) $(SIM_FILES)

$(V_DIR) $(OBJ_DIR) $(SYN_DIR):
	mkdir -p $@

# .PRECIOUS: $(V_DIR)/%.v
$(V_DIR)/%.v: $(SV_DIR)/%.sv $(SV_FILES) $(V_DIR)
	$(SV2V) -I $(SV_DIR) $< > $@

$(OBJ_DIR)/Vmasked%: VERILATOR_DEFINES = -pvalue+NUM_SHARES=$(NUM_SHARES) -CFLAGS -DNUM_SHARES=$(NUM_SHARES) 
$(OBJ_DIR)/Vmasked_aes%: VERILATOR_DEFINES += -pvalue+LATENCY=$(LATENCY)             -CFLAGS -DLATENCY=$(LATENCY) 
$(OBJ_DIR)/Vmasked_aes%: VERILATOR_DEFINES += -pvalue+CHOSEN_STAGE_TYPE=$(value $(STAGE_TYPE))       # -CFLAGS -DSTAGE_TYPE=$(STAGE_TYPE)
$(OBJ_DIR)/Vmasked_aes%: VERILATOR_DEFINES += -pvalue+CHOSEN_INVERTER_TYPE=$(value $(INVERTER_TYPE)) # -CFLAGS -DINVERTER_TYPE=$(INVERTER_TYPE)

$(OBJ_DIR)/Vsyn_masked%: VERILATOR_DEFINES = -CFLAGS -DNUM_SHARES=$(NUM_SHARES)
$(OBJ_DIR)/Vsyn_masked_aes%: VERILATOR_DEFINES += -CFLAGS -DLATENCY=$(LATENCY)


$(OBJ_DIR)/V%: $(SV_DIR)/%.sv $(TB_DIR)/tb_%.cpp $(CPP_FILES)
	$(VERILATOR) $(VERILATOR_DEFINES) $(VERILATOR_FLAGS) $^ --top-module $$(basename -s .sv $<)

syn_masked%: YOSYS_DEFINES = NUM_SHARES=$(NUM_SHARES)
syn_masked_aes_sbox%: YOSYS_DEFINES += LATENCY=$(LATENCY)
syn_masked_aes_sbox%: YOSYS_DEFINES += CHOSEN_STAGE_TYPE=$(value $(STAGE_TYPE))
syn_masked_aes_sbox%: YOSYS_DEFINES += CHOSEN_INVERTER_TYPE=$(value $(INVERTER_TYPE))

syn_masked%: YOSYS_LOG_SUFFIX = $(NUM_SHARES)_log.txt
syn_%: $(V_DIR)/%.v $(SYN_DIR)
	cp $< $(V_DIR)/tmp_$$(basename $<)
	$(YOSYS_DEFINES) IN_FILES="$<" TOP_MODULE="$$(basename -s .v $<)" OUT_BASE="$(SYN_DIR)/$@" LIBERTY="$(LIBERTY_FILE)" $(YOSYS) synth.tcl -t -l "$(SYN_DIR)/$@_$(YOSYS_LOG_SUFFIX)"

$(OBJ_DIR)/Vsyn_masked%: syn_masked% $(TB_DIR)/tb_masked%.cpp $(CPP_FILES)
	$(VERILATOR) $(VERILATOR_DEFINES) $(VERILATOR_SYN_FLAGS) $(SYN_DIR)/$<_$(NUM_SHARES)_pre.v $(wordlist 2,$(words $^),$^) --top-module $$(echo $< | sed 's/^syn_//') -o $(shell pwd)/$@

# $(SYN_DIR)/syn_%_pre.v $(SYN_DIR)/syn_%_post.v $(SYN_DIR)/syn_%_pre.json $(SYN_DIR)/syn_%_post.json $(SYN_DIR)/syn_%_stats.json: syn_%

show_masked%: $(SYN_DIR)/syn_masked%_$(NUM_SHARES)_pre.json
	IN_FILE="$<" $(YOSYS) show.tcl -t
show_%: $(SYN_DIR)/syn_%__pre.json
	IN_FILE="$<" $(YOSYS) show.tcl -t

clean:
	rm -rf $(V_DIR) $(OBJ_DIR) $(SYN_DIR)