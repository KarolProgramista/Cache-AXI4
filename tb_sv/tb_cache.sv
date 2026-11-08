
/* verilator lint_off WIDTHTRUNC */
typedef class cache_transaction;

module tb_cache;
    logic clk = 0;
    logic reset = 0;
    always #5 clk = ~clk;

    cache_ip_if cif(.clk(clk), .reset(reset));

    cache_ip dut (.cif(cif));

    dummy_ram ram(dut.cif.WRAPPER);
    
    mailbox #(cache_transaction) gen2drv_mbx = new();
    mailbox #(cache_transaction) mon2scb_mbx = new();

    cache_driver drv;
    cache_monitor mon;
    cache_scoreboard scb;
    cache_generator gen;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_cache);
    end

    initial begin
        gen = new(gen2drv_mbx);
        drv = new(cif.WRAPPER, gen2drv_mbx);
        mon = new(cif.WRAPPER, mon2scb_mbx);
        scb = new(mon2scb_mbx);

        reset = 1;
        #10;
        reset = 0;
        #10;

        fork
            gen.run_random();
            drv.run();
            mon.run();
            scb.run();
        join_none

        @(posedge clk);


        $display("\n=======================================================");
        $display("                   TESTING RANDOM");
        wait(gen2drv_mbx.num() == 0);
        wait(mon2scb_mbx.num() == 0);
        wait(cif.ready == 1'b1);
        #100;
        $display(" TOTAL MATCHES : %0d", scb.match_count);
        $display(" TOTAL ERRORS  : %0d", scb.error_count);
        $display("=======================================================\n");

        fork
            gen.run_raw();
        join_none

        @(posedge clk);


        $display("\n=======================================================");
        $display("                   TESTING READ AFTER WRITE");
        wait(gen2drv_mbx.num() == 0);
        wait(mon2scb_mbx.num() == 0);
        wait(cif.ready == 1'b1);
        #100;
        $display(" TOTAL MATCHES : %0d", scb.match_count);
        $display(" TOTAL ERRORS  : %0d", scb.error_count);
        $display("=======================================================\n");

        fork
            gen.run_eviction();
        join_none

        @(posedge clk);


        $display("\n=======================================================");
        $display("                   TESTING READ AFTER WRITE");
        wait(gen2drv_mbx.num() == 0);
        wait(mon2scb_mbx.num() == 0);
        wait(cif.ready == 1'b1);
        #500;
        $display(" TOTAL MATCHES : %0d", scb.match_count);
        $display(" TOTAL ERRORS  : %0d", scb.error_count);
        $display("=======================================================\n");

        $display("\n=======================================================");
        $display("               VERIFICATION SUMMARY                    ");
        $display("=======================================================");
        $display(" TOTAL MATCHES : %0d", scb.match_count);
        $display(" TOTAL ERRORS  : %0d", scb.error_count);

        if (scb.error_count == 0 && scb.match_count > 0) begin
            $display(" OVERALL STATUS: >>> TEST PASSED <<<");
        end else begin
            $display(" OVERALL STATUS: >>> TEST FAILED <<<");
        end
        $display("=======================================================\n");

        $finish;
    end

endmodule
