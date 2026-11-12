interface axi4_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WDITH = 32,
    parameter int USER_WIDTH = 1,
    parameter int ID_WIDTH = 1
    )
    (input logic aclk, input logic aresetn);
    // Channel AW
    logic [ID_WIDTH-1:0] awid;
    logic [ADDR_WIDTH-1:0] awaddr;
    logic [7:0] awlen;
    logic [2:0] awsize;
    logic [1:0] awburst;
    logic awlock;
    logic [3:0] awcache;
    logic [2:0] awprot;
    logic [3:0] awqos;
    logic [3:0] awregion;
    logic [USER_WIDTH-1:0] awuser;
    logic awvalid;
    logic awready;

    // Channel AR
    logic [ID_WIDTH-1:0] arid;
    logic [ADDR_WIDTH-1:0] araddr;
    logic [7:0] arlen;
    logic [2:0] arsize;
    logic [1:0] arburst;
    logic arlock;
    logic [3:0] arcache;
    logic [2:0] arprot;
    logic [3:0] arqos;
    logic [3:0] arregion;
    logic [USER_WIDTH-1:0] aruser;
    logic arvalid;
    logic arready;

    // Channel W
    logic [ID_WIDTH-1:0] wid;
    logic [DATA_WDITH-1:0] wdata;
    logic [(DATA_WDITH/8)-1:0] wstrb;
    logic wlast;
    logic [USER_WIDTH-1:0] wuser;
    logic wvalid;
    logic wready;


    // Channel R
    logic [ID_WIDTH-1:0] rid;
    logic [DATA_WDITH-1:0] rdata;
    logic [1:0] rresp;
    logic rlast;
    logic [USER_WIDTH-1:0] ruser;
    logic rvalid;
    logic rready;

    // Channel B
    logic [ID_WIDTH-1:0] bid;
    logic [1:0] bresp;
    logic [USER_WIDTH-1:0] buser;
    logic bvalid;
    logic bready;

    modport master (
        input aclk, aresetn,
            rid, rdata, rresp, rlast, ruser, rvalid,
            bid, bresp, buser, bvalid,
            arready, awready, wready,
        output arid, araddr, arlen, arsize, arburst,
            arlock, arcache, arprot, arqos, arregion, aruser, arvalid,
            awid, awaddr, awlen, awsize, awburst,
            awlock, awcache, awprot, awqos, awregion, awuser, awvalid,
            wid, wdata, wstrb, wlast, wuser, wvalid,
            rready, bready
    );

    modport slave (
        input aclk, aresetn,
            arid, araddr, arlen, arsize, arburst,
            arlock, arcache, arprot, arqos, arregion, aruser, arvalid,
            awid, awaddr, awlen, awsize, awburst,
            awlock, awcache, awprot, awqos, awregion, awuser, awvalid,
            wid, wdata, wstrb, wlast, wuser, wvalid,
            rready, bready,
        output rid, rdata, rresp, rlast, ruser, rvalid,
            bid, bresp, buser, bvalid,
            arready, awready, wready
    );

    modport monitor (
        input aclk, aresetn,
            arid, araddr, arlen, arsize, arburst,
            arlock, arcache, arprot, arqos, arregion, aruser, arvalid,
            awid, awaddr, awlen, awsize, awburst,
            awlock, awcache, awprot, awqos, awregion, awuser, awvalid,
            wid, wdata, wstrb, wlast, wuser, wvalid,
            rid, rdata, rresp, rlast, ruser, rvalid,
            bid, bresp, buser, bvalid,
            arready, awready, wready, rready, bready
    );


    property reset_valid_p;
        @(posedge aclk) !aresetn |-> (awvalid  === 1'b0 && wvalid === 1'b0 &&
                                    arvalid === 1'b0 && bvalid === 1'b0 &&
                                    rvalid === 1'b0);
    endproperty

    assert_reset_memWe: assert property (reset_valid_p)
        else $error("[SVA] Reset must set all xxVALID to 0");
endinterface
