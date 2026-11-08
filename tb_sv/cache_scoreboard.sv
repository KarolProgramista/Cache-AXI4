/* verilator lint_off WIDTHTRUNC */
typedef class cache_transaction;

class cache_scoreboard;
    mailbox #(cache_transaction) mon2scb_mbx;

    logic [31:0] ref_mem [logic [29:0]];

    int match_count = 0;
    int error_count = 0;

    function new(mailbox #(cache_transaction) mbx);
        this.mon2scb_mbx = mbx;
    endfunction

    task run();
        cache_transaction tr;

        forever begin
            mon2scb_mbx.get(tr);

            if (tr.we) begin
                ref_mem[tr.addr] = tr.dataIn;
                $display("[%0t] [SCOREBOARD] WRITE: Addr=0x%0h | Data=0x%0h",
                    $time, tr.addr, tr.dataIn);
            end else begin
                logic [31:0] exp_data;

                if (ref_mem.exists(tr.addr))
                    exp_data = ref_mem[tr.addr];
                else
                    exp_data = 32'h1000+32'(tr.addr);

                if (tr.dataOut === exp_data) begin
                    $display("[%0t] [SCB PASS]: addr=0x%0h | exp=0x%0h | got=0x%0h",
                        $time, tr.addr, exp_data, tr.dataOut);
                    match_count++;
                end else begin
                    $display("[%0t] [SCB FAILS]: addr=0x%0h | exp=0x%0h | got=0x%0h",
                        $time, tr.addr, exp_data, tr.dataOut);
                    error_count++;

                end
            end
        end
    endtask

endclass
