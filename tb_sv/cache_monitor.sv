typedef class cache_transaction;

class cache_monitor;
    virtual axi4_if.monitor vif;
    mailbox #(cache_transaction) mon2scb_mbx;

    function new(virtual axi4_if.monitor vif, mailbox #(cache_transaction) mbx);
        this.vif = vif;
        this.mon2scb_mbx = mbx;
    endfunction

    task run();
        cache_transaction tr;

        forever begin
            @(posedge vif.aclk);
            if (vif.rready || vif.wready) begin

                tr = new();

                tr.addr = vif.rready ? vif.araddr : vif.awaddr;
                tr.dataIn = vif.wdata;
                tr.we = vif.wready;

                tr.dataOut = vif.rdata;
                tr.ready = 1'b1;

                tr.display("MONITOR");

                mon2scb_mbx.put(tr);
            end
        end

    endtask
endclass
