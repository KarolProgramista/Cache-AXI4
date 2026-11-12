import axi4_pkg::*;

module axi4_cache (axi4_if.slave cpu_if);

    logic reset;
    logic gotA;
    logic we;
    logic read_op;

    logic [3:0] cache_strobe;

    logic [29:0] addr;
    logic [31:0] wdata;
    logic [31:0] ram_rdata;

    cache_ip_if cif(.clk(cpu_if.aclk), .reset(reset));
    axi4_if ram_if(.aclk(cpu_if.aclk), .aresetn(cpu_if.aresetn));

    cache_ip cache(cif);

    assign cif.request = (cpu_if.arvalid || (cpu_if.awvalid && cpu_if.wvalid));// && cif.ready && cpu_if.aresetn;

    assign cpu_if.arready = cpu_if.arvalid && cif.ready;
    assign cpu_if.awready = !cpu_if.arvalid && cpu_if.awvalid && cpu_if.wvalid && cif.ready;
    assign cpu_if.wready = cpu_if.awready;
    assign cpu_if.rvalid = cif.ready && read_op;
    assign cpu_if.bvalid = cif.ready && we;

    assign cpu_if.rresp = AXI_OKAY;
    assign cpu_if.bresp = AXI_OKAY;

    assign cpu_if.rdata = cpu_if.rvalid ? cif.cpuDataOut : 32'b0;

    assign reset = !cpu_if.aresetn;

    assign cif.addr = addr;
    assign cif.cpuDataIn = wdata;
    assign cif.we = we;
    assign cif.memDataIn = 32'b0;// ram_rdata;
    assign cif.strobe = 4'b0;// cache_strobe;

    // Address latching with read first policy
    always_ff @(posedge cpu_if.aclk) begin
        if (cpu_if.aresetn == 1'b1) begin
            if (cpu_if.arvalid && cif.ready) begin
                addr <= 30'(cpu_if.araddr >> 2);
                read_op <= 1'b0;
            end else if (cpu_if.awvalid && cif.ready) begin
                addr <= 30'(cpu_if.awaddr >> 2);
                we <= 1'b1;
            end else if (cif.ready) begin
                we <= 1'b0;
                read_op <= 1'b0;
            end
        end else begin
            addr <= 30'b0;
            we <= 1'b0;
            read_op <= 1'b0;
        end
    end

    // W
    always_ff @(posedge cpu_if.aclk) begin
        if (cpu_if.aresetn == 1'b1) begin
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
