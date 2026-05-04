# --- Variables ---
VCS      = vcs
FLAGS    = -sverilog -debug_acc+all -timescale=1ns/1ps -kdb
TOP_NAME = dip_oracle_tb
SRC      = aes_tools.sv \
		   aes_modules.sv \
		   aes_tb.sv
SAR_KEY ?= 0
		   
# --- Default Target ---
all: clean compile run

# --- Compilation ---
compile:
	$(VCS) $(FLAGS) $(SRC) -top $(TOP_NAME) -o simv

# --- Simulation ---
run:
	./simv +SAR_KEY=$(SAR_KEY)

# --- GUI Mode ---
gui:
	./simv -gui &

# --- Housekeeping ---
clean:
	rm -rf csrc simv simv.daidir ucli.key vc_hdrs.h
	rm -rf *.vcd *.log *.vpd DVEfiles