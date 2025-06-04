module tb;
    import tb_pkg::*;
    import smartnic_pkg::*;
    import p4_proc_pkg::*;

    // (Local) parameters
    localparam int AXIS_DATA_WID = 512;
    localparam int AXIS_DATA_BYTE_WID = AXIS_DATA_WID/8;
    localparam int NUM_PORTS = 2;

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
    axi4l_intf axil_to_vitisnetp4 ();
    axi4l_intf axil_to_extern ();

    axi4s_intf #(.TUSER_T(tuser_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_in_if  [NUM_PORTS] ();
    axi4s_intf #(.TUSER_T(tuser_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_out_if [NUM_PORTS] ();
    axi4s_intf #(.TUSER_T(tuser_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_to_vitisnetp4 ();
    axi4s_intf #(.TUSER_T(tuser_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_from_vitisnetp4 ();
    axi4s_intf #(.TUSER_T(tuser_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_to_extern ();
    axi4s_intf #(.TUSER_T(tuser_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_from_extern ();

    user_metadata_t user_metadata_in;
    logic           user_metadata_in_valid;
    user_metadata_t user_metadata_out, user_metadata_out_latch;
    logic           user_metadata_out_valid;

    // DUT instance - 'smartnic_app_igr_p4' instantiates the 'p4_proc' and 'vitisnetp4_wrapper' complex.
    smartnic_app_igr_p4 #(.NUM_PORTS(NUM_PORTS)) DUT (
        .core_clk                ( clk ),
        .core_rstn               ( rstn ),
        .timestamp               ( timestamp ),
        .axil_to_p4_proc         ( axil_if ),
        .axil_to_vitisnetp4      ( axil_to_vitisnetp4 ),
        .axil_to_extern          ( axil_to_extern ),
        .egr_flow_ctl            ( '0 ),
        .axis_in                 ( axis_in_if ),
        .axis_out                ( axis_out_if ),
        .axis_to_extern          ( axis_to_extern ),
        .axis_from_extern        ( axis_from_extern )
    );

    axi4l_intf_controller_term   axil_term     ( .axi4l_if(axil_to_extern) );
    axi4s_intf_rx_sink   axis_from_extern_sink ( .axi4s_if(axis_from_extern) );
    axi4s_intf_tx_term   axis_to_extern_term ( .aclk(clk), .aresetn(rstn), .axi4s_if(axis_to_extern) );

    //===================================
    // Local signals
    //===================================
    logic rst;

    // Interfaces
    std_reset_intf #(.ACTIVE_LOW(1)) reset_if      (.clk(clk));
    std_reset_intf #(.ACTIVE_LOW(1)) mgmt_reset_if (.clk(axil_if.aclk));

    timestamp_intf #() timestamp_if (.clk(clk), .srst(rst));

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
    assign axil_to_vitisnetp4.aclk = axil_if.aclk;
    assign axil_to_vitisnetp4.aresetn = axil_if.aresetn;

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
            env.axil_vitisnetp4_vif = axil_to_vitisnetp4;
            env.axis_in_vif[0]  = axis_in_if[0];
            env.axis_out_vif[0] = axis_out_if[0];
            env.axis_in_vif[1]  = axis_in_if[1];
            env.axis_out_vif[1] = axis_out_if[1];

            env.connect();
        end
    endfunction

    // Export AXI-L accessors to VitisNetP4 shared library
    export "DPI-C" task axi_lite_wr;
    task axi_lite_wr(input int address, input int data);
        env.vitisnetp4_write(address, data);
    endtask

    export "DPI-C" task axi_lite_rd;
    task axi_lite_rd(input int address, inout int data);
        env.vitisnetp4_read(address, data);
    endtask

endmodule : tb
