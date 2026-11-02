# One-way write-back write-allocate cache module
A 16-bit cache module containing 64 (128B) words with a controler faciliating 16-bit memory transactions.
## 1. Interface
### Inputs
- *addr* - Memory address of requested word (16 bits)
- *we* - Cache write enable (1 bit)
- *request* - Signal cache to start input process cycle (1 bit)
- *cpuDataIn* - Word to be writen into memory if we is 1 (16 bits)
- *memDataIn* - Connection to memory's output (16 bits)
- *clk* - clock input (1 bit)
- *reset* - reset input (1 bit)
### Outputs
- *cpuDataOut* - Data fetched by cache if we is 0 (16 bits)
- *ready* - Signal indicating that cache process cycle is done (1 bit)
- *memAddr* - Connection to memory's address rail (16 bits)
- *memDataOut* - Connection to memory's input (16 bits)
- *memWe* - Memorys write enable (1 bit)

## 2. Cache Organization
Address decomposition:

| **BITS** | 15:6 | 5:2 | 1:0 |
|---|---|---|---|
| **MEANING** | TAG | INDEX | OFFSET |

Where INDEX selects the cache line, OFFSET - a word from the line, and TAG indentifies if the line containes requested memory block.

Each line contains VALID and DIRTY bits and 4 words.

## 3. Control and Timing
Set *request* bit to start cache cycle. When cache finishes processing, *ready* bit will be set. Only then new requests can be made. *cpuDataOut* might be set before *ready*, but should be read only when *ready* is 1. Read and write takes 2 cycles on hit (requested data in cache) and 10 cycles on miss (requested data needs fetching from external memory). *cpuDataOut* might change even if *we* is 0.

Cache supports only one-cycle memories.

## 4. Reset behaviour
Reset is synchronous. Sets every internal registers and outputs to 0s. Sets state to IDLE and *ready* to 1.

## 5. Synthesis
Module was successfuly synthesised using **Vivado** for **Xilinx/AMD Artix-7**. Post-synthesis simulation was verified against SV Testbench. Resource Utilization Report and Static Timing Analysis Report from Vivado are included in *reports* folder.

## How to Run
```bash
# Run SystemVerilog Simulation
make v-simulate

# Run Logic Synthesis (Yosys)
make yo-synth

# Run Post-Synthesis Gate-Level Simulation
make v-sim-synth
```
