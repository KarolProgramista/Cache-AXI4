interface cache_ip_if (input logic clk, input logic reset);
    logic [29:0] addr;
    logic we;
    logic request;
    logic [31:0] cpuDataIn;
    logic [31:0] cpuDataOut;
    reg ready;

    logic [29:0] memAddr;
    logic [31:0] memDataIn;
    logic [31:0] memDataOut;
    logic memWe;
    logic memReadyW;
    logic memReadyR;

    modport IP (
        input addr, we, request, cpuDataIn, memDataIn, memReadyW, memReadyR, clk, reset,
        output cpuDataOut, ready, memAddr, memDataOut, memWe
    );

    modport WRAPPER (
        input cpuDataOut, ready, memAddr, memDataOut, memWe,
        output addr, we, request, cpuDataIn, memDataIn, memReadyW, memReadyR, clk, reset
    );

endinterface
