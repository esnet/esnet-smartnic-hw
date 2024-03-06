module tb;
    import tb_pkg::*;
    import smartnic_322mhz_pkg::*;
    import p4_proc_pkg::*;

    // (Local) parameters
    localparam int AXIS_DATA_WID = 512;
    localparam int AXIS_DATA_BYTE_WID = AXIS_DATA_WID/8;
    localparam int N = 2;

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

    axi4s_intf #(.TUSER_T(tuser_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t))  axis_in_if  [N] ();
    axi4s_intf #(.TUSER_T(tuser_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t))  axis_out_if [N] ();
    axi4s_intf #(.TUSER_T(tuser_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t))  axis_to_sdnet ();
    axi4s_intf #(.TUSER_T(tuser_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t))  axis_from_sdnet ();

    axi3_intf  #(.DATA_BYTE_WID(32), .ADDR_WID(33), .ID_T(logic[5:0])) axi_to_hbm [16] ();

    user_metadata_t user_metadata_in;
    logic           user_metadata_in_valid;
    user_metadata_t user_metadata_out, user_metadata_out_latch;
    logic           user_metadata_out_valid;

    // DUT instance
    p4_proc #(.N(N)) DUT (
        .core_clk                ( clk ),
        .core_rstn               ( rstn ),
        .timestamp               ( timestamp ),
        .axil_if                 ( axil_if ),
        .axis_from_switch        ( axis_in_if ),
        .axis_to_switch          ( axis_out_if ),
        .axis_from_sdnet         ( axis_from_sdnet ),
        .axis_to_sdnet           ( axis_to_sdnet ),
        .user_metadata_in_valid  ( user_metadata_in_valid ),
        .user_metadata_in        ( user_metadata_in ),
        .user_metadata_out_valid ( user_metadata_out_valid ),
        .user_metadata_out       ( user_metadata_out )
    );

    sdnet_0_wrapper sdnet_0_wrapper_inst (
        .core_clk                ( clk ),
        .core_rstn               ( rstn ),

        .axil_sdnet_aclk         ( axil_to_sdnet.aclk ),
        .axil_sdnet_aresetn      ( axil_to_sdnet.aresetn ),
        .axil_sdnet_awvalid      ( axil_to_sdnet.awvalid ),
        .axil_sdnet_awready      ( axil_to_sdnet.awready ),
        .axil_sdnet_awaddr       ( axil_to_sdnet.awaddr  ),
        .axil_sdnet_awprot       ( axil_to_sdnet.awprot  ),
        .axil_sdnet_wvalid       ( axil_to_sdnet.wvalid  ),
        .axil_sdnet_wready       ( axil_to_sdnet.wready  ),
        .axil_sdnet_wdata        ( axil_to_sdnet.wdata   ),
        .axil_sdnet_wstrb        ( axil_to_sdnet.wstrb   ),
        .axil_sdnet_bvalid       ( axil_to_sdnet.bvalid  ),
        .axil_sdnet_bready       ( axil_to_sdnet.bready  ),
        .axil_sdnet_bresp        ( axil_to_sdnet.bresp   ),
        .axil_sdnet_arvalid      ( axil_to_sdnet.arvalid ),
        .axil_sdnet_arready      ( axil_to_sdnet.arready ),
        .axil_sdnet_araddr       ( axil_to_sdnet.araddr  ),
        .axil_sdnet_arprot       ( axil_to_sdnet.arprot  ),
        .axil_sdnet_rvalid       ( axil_to_sdnet.rvalid  ),
        .axil_sdnet_rready       ( axil_to_sdnet.rready  ),
        .axil_sdnet_rdata        ( axil_to_sdnet.rdata   ),
        .axil_sdnet_rresp        ( axil_to_sdnet.rresp   ),

        .axis_to_sdnet_tdata     ( axis_to_sdnet.tdata ),
        .axis_to_sdnet_tkeep     ( axis_to_sdnet.tkeep ),
        .axis_to_sdnet_tvalid    ( axis_to_sdnet.tvalid ),
        .axis_to_sdnet_tlast     ( axis_to_sdnet.tlast ),
        .axis_to_sdnet_tready    ( axis_to_sdnet.tready ),

        .axis_from_sdnet_tdata   ( axis_from_sdnet.tdata ),
        .axis_from_sdnet_tkeep   ( axis_from_sdnet.tkeep ),
        .axis_from_sdnet_tvalid  ( axis_from_sdnet.tvalid ),
        .axis_from_sdnet_tlast   ( axis_from_sdnet.tlast ),
        .axis_from_sdnet_tready  ( axis_from_sdnet.tready ),

        .user_metadata_in_valid  ( user_metadata_in_valid ),
        .user_metadata_in        ( user_metadata_in ),
        .user_metadata_out_valid ( user_metadata_out_valid ),
        .user_metadata_out       ( user_metadata_out ),

        .axi_to_hbm              ( axi_to_hbm )
    );

    assign axis_from_sdnet.aclk = clk;
    assign axis_from_sdnet.aresetn = rstn;

    hbm_bfm #(.PSEUDO_CHANNELS (16)) i_hbm_model (.axi3_if (axi_to_hbm));

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
    assign axis_in_if[0].aclk = clk;
    assign axis_in_if[0].aresetn = rstn;

    assign axis_in_if[1].aclk = clk;
    assign axis_in_if[1].aresetn = rstn;

    //===================================
    // Build
    //===================================
    function void build();
        if (env == null) begin
            // Instantiate environment
            env = new("tb_env",0); // Configure for little-endian

            // Connect
            env.reset_vif = reset_if;
            env.mgmt_reset_vif = mgmt_reset_if;
            env.timestamp_vif = timestamp_if;
            env.axil_vif = axil_if;
            env.axil_sdnet_vif = axil_to_sdnet;
            env.axis_in_vif[0]  = axis_in_if[0];
            env.axis_out_vif[0] = axis_out_if[0];
            env.axis_in_vif[1]  = axis_in_if[1];
            env.axis_out_vif[1] = axis_out_if[1];

            env.axi_to_hbm_vif = axi_to_hbm;

            env.connect();
        end
    endfunction

    // Export AXI-L accessors to VitisNetP4 shared library
    export "DPI-C" task axi_lite_wr;
    task axi_lite_wr(input int address, input int data);
        env.sdnet_write(address, data);
    endtask

    export "DPI-C" task axi_lite_rd;
    task axi_lite_rd(input int address, inout int data);
        env.sdnet_read(address, data);
    endtask

endmodule : tb
