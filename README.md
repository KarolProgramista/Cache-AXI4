# One-way write-back write-allocate cache module
A 32-bit cache module containing 4096 words (16KiB) with a controler faciliating 32-bit memory transactions.
## 1. Interface
Both cache-ram and cpu-cache interfaces are AXI4-Lite.

## 2. Cache Organization
Address decomposition:

| **BITS** | 31:14 | 13:4 | 3:2 | 1:0 |
|---|---|---|---|---|
| **MEANING** | TAG | INDEX | WORD OFFSET | BYTE OFFSET |

Where INDEX selects the cache line, WORD OFFSET and BYTE OFFSET - a byte from the line, and TAG indentifies if the line containes requested memory block.

Each line contains VALID and DIRTY bits and 4 words.

## 3. Control and Timing
Standard AXI4-Lite behaviour.

## 4. Reset behaviour
Reset is asynchronous. Sets every internal registers and outputs to 0s. Sets state to IDLE. According to AXI4-Lite specification it sets all xxVALID signals to 0.

## 5. Synthesis
Module was successfuly synthesised using **Vivado** for **Xilinx/AMD Artix-7**. Post-synthesis simulation was verified against SV Testbench. Resource Utilization Report and Static Timing Analysis Report from Vivado are included in *reports* folder.

## 6. How to Run
```bash
# Run SystemVerilog Simulation
make

# Run Logic Synthesis (Yosys)
make yo-synth

# Run Post-Synthesis Gate-Level Simulation
make v-sim-synth
```
## 7. Minimal Dependencies
- Verliator >= 5.042 (tested with 5.054)
- z3
- g++, make
For synthesis you would need either ```yosys``` or ```Vivado```. Do not use earlier versions of Verilator, as it has a bug with virtual interfaces causing a convergence crash. 
