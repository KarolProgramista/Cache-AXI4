
/* verilator lint_off WIDTHTRUNC */
typedef class cache_transaction;

class cache_generator;
    mailbox #(cache_transaction) gen2drv_mbx;

    function new(mailbox #(cache_transaction) mbx);
        this.gen2drv_mbx = mbx;
    endfunction

    task run_random(int transaction_count=50);
        cache_transaction tr;

        repeat (transaction_count) begin
            tr = new();

            if (!tr.randomize()) begin
                $fatal(1, "[%0t] [GENERATOR] Randomization failed!", $time);
            end

            tr.display("GEN-RAN");
            gen2drv_mbx.put(tr);
        end
    endtask

    task run_raw(int transaction_count=10);
        cache_transaction tr_w, tr_r;

        repeat (transaction_count) begin
            tr_w = new();

            if (!tr_w.randomize())
                $fatal(1, "[%0t] [GENERATOR] Randomization failed!", $time);

            tr_w.we = 1'b1;
            tr_w.display("GEN-W");
            gen2drv_mbx.put(tr_w);

            tr_r = new();
            tr_r.we = 1'b0;
            tr_r.dataIn = tr_w.dataIn;
            tr_r.addr = tr_w.addr;
            tr_r.request = 1'b1;

            tr_r.display("GEN-R");
            gen2drv_mbx.put(tr_r);
        end
    endtask

    task run_eviction(int transaction_count=10);
        cache_transaction tr_w, tr_r_eviction;

        repeat (transaction_count) begin
            tr_w = new();

            if (!tr_w.randomize())
                $fatal(1, "[%0t] [GENERATOR] Randomization failed!", $time);

            tr_w.we = 1'b1;
            tr_w.display("GEN-W");
            gen2drv_mbx.put(tr_w);

            tr_r_eviction = new();
            if (!tr_r_eviction.randomize())
                $fatal(1, "[%0t] [GENERATOR] Randomization failed!", $time);

            tr_r_eviction.we = 1'b0;
            tr_r_eviction.addr[5:0] = tr_w.addr[5:0];
            tr_r_eviction.addr[15:6] = (tr_w.addr[15:6] + 1) & 10'b0000001111;

            tr_r_eviction.display("GEN-EVICT");
            gen2drv_mbx.put(tr_r_eviction);
        end
    endtask
endclass
/*verilator coverage_on*/
