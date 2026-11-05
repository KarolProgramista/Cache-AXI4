// Write-back write-allocate 32-bit cache
module cache_ip (addr, we, request, cpuDataIn, cpuDataOut, ready, memAddr, memDataIn, memDataOut, memWe, clk, reset);
    input [31:0] addr;
    input we;
    input request;
    input [31:0] cpuDataIn;

    output reg [31:0] cpuDataOut;
    output reg ready;

    output reg [31:0] memAddr;
    input reg [31:0] memDataIn;
    output reg [31:0] memDataOut;
    output reg memWe;

    input clk;
    input reset;
    
    reg [31:0] addr_latch;
    reg [1:0] word_counter;
    reg [31:0] memory_blocks [4096];
    reg [17:0] tags [1024];
    reg valid [1024];
    reg dirty [1024];
    wire [9:0] index;
    wire [1:0] word_offset;
    wire [1:0] byte_offset;
    wire [17:0] tag;
    wire hit;
    wire [11:0] memory_address;
    wire [11:0] counted_memory_address;

    localparam IDLE = 2'b00,
        LOOKUP = 2'b01,
        FETCH = 2'b10,
        REPLACE = 2'b11;
    reg [1:0] state;

    assign tag = addr_latch[31:14];
    assign index = addr_latch[13:4];
    assign word_offset = addr_latch[3:2];
    assign byte_offset = addr_latch[1:0];
    assign hit = (valid[index] === 1'b1) && (tags[index] == tag);
    assign memory_address = addr_latch[13:2];
    assign counted_memory_address = (12'(index) << 2) + 12'(word_counter);

    integer i, j;

    always_ff @(posedge clk) begin
        if (reset) begin
            for (i=0; i < 1024; i = i+1) begin
                for (j=0; j < 4; j=j+1)
                    memory_blocks[i*4+j] <= 32'b0;
                tags[i] <= 18'b0;
                valid[i] <= 1'b0;
                dirty[i] <= 1'b0;
            end

            word_counter <= 2'b0;
            memWe <= 1'b0;
            state <= IDLE;
            ready <= 1'b1;
            cpuDataOut <= 32'b0;
            memAddr <= 32'b0;
            memDataOut <= 32'b0;
            addr_latch <= 32'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (request) begin
                        state <= LOOKUP;
                        ready <= 1'b0;
                        addr_latch <= addr;
                    end
                end
                LOOKUP: begin
                    if (hit) begin
                        if (we) begin
                            memory_blocks[memory_address] <= cpuDataIn;
                            dirty[index] <= 1'b1;
                        end else
                            cpuDataOut <= memory_blocks[memory_address];
                        ready <= 1'b1;
                        state <= IDLE;
                    end else begin
                        state <= FETCH;
                    end
                end
                FETCH: begin
                    memAddr <= ((addr_latch>>2) & (~(32'b11)))+32'(32'(word_counter)<<2);
                    memWe <= 1'b0;
                    state <= REPLACE;
                end
                REPLACE: begin
                    memory_blocks[counted_memory_address] <= memDataIn;

                    if (memAddr == addr_latch && we)
                        memory_blocks[counted_memory_address] <= cpuDataIn;
                    else if (memAddr == addr_latch)
                        cpuDataOut <= memDataIn;

                    if (dirty[index]) begin
                        memAddr <= 32'(32'(tags[index]) << 12) | (32'(index) << 2) | 32'(word_counter);
                        memWe <= 1'b1;
                        memDataOut <= memory_blocks[counted_memory_address];
                    end

                    if (word_counter < 2'b11) begin
                        word_counter <= word_counter+1;
                        state <= FETCH;
                    end else begin
                        word_counter <= 0;
                        state <= IDLE;
                        dirty[index] <= we ? 1'b1 : 1'b0;
                        tags[index] <= tag;
                        valid[index] <= 1'b1;
                        ready <= 1'b1;
                    end
                end
                default:
                    state <= IDLE;

            endcase
        end
    end
endmodule
