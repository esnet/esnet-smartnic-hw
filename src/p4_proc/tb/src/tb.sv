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

    axi4s_intf #(.TUSER_T(tuser_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_in_if  [NUM_PROC_PORTS] ();
    axi4s_intf #(.TUSER_T(tuser_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) _axis_out_if [NUM_PROC_PORTS] ();
    axi4s_intf #(.TUSER_T(tuser_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_out_if [NUM_PROC_PORTS] ();
    axi4s_intf #(.TUSER_T(tuser_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_to_extern ();
    axi4s_intf #(.TUSER_T(tuser_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_from_extern ();

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
        .axis_out                ( _axis_out_if ),
        .axis_to_extern          ( axis_to_extern ),
        .axis_from_extern        ( axis_from_extern )
    );

    // set some 'axis_out_if' tuser fields to zero to simplify scoreboard comparisons (dont_cares).
    generate
        for (genvar i = 0; i < NUM_PROC_PORTS; i += 1) begin
            assign  axis_out_if[i].aclk    = _axis_out_if[i].aclk;
            assign  axis_out_if[i].aresetn = _axis_out_if[i].aresetn;
            assign  axis_out_if[i].tvalid  = _axis_out_if[i].tvalid;
            assign  axis_out_if[i].tdata   = _axis_out_if[i].tdata;
            assign  axis_out_if[i].tkeep   = _axis_out_if[i].tkeep;
            assign  axis_out_if[i].tlast   = _axis_out_if[i].tlast;
            assign  axis_out_if[i].tid     = _axis_out_if[i].tid;
            assign  axis_out_if[i].tdest   = _axis_out_if[i].tdest;
            assign _axis_out_if[i].tready  =  axis_out_if[i].tready;

            always_comb begin
                axis_out_if[i].tuser = _axis_out_if[i].tuser;
                axis_out_if[i].tuser.timestamp = 0;
                axis_out_if[i].tuser.pid = 0;
                axis_out_if[i].tuser.hdr_tlast = 0;
            end
        end
    endgenerate

    axi4l_intf_controller_term   axil_term     ( .axi4l_if(axil_to_extern) );
    axi4s_intf_rx_sink   axis_from_extern_sink ( .axi4s_if(axis_from_extern) );
    axi4s_intf_tx_term   axis_to_extern_term   ( .aclk(clk), .aresetn(rstn), .axi4s_if(axis_to_extern) );

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

    // Assign AXI-S input clock/reset
    generate
        for (genvar i = 0; i < NUM_PROC_PORTS; i += 1) begin
            assign axis_in_if[i].aclk = clk;
            assign axis_in_if[i].aresetn = rstn;
        end
    endgenerate

    // Timestamp
    timestamp_intf #() timestamp_if (.clk(clk), .srst(~rstn));
    assign timestamp = timestamp_if.timestamp;

    //===================================
    // Build
    //===================================
    function automatic tb_env build();
        tb_env env;
        // Instantiate environment
        env = new("tb_env", 0); // bigendian=0 to match CMACs.

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
