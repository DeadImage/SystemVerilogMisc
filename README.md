# (System)Verilog Miscellaneous

This is a set of different modules written by me with RTL code on both Verilog and SystemVerilog. This repository can be considered both as a personal stash and a portfolio. RTL code displayed here is not homogenous, different modules were written at different times for different purposes.

Most of the hardware modules have a corresponding testbench, written in SystemVerilog or Python (with cocotb). I prefer to use Questa for simulating, don't know if the behavior of certain TBs would differ in other sims.

## Short List

Here's a short list of what's inside the repository.

1. **Wavelet-Transformer** - Bachelor's graduation project. A set of modules for 2D discrete wavelet transform based on CDF5,3 wavelet. Uses lifting scheme for transformation.
2. **AXI-Interconnect** - AXI Many-To-One Interconnect (Many Masters, One Slave). Supports simultaneous read and write transactions from the same Master. Supports multitransactions.
3. **Test Base** - A small SystemVerilog package to provide a set of base classes for writing testbenches (not UVM).
4. **Misc** - Just a bunch of modules without any common purpose.
