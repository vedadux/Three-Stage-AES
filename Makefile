SV2V = sv2v
YOSYS = yosys

SV_DIR = src
V_DIR = tmp

SV_PACKAGE = $(SV_DIR)/aes128_package.sv
SV_FILES = $(SV_DIR)/register.sv $(SV_DIR)/share_zero.sv
V_FILES = $(patsubst $(SV_DIR)/%.sv,$(V_DIR)/%.v,$(SV_FILES))

TOP_MODULE = share_zero
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