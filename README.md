A succinct VHDL implementation of Keccak-f[1600].

The main code is written in (to my best guess) VHDL-2008. Since I enjoy using it (and it makes random test vector generation very easy), I've opted for cocotb for the test bench. At least for me, this is a very easy approach to writing testbenches compared to a standard HDL-based test bench.

(This repository should house the remaining buffer pieces of keccak in the future.)

Future improvements:
- add the official test vectors (of limited use, since the random vectors in the testbench should be good enough)
- modularize the application for different cases of keccak-rho

