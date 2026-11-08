
module cache_ip (cache_ip_if.IP cif);
    logic [1:0] word_counter;
    logic [31:0] memory_blocks [4096];
    logic [17:0] tags [1024];
    logic valid [1024];
    logic dirty [1024];
    logic [9:0] index;
    logic [1:0] offset;
    logic [17:0] tag;
    logic hit;
    logic [11:0] memory_address;
    logic [11:0] counted_memory_address;

    localparam IDLE = 2'b00,
        LOOKUP = 2'b01,
        FETCH = 2'b10,
        REPLACE = 2'b11;
    reg [1:0] state;

    assign tag = cif.addr[29:12];
    assign index = cif.addr[11:2];
    assign offset = cif.addr[1:0];
    assign hit = (valid[index] === 1'b1) && (tags[index] == tag);
    assign memory_address = cif.addr[11:0];
    assign counted_memory_address = (12'(index) << 2) + 12'(word_counter);

    integer i, j;

    always_ff @(posedge cif.clk) begin
        if (cif.reset) begin
            for (i=0; i < 1024; i = i+1) begin
                for (j=0; j < 4; j=j+1)
                    memory_blocks[i*4+j] = 32'b0;
                tags[i] = 18'b0;
                valid[i] = 1'b0;
                dirty[i] = 1'b0;
            end

            word_counter <= 2'b0;
            cif.memWe <= 1'b0;
            state <= IDLE;
            cif.ready <= 1'b1;
            cif.cpuDataOut <= 32'b0;
            cif.memAddr <= 30'b0;
            cif.memDataOut <= 32'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (cif.request) begin
                        state <= LOOKUP;
                        cif.ready <= 1'b0;
                    end
                end
                LOOKUP: begin
                    if (hit) begin
                        if (cif.we) begin
                            memory_blocks[memory_address] <= cif.cpuDataIn;
                            dirty[index] <= 1'b1;
                        end else
                            cif.cpuDataOut <= memory_blocks[memory_address];
                        cif.ready <= 1'b1;
                        state <= IDLE;
                    end else begin
                        state <= FETCH;
                    end
                end
                FETCH: begin
                    cif.memAddr <= (cif.addr & (~(30'b11)))+30'(word_counter);
                    cif.memWe <= 1'b0;
                    state <= REPLACE;
                end
                REPLACE: begin
                    memory_blocks[counted_memory_address] <= cif.memDataIn;

                    if (cif.memAddr == cif.addr && cif.we)
                        memory_blocks[counted_memory_address] <= cif.cpuDataIn;
                    else if (cif.memAddr == cif.addr)
                        cif.cpuDataOut <= cif.memDataIn;

                    if (dirty[index]) begin
                        cif.memAddr <= 30'(30'(tags[index]) << 12) | (30'(index) << 2) | 30'(word_counter);
                        cif.memWe <= 1'b1;
                        cif.memDataOut <= memory_blocks[counted_memory_address];
                    end

                    if (word_counter < 2'b11) begin
                        word_counter <= word_counter+1;
                        state <= FETCH;
                    end else begin
                        word_counter <= 0;
                        state <= IDLE;
                        dirty[index] <= cif.we ? 1'b1 : 1'b0;
                        tags[index] <= tag;
                        valid[index] <= 1'b1;
                        cif.ready <= 1'b1;
                    end
                end
                default:
                    state <= IDLE;

            endcase
        end
    end
endmodule
