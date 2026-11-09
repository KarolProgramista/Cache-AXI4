import axi4_pkg::*;

module axi4_cache (axi4_if.slave cpu_if);

    logic reset;
    logic gotA;
    logic we;
    logic read_op;

    logic [3:0] cache_strobe;

    logic [29:0] addr;
    logic [31:0] wdata;
    logic [31:0] ram_wdata;

    cache_ip_if cif(.clk(cpu_if.aclk), .reset(reset), .addr(addr), 
        .cpuDataIn(wdata), .we(we), .memDataIn(ram_wdata), .strobe(cache_strobe));
    axi4_if ram_if(.aclk(cpu_if.aclk), .aresetn(cpu_if.aresetn));

    cache_ip cache(cif);

    assign cif.request = (arvalid || (awvalid && wvalid)) && cif.ready;

    assign cpu_if.arready = cpu_if.arvalid && cif.ready;
    assign cpu_if.awready = cpu_if.awvalid && cpu_if.wvalid && cpu_if.arready;
    assign cpu_if.wready = cpu_if.awready;
    assign cpu_if.rvalid = cpu_if.ready && read_op;
    assign cpu_if.bvalid = cpu_if.ready && we;

    assign cpu_if.rresp = AXI_OKAY;
    assign cpu_if.bresp = AXI_OKAY;

    assign cpu_if.rdata = rvalid ? cpuDataOut : 32'b0;

    // Address latching with read first policy
    always_ff @(posedge clk) begin
        if (cpu_if.aresetn === 1'b1) begin
            if (cpu_if.arvalid && cif.ready) begin
                addr <= 30'(cpu_if.araddr >> 2);
                read_op <= 1'b0;
            end else if (cpu_if.awvalid && cif.ready) begin
                addr <= cpu_if.awaddr;
                we <= 1'b1;
            end else if (cif.ready) begin
                we <= 1'b0;
                read_op <= 1'b0;
            end
        end
    end

    // W
    always_ff @(posedge clk) begin
        if (cpu_if.aresetn === 1'b1) begin
            if (cpu_if.wvalid && cif.ready)
                wdata <= cpu_if.wdata;
        end
    end
    
    // Strobe decoding
    always_comb  begin
        cache_strobe = 4'b0000;
        if (cpu_if.wstrb[0] && cpu_if.awaddr % 4 == 0)
            cache_strobe += 4'b0001;
        if (cpu_if.wstrb[1] && cpu_if.awaddr % 4 <= 1)
            cache_strobe += 4'b0010;
        if (cpu_if.wstrb[2] && cpu_if.awaddr % 4 <= 2)
            cache_strobe += 4'b0100;
        if (cpu_if.wstrb[3])
            cache_strobe += 4'b1000;
    end

endmodule
