SV2V = sv2v
YOSYS = yosys
VERILATOR = verilator

SV_DIR = rtl
V_DIR = tmp

SV_PACKAGE = $(SV_DIR)/aes128_package.sv
SOURCES = $(wildcard $(SV_DIR)/*.sv)
SV_FILES = $(filter-out $(SV_PACKAGE), $(SOURCES))
V_FILES = $(patsubst $(SV_DIR)/%.sv, $(V_DIR)/%.v,$(SV_FILES))

TOP_MODULE = bv8_inv
OUTPUT_FILE = $(V_DIR)/netlist.v

.PHONY = all sv2v clean

all: $(OUTPUT_FILE)

sv2v: $(SV_PACKAGE) $(SV_FILES) tmp
	$(SV2V) -w $(V_DIR) $(SV_PACKAGE) $(SV_FILES)

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

verilator: $(SV_PACKAGE) $(SV_FILES)
	$(VERILATOR) -cc -sv $(SV_PACKAGE) $(SV_FILES) --top-module hpc3_mul

$(OUTPUT_FILE): $(V_FILES)
	IN_FILES="$(V_FILES)" OUT_FILE="$(OUTPUT_FILE)" TOP_MODULE="$(TOP_MODULE)" $(YOSYS) synth.tcl

clean:
	rm -rf $(V_DIR)