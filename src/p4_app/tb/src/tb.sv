module tb;
    import tb_pkg::*;
    import smartnic_322mhz_pkg::*;

    // (Local) parameters
    localparam int AXIS_DATA_WID = 512;
    localparam int AXIS_DATA_BYTE_WID = AXIS_DATA_WID/8;

    //===================================
    // (Common) test environment
    //===================================
    tb_env env;

    //===================================
    // Device Under Test
    //===================================

    // Signals
    logic        clk;
    logic        rstn;

    logic [63:0] timestamp;

    axi4l_intf axil_if       ();
    axi4l_intf axil_to_sdnet ();

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_in_if ();
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_out_if ();
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_to_adpt ();
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_from_adpt ();

    axi3_intf  #(.DATA_BYTE_WID(32), .ADDR_WID(33), .ID_T(logic[5:0])) axi_to_hbm [16] ();

    // DUT instance
    p4_app DUT(
        .core_clk            ( clk ),
        .core_rstn           ( rstn ),
        .timestamp           ( timestamp ),
        .axil_if             ( axil_if ),
        .axil_to_sdnet       ( axil_to_sdnet ),
        .axis_switch_to_core ( axis_in_if ),
        .axis_core_to_switch ( axis_out_if ),
        .axis_to_host_0      ( axis_to_adpt ),
        .axis_from_host_0    ( axis_from_adpt ),
        .axi_to_hbm          ( axi_to_hbm )
    );

    hbm_model #(.PSEUDO_CHANNELS (16)) i_hbm_model (.axi3_if (axi_to_hbm));

    //===================================
    // Local signals
    //===================================
    logic rst;

    // Interfaces
    std_reset_intf #(.ACTIVE_LOW(1)) reset_if      (.clk(clk));
    std_reset_intf #(.ACTIVE_LOW(1)) mgmt_reset_if (.clk(axil_if.aclk));

    timestamp_if #() timestamp_if (.clk(clk), .srst(rst));

    // Generate datapath clock
    initial clk = 1'b0;
    always #1455ps clk = ~clk; // 343.75 MHz

    // Generate AXI management clock
    initial axil_if.aclk = 1'b0;
    always  #4ns axil_if.aclk = ~axil_if.aclk; // 125 MHz


    // Assign reset interfaces
    assign rstn = reset_if.reset;
    initial reset_if.ready = 1'b0;
    always @(posedge clk) reset_if.ready <= rstn;

    assign axil_if.aresetn = mgmt_reset_if.reset;
    initial mgmt_reset_if.ready = 1'b0;
    always @(posedge axil_if.aclk) mgmt_reset_if.ready <= axil_if.aresetn;

    assign rst = ~rstn;

    // SDNet AXI-L interface shares common AXI-L clock/reset
    assign axil_to_sdnet.aclk = axil_if.aclk;
    assign axil_to_sdnet.aresetn = axil_if.aresetn;

    // Timestamp
    assign timestamp = timestamp_if.timestamp;

    // Assign AXI-S input clock/reset
    assign axis_in_if.aclk = clk;
    assign axis_in_if.aresetn = rstn;

    assign axis_from_adpt.aclk = clk;
    assign axis_from_adpt.aresetn = rstn;

    //===================================
    // Build
    //===================================
    function void build(
            input string hier_path="tb"
        );
        if (env == null) begin
            // Instantiate environment
            env = new("tb_env",0); // Configure for little-endian

            // Connect
            env.reset_vif = reset_if;
            env.mgmt_reset_vif = mgmt_reset_if;
            env.timestamp_vif = timestamp_if;
            env.axil_vif = axil_if;
            env.axil_sdnet_vif = axil_to_sdnet;
            env.axis_in_vif = axis_in_if;
            env.axis_out_vif = axis_out_if;
            env.axis_to_adpt_vif = axis_to_adpt;
            env.axis_from_adpt_vif = axis_from_adpt;

            env.axi_to_hbm_vif = axi_to_hbm;

            env.connect();

            // Create SDNet driver
            env.sdnet_create(hier_path);
        end
    endfunction

    // Export AXI-L accessors to SDnet shared library
    export "DPI-C" task axi_lite_wr;
    task axi_lite_wr(input int address, input int data);
        env.sdnet_write(address, data);
    endtask

    export "DPI-C" task axi_lite_rd;
    task axi_lite_rd(input int address, inout int data);
        env.sdnet_read(address, data);
    endtask

endmodule : tb

