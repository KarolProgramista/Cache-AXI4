class cache_transaction;
    rand logic [31:0] addr;
    rand logic [31:0] dataIn;
    rand logic we;

    rand logic request;

    logic ready;
    logic [31:0] dataOut;

    constraint addr_range_c {
        addr inside {[32'h0 : 32'h3FF]};
    }

    constraint op_dist_c {
        we dist {1'b0 := 70, 1'b1 := 30};
        request == 1'b1;
    }

    // For compatiblity with older versions of verilator
    function void post_randomize();
        this.addr = this.addr & 32'h03FF;
        this.request = 1'b1;
        this.we = ((this.dataIn%100) < 30) ? 1'b1 : 1'b0;
    endfunction

    function void display (string tag);
        $display("[%0t][%s] REQ=%0b | TYPE=%s | WDATA=0x%0h | ADDR=0x%0h | RDATA=0x%0h | READY=%0b",
            $time, tag, request, (we ? "W" : "R"), dataIn, addr, dataOut, ready);
    endfunction
endclass
