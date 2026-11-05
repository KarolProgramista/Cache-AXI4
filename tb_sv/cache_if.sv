interface cache_if (input logic clk);
    logic [31:0] addr;
    logic [31:0] cpuDataIn;
    logic [31:0] cpuDataOut;
    logic [31:0] memAddr;
    logic [31:0] memDataIn;
    logic [31:0] memDataOut;
    logic we;
    logic memWe;
    logic request;
    logic ready;
    logic reset;

    modport TB (
        input clk, cpuDataOut, ready,
        output addr, cpuDataIn, we, request, reset
    );

    modport DUT (
        input clk, addr, cpuDataIn, we, request, reset, memDataIn,
        output cpuDataOut, ready, memAddr, memDataOut, memWe
    );

    modport RAM (
        input clk, memAddr, memDataOut, memWe,
        output memDataIn
    );

    // Correct protocol assertions
    property stable_inputs_during_wait;
        @(posedge clk) disable iff (reset)
        (request && !ready) |=> $stable(addr) && $stable(cpuDataIn) && $stable(we);
    endproperty


    property reset_clear_mem_we_p;
        @(posedge clk) reset |-> (memWe  == 1'b0);
    endproperty

    assert_stable_inputs: assert property (stable_inputs_during_wait)
        else $error("[SVA] Cache inputs not stable during waiting for ready");
    assert_reset_memWe: assert property (reset_clear_mem_we_p)
        else $error("[SVA] Reset failed to clear memW flag");
endinterface
