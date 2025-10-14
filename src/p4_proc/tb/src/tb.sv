module tb;
    import tb_pkg::*;
    import smartnic_pkg::*;
    import p4_proc_pkg::*;

    // (Local) parameters
    localparam int AXIS_DATA_WID = 512;
    localparam int AXIS_DATA_BYTE_WID = AXIS_DATA_WID/8;
    localparam int NUM_PROC_PORTS = 2;

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

    axi4s_intf #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_in_if  [NUM_PROC_PORTS] (.aclk(clk));
    axi4s_intf #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_out_if [NUM_PROC_PORTS] (.aclk(clk));
    axi4s_intf #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_to_extern (.aclk(clk));
    axi4s_intf #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_from_extern (.aclk(clk));

    user_metadata_t user_metadata_in;
    logic           user_metadata_in_valid;
    user_metadata_t user_metadata_out, user_metadata_out_latch;
    logic           user_metadata_out_valid;

    // DUT instance - 'smartnic_app_igr_p4' instantiates the 'p4_proc' and 'vitisnetp4_wrapper' complex.
    smartnic_app_igr_p4 #(.NUM_PORTS(NUM_PROC_PORTS)) DUT (
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
    axi4s_intf_rx_sink   axis_from_extern_sink ( .from_tx(axis_from_extern) );
    axi4s_intf_tx_term   axis_to_extern_term   ( .to_rx(axis_to_extern) );

    //===================================
    // Local signals
    //===================================
    // Clocks
    initial clk = 1'b0;
    always #1455ps clk = ~clk; // 343.75 MHz

    initial axil_if.aclk = 1'b0;
    always #4ns axil_if.aclk = ~axil_if.aclk; // 125 MHz

    // Resets
    std_reset_intf reset_if (.clk(clk));
    initial begin
       reset_if.ready = 1'b0;
       reset_if._wait(10); reset_if.ready = 1'b1;
    end

    assign rstn = ~reset_if.reset;
    assign axil_if.aresetn = rstn;

    // SDNet AXI-L interface shares common AXI-L clock/reset
    assign axil_to_vitisnetp4.aclk = axil_if.aclk;
    assign axil_to_vitisnetp4.aresetn = axil_if.aresetn;

    // Timestamp
    timestamp_intf #() timestamp_if (.clk(clk), .srst(~rstn));
    assign timestamp = timestamp_if.timestamp;

    //===================================
    // Build
    //===================================
    function automatic tb_env build();
        tb_env env;
        // Instantiate environment
        env = new("tb_env");

        // Connect environment
        env.reset_vif = reset_if;
        env.timestamp_vif = timestamp_if;
        env.axil_vif = axil_if;
        env.axil_vitisnetp4_vif = axil_to_vitisnetp4;
        env.axis_in_vif[0]  = axis_in_if[0];
        env.axis_out_vif[0] = axis_out_if[0];
        env.axis_in_vif[1]  = axis_in_if[1];
        env.axis_out_vif[1] = axis_out_if[1];

        env.build();
        env.set_debug_level(0);
        return env;
    endfunction

    // Disable VitisNetP4 IP assertions
    // - works around a time-zero underflow assertion that causes an immediate exit from the sim
    // TODO: make this fine-grained... Vivado sim doesn't support hierarchical scoping, but could
    //       turn off assertions during reset and then re-enable possibly
    initial $assertoff(0);

endmodule : tb
