SIM ?= nvc
TOPLEVEL_LANG ?= vhdl

SIM_ARGS+=--format=vcd --wave=keccak.vcd --dump-arrays

VHDL_SOURCES += $(PWD)/*.vhdl

TOPLEVEL = keccak_f

MODULE = test_keccak_f

include $(shell cocotb-config --makefiles)/Makefile.sim

