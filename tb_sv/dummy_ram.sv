
module dummy_ram (axi4_if.slave ram_if);
    logic [31:0] mem [1023];

    assign ram_if.rdata = mem[ram_if.araddr[11:2]];
    assign ram_if.rvalid = ram_if.aresetn ? 1'b1 : 1'b0;
    assign ram_if.arready = ram_if.rready;

    initial begin
        foreach (mem[i]) begin
            mem[i] = 32'h1000 + 32'(i);
        end
    end

    always_ff @(posedge ram_if.aclk) begin
        if (ram_if.wvalid && ram_if.awvalid) begin
            ram_if.wready <= 1'b1;
            ram_if.awready <= 1'b1;
            mem[ram_if.awaddr[11:2]] <= ram_if.wdata;
        end
    end

endmodule