module hbm_model #(
    parameter int PSEUDO_CHANNELS = 16,
    parameter bit DEBUG = 1'b0
) (
    axi3_intf.peripheral axi3_if [PSEUDO_CHANNELS]
);

    // Typedefs
    typedef logic [32:0]      addr_t;
    typedef logic [31:0][7:0] data_t;
    typedef logic [5:0]       id_t;

    data_t __ram [addr_t];

    generate
        for (genvar g_if = 0; g_if < PSEUDO_CHANNELS; g_if++) begin : g__if

            // (Local) signals
            addr_t awaddr;
            addr_t awaddr_reg;
            id_t   awid;
            id_t   awid_reg;

            addr_t araddr;
            addr_t araddr_reg;
            id_t   arid;
            id_t   arid_reg;

            // Always ready for write address
            assign axi3_if[g_if].awready = 1'b1;

            // Latch write address/id
            always @(posedge axi3_if[g_if].aclk) begin
                if (axi3_if[g_if].awvalid) begin
                    awaddr_reg <= axi3_if[g_if].awaddr;
                    awid_reg <= axi3_if[g_if].awid;
                end
            end
            assign awaddr = axi3_if[g_if].awvalid ? axi3_if[g_if].awaddr : awaddr_reg;
            assign awid   = axi3_if[g_if].awvalid ? axi3_if[g_if].awid   : awid_reg;

            // Always ready for write data
            assign axi3_if[g_if].wready = 1'b1;

            // Perform write
            always @(posedge axi3_if[g_if].aclk) begin
                if (axi3_if[g_if].wvalid) begin
                    if (axi3_if[g_if].wlast) begin
                        __ram[awaddr + 32] = axi3_if[g_if].wdata;
                        if (DEBUG) $display("WRITE on PC %d, ID %d: ADDR: %0x, DATA: %x", g_if, awid, awaddr + 32, axi3_if[g_if].wdata);
                    end else begin
                        __ram[awaddr] = axi3_if[g_if].wdata;
                        if (DEBUG) $display("WRITE on PC %d, ID %d: ADDR: %0x, DATA: %x", g_if, awid, awaddr, axi3_if[g_if].wdata);
                    end
                end
            end

            // Perform write response
            always @(posedge axi3_if[g_if].aclk) begin
                if (axi3_if[g_if].wvalid) begin
                    axi3_if[g_if].bvalid <= 1'b1;
                    axi3_if[g_if].bid <= awid;
                    axi3_if[g_if].bresp <= axi3_pkg::RESP_OKAY;
                end else begin
                    axi3_if[g_if].bvalid <= 1'b0;
                end
            end

            // Always ready for read address
            assign axi3_if[g_if].arready = 1'b1;

            // Latch read address/id
            always @(posedge axi3_if[g_if].aclk) begin
                if (axi3_if[g_if].arvalid) begin
                    araddr_reg <= axi3_if[g_if].araddr;
                    arid_reg <= axi3_if[g_if].arid;
                end
            end
            assign araddr = axi3_if[g_if].arvalid ? axi3_if[g_if].araddr : araddr_reg;
            assign arid   = axi3_if[g_if].arvalid ? axi3_if[g_if].arid   : arid_reg;

            // Perform read
            always @(posedge axi3_if[g_if].aclk) begin
                if (axi3_if[g_if].arvalid) begin
                    if (__ram.exists(araddr)) begin
                        axi3_if[g_if].rdata <= __ram[araddr];
                        if (DEBUG) $display("READ on PC %d, ID %d: ADDR: %0x, DATA: %x", g_if, arid, araddr, __ram[araddr]);
                    end else begin
                        axi3_if[g_if].rdata <= '0;
                        if (DEBUG) $display("READ on PC %d, ID %d: ADDR: %0x, DATA: %x", g_if, arid, araddr, '0);
                    end
                    axi3_if[g_if].rvalid <= 1'b1;
                    axi3_if[g_if].rid <= arid;
                    axi3_if[g_if].rlast <= 1'b0;
                    axi3_if[g_if].rresp <= axi3_pkg::RESP_OKAY;
                end else if (axi3_if[g_if].rvalid && !axi3_if[g_if].rlast) begin
                    if (__ram.exists(araddr + 32)) begin
                        axi3_if[g_if].rdata <= __ram[araddr + 32];
                        if (DEBUG) $display("READ on PC %d, ID %d: ADDR: %0x, DATA: %x", g_if, arid, araddr + 32, __ram[araddr + 32]);
                    end else begin
                        axi3_if[g_if].rdata <= '0;
                        if (DEBUG) $display("READ on PC %d, ID %d: ADDR: %0x, DATA: %x", g_if, arid, araddr, '0);
                    end
                    axi3_if[g_if].rvalid <= 1'b1;
                    axi3_if[g_if].rlast <= 1'b1;
                    axi3_if[g_if].rid <= arid;
                    axi3_if[g_if].rresp <= axi3_pkg::RESP_OKAY;
                end else begin
                    axi3_if[g_if].rvalid <= 1'b0;
                end
            end

        end : g__if
    endgenerate

endmodule : hbm_model
