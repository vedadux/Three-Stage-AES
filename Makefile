SV2V = sv2v
YOSYS = yosys

SV_DIR = src
V_DIR = tmp

SV_PACKAGE = $(SV_DIR)/aes128_package.sv
SOURCES = register.sv bv2_scl_n.sv bv2_mul.sv bv4_mul.sv generic_mul.sv share_zero.sv reduce_xor.sv hpc1_mul.sv
SV_FILES = $(patsubst %.sv,$(SV_DIR)/%.sv,$(SOURCES))
V_FILES =  $(patsubst %.sv, $(V_DIR)/%.v,$(SOURCES))

TOP_MODULE = hpc1_mul
OUTPUT_FILE = $(V_DIR)/netlist.v

.PHONY = all sv2v clean

all: $(OUTPUT_FILE)

sv2v: $(SV_PACKAGE) $(SV_FILES) tmp
	$(SV2V) -w $(V_DIR) $(SV_PACKAGE) $(SV_FILES)
	
$(V_FILES): sv2v
	base="$$(basename -s .v $@)"; \
	echo "$$base"; \
	files="$$(find -name $$V_DIR "$$base*.v")"; \
	echo "$$files"; \
	for file in $$files; do \
        echo "Processing $$file"; \
		base2="$$(basename -s .v $$file)"; \
		if [ "$$base" != "$$base2" ] && ! grep -q "$$base2" $@ ; then \
			echo "\`include \"$$file\"" >> $@ ; \
		fi \
    done
tmp:
	mkdir -p tmp

$(OUTPUT_FILE): $(V_FILES)
	IN_FILES="$(V_FILES)" OUT_FILE="$(OUTPUT_FILE)" TOP_MODULE="$(TOP_MODULE)" $(YOSYS) synth.tcl

clean:
	rm -rf $(V_DIR)