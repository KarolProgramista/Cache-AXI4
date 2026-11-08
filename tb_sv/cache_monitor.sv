typedef class cache_transaction;

class cache_monitor;
    virtual cache_ip_if.WRAPPER vif;
    mailbox #(cache_transaction) mon2scb_mbx;

    function new(virtual cache_ip_if.WRAPPER vif, mailbox #(cache_transaction) mbx);
        this.vif = vif;
        this.mon2scb_mbx = mbx;
    endfunction

    task run();
        cache_transaction tr;
        logic ready_prev = 1'b0;

        forever begin
            @(posedge vif.clk);
            if (!ready_prev && vif.ready && !(vif.addr == 30'h0000 && vif.cpuDataOut == 32'h0000)) begin

                tr = new();

                tr.addr = vif.addr;
                tr.dataIn = vif.cpuDataIn;
                tr.we = vif.we;

                tr.dataOut = vif.cpuDataOut;
                tr.ready = vif.ready;

                tr.display("MONITOR");

                mon2scb_mbx.put(tr);
            end
            ready_prev = vif.ready;
        end

    endtask
endclass
