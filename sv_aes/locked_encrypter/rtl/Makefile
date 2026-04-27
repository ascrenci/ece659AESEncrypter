# --- Variables ---
VCS      = vcs
FLAGS    = -sverilog -debug_acc+all -timescale=1ns/1ps -kdb
TOP_NAME = aes_tb
SRC      = aes_tools.sv \
		   aes_modules.sv \
		   aes_fsm_locked.sv \
		   aes_tb.sv

RAW_KEY  = testingaessarkey
SAR_KEY ?= 0

ifeq ($(SAR_KEY), KEY)
	KEY_HEX = $(shell printf "$(RAW_KEY)" | xxd -p)
else
	KEY_HEX = $(SAR_KEY)
endif

SYNTH	 = -v stdcells.v \
		   aes_locked.v \
		   aes_tb_post_synth.sv
 
# --- Default Target ---
all: clean compile run

# --- Compilation ---
compile:
	$(VCS) $(FLAGS) $(SRC) -top $(TOP_NAME) -o simv

# --- Simulation ---
run:
	./simv +SAR_KEY=$(KEY_HEX)

# --- GUI Mode ---
gui:
	./simv -gui &

# --- Housekeeping ---
clean:
	rm -rf csrc simv simv.daidir ucli.key vc_hdrs.h
	rm -rf *.vcd *.log *.vpd DVEfiles

synth:
	$(VCS) $(FLAGS) $(SYNTH) -top $(TOP_NAME) -o simv