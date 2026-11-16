RTL_DIR ?= rtl
TB_DIR ?= tb_sv

RTL_SRC ?= $(RTL_DIR)/axi4_pkg.sv $(filter-out $(RTL_DIR)/axi4_pkg.sv, $(wildcard $(RTL_DIR)/*.sv))
TB_SRC ?= $(wildcard $(TB_DIR)/*.sv)
TB_TOP ?= tb_cache
VL_TOP := axi4_cache
SNAPSHOT = $(TB_TOP)_snap

SYNTH_VFLAGS := --binary --trace \
               -Wno-DECLFILENAME \
               -Wno-UNUSEDSIGNAL \
               -Wno-UNDRIVEN \
               -Wno-UNOPTFLAT \
               -Wno-VARHIDDEN \
               -Wno-CONSTRAINTIGN \
               -Wno-BLKSEQ \

VFLAGS := --binary --trace --coverage -Wno-CONSTRAINTIGN --assert --report-unoptflat

COVERAGE_TOOL ?= verilator_coverage
VERILATOR ?= verilator
YOSYS ?= yosys
VIVADO ?= vivado
XVLOG ?= xvlog
XELAB ?= xelab
XSIM ?= xsim

.PHONY: all clean yo-synth v-simulate v-sim_synth v-coverage\
	v-check v-lint v-build-dbg v-run-dbg v-gdb\
	xsim-parse xsim-elaborate xsim-sim 

all: v-simulate

v-build: v-check
	$(VERILATOR)  $(VFLAGS) -I$(RTL_DIR) $(RTL_SRC) $(TB_SRC) --top-module $(TB_TOP)

v-simulate: v-build
	./obj_dir/V$(TB_TOP)

yo-synth:
	mkdir -p netlist
	$(YOSYS) -s synth.ys | tee synth.log

v-sim-synth: yo-synth
	$(VERILATOR) $(SYNTH_VFLAGS) -I$(RTL_DIR) -I$(TB_DIR) \
		netlist/cache_synth_netlist.v $(TB_SRC) \
		--top-module $(TB_TOP) -o Vcache_synth
	./obj_dir/Vcache_synth

v-coverage: v-simulate
	@echo "--- GENERATING COVERAGE REPORT ---"
	$(COVERAGE_TOOL) --annotate-min 1 coverage.dat
	mkdir -p logs/annotated
	$(COVERAGE_TOOL) --annotate logs/annotated coverage.dat
	@echo "Annotated report saved in logs/annotated/"

v-lint:
	verilator --lint-only -Wall --top-module $(VL_TOP) -Irtl $(RTL_SRC) 2>&1 | tee lint.txt
	grep -n "UNOPTFLAT\|LATCH\|MULTIDRIVEN\|COMBDLY\|CLKDATA" lint.txt || true

v-build-dbg:
	rm -rf obj_dir
	verilator --binary --timing -Wall -Wno-fatal --trace-fst --report-unoptflat \
	  --converge-limit 20 -CFLAGS "-g -O0" --top-module tb_cache \
	  -Irtl -Itb_sv $(RTL_SRC) $(TB_SRC) -Mdir obj_dir 2>&1 | tee build.log

v-run-dbg: v-build-dbg
	./obj_dir/Vtb_cache +trace 2>&1 | tee run.log

v-gdb: v-build-dbg
	gdb -batch -ex run -ex bt ./obj_dir/Vtb_cache 2>&1 | tee crash_bt.txt

v-check:
	@verilator --version | awk '{ if ($$2+0 < 5.042) { print "Verilator >= 5.042 required, found " $$2; exit 1 } }'
	@which z3 > /dev/null || { echo "z3 required (sudo apt install z3)"; exit 1; }

xsim-parse:
	$(XVLOG) -sv $(RTL_SRC) $(TB_SRC)

xsim-elaborate: xsim-parse
	$(XELAB) -debug typical -top $(TB_TOP) -snapshot $(SNAPSHOT)

xsim-sim: xsim-elaborate
	$(XSIM) $(SNAPSHOT) -R

clean:
	rm -rf $(SNAPSHOT) obj_dir *.log *.pb *.jou *.vcd coverage.dat logs/ coverage.info coverage_html/ *.wdb xsim.dir *.txt 
