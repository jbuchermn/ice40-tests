PROJ := main
TOPMODULE := main

PIN_DEF := alchitry_cu.pcf
DEVICE := hx8k
PACKAGE := cb132

SIMCOMPILER := iverilog
SIMULATOR := vvp

SYNTHFLAGS := -p synth_ice40 -top $(TOPMODULE)
NEXTPNR := nextpnr-ice40 --$(DEVICE) --package $(PACKAGE) --pcf $(PIN_DEF)
SIMCOMPFLAGS :=
SIMFLAGS := -v

SRCS = $(wildcard *.v)
TBSRCS = $(filter %_tb.v, $(SRCS))
MODSRCS = $(filter-out %_tb.v %_incl.v, $(SRCS))
VVPS = $(patsubst %.v,%.vvp,$(TBSRCS))

BINS := $(PROJ).bin
RPTS := $(patsubst %.bin,%.rpt,$(BINS))
JSONS := $(patsubst %.bin,%.json,$(BINS))
ASCS := $(patsubst %.bin,%.asc,$(BINS))


all: timing bitstream

timing: $(RPTS)

bitstream: $(BINS)

$(JSONS): %.json: %.v $(MODSRCS)
	yosys '$(SYNTHFLAGS) -json $@' $^

$(ASCS): %.asc: %.json $(PIN_DEF) 
	$(NEXTPNR) --asc $@ --json $<

$(BINS): %.bin: %.asc
	icepack $< $@

$(RPTS): %.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

$(VVPS): %.vvp: %.v $(MODSRCS)
	$(SIMCOMPILER) $(SIMCOMPFLAGS) -o $@ $^

simulate: $(VVPS)
	$(foreach file, $^, $(SIMULATOR) $(SIMFLAGS) $(file);)

prog: $(BINS)
	sudo iceprog $<

clean:
	rm $(wildcard *.vvp) $(wildcard *.vcd) $(JSONS) $(BINS) $(RPTS) $(ASCS)
