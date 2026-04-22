# --- Variables ---
VCS      = vcs
FLAGS    = -sverilog -debug_acc+all -timescale=1ns/1ps -kdb
TOP_NAME = aes_tb
SRC      = aes_tools.sv \
		   aes_modules.sv \
		   aes_tb.sv
SRC_SYNTH = netlist.v \
			aes_tb_post_synth.sv

# --- Default Target ---
all: clean compile run

# --- Compilation ---
compile:
	$(VCS) $(FLAGS) $(SRC) -top $(TOP_NAME) -o simv

# --- Simulation ---
run:
	./simv

# --- GUI Mode ---
gui:
	./simv -gui &

# --- Housekeeping ---
clean:
	rm -rf csrc simv simv.daidir ucli.key vc_hdrs.h
	rm -rf *.vcd *.log *.vpd DVEfiles

post-synth: clean
	$(VCS) $(FLAGS) $(SRC_SYNTH) -top $(TOP_NAME) -o simv