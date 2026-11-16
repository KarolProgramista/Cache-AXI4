typedef class cache_transaction;

class cache_driver;
    virtual axi4_if.master vif;

    mailbox #(cache_transaction) gen2drv_mbx;

    function new(virtual axi4_if.master vif, mailbox #(cache_transaction) mbx);
        this.vif = vif;
        this.gen2drv_mbx = mbx;
    endfunction

    task run();
        cache_transaction tr;

        vif.araddr <= 32'b0;
        vif.arvalid <= 1'b0;
        vif.awaddr <= 32'b0;
        vif.awvalid <= 1'b0;
        vif.wdata <= 32'b0;
        vif.wstrb <= 4'b1111;
        vif.wvalid <= 1'b0;
        vif.rready <= 1'b0;
        vif.bready <= 1'b1; // Write response can be ignored

        forever begin
            gen2drv_mbx.get(tr);
            drive_transaction(tr);
        end
    endtask

    task drive_transaction(cache_transaction tr);
        @(posedge vif.aclk);
        #1;
        vif.rready <= 1'b0;
        vif.bready <= 1'b1;

        if (tr.we) begin
            vif.awaddr <= tr.addr;
            vif.awvalid <= 1'b1;

            vif.wdata <= tr.dataIn;
            vif.wstrb <= tr.strobe;
            vif.wvalid <= 1'b1;
            do begin
                @(posedge vif.aclk);
            end while (!vif.wready || !vif.awvalid);
            vif.wvalid <= 1'b0;
            vif.awvalid <= 1'b0;
        end else begin
            vif.araddr <= tr.addr;
            vif.arvalid <= 1'b1;
            do begin
                @(posedge vif.aclk);
            end while (!vif.arready);
            vif.arvalid <= 1'b0;
            do begin
                @(posedge vif.aclk);
            end while (!vif.rvalid);
            vif.rready <= 1'b1;
            @(posedge vif.aclk);
            vif.rready <= 1'b0;
        end
    endtask

endclass
