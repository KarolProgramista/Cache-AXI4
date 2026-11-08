
module dummy_ram (cache_ip_if.WRAPPER ram_if);
    logic [31:0] mem [1023];

    assign ram_if.memDataIn = mem[ram_if.memAddr[9:0]];

    initial begin
        foreach (mem[i]) begin
            mem[i] = 32'h1000 + 32'(i);
        end
    end

    always_ff @(posedge ram_if.clk) begin
        if (ram_if.memWe)
            mem[ram_if.memAddr[9:0]] <= ram_if.memDataOut;
    end

endmodule
