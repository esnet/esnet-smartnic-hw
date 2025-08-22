module smartnic_app_egr
#(
    parameter int NUM_PORTS = 2  // Number of ingress/egress axi4s ports.
 ) (
    input  logic      core_clk,
    input  logic      core_rstn,

    axi4s_intf.rx     axi4s_in  [NUM_PORTS],
    axi4s_intf.rx     axi4s_h2c [NUM_PORTS],
    axi4s_intf.tx     axi4s_out [NUM_PORTS],

    axi4l_intf.peripheral axil_if
);

    localparam int DATA_BYTE_WID = axi4s_in[0].DATA_BYTE_WID;
    localparam int TID_WID       = axi4s_in[0].TID_WID;
    localparam int TDEST_WID     = axi4s_in[0].TDEST_WID;
    localparam int TUSER_WID     = axi4s_in[0].TUSER_WID;

    // ----------------------------------------------------------------------
    //  axil register map. axil intf, regio block and decoder instantiations.
    // ----------------------------------------------------------------------
    axi4l_intf  axil_if__core_clk ();

    smartnic_app_egr_reg_intf  smartnic_app_egr_regs ();

    // pass AXI-L interface from aclk (AXI-L clock) to core clk domain
    axi4l_intf_cdc i_axil_intf_cdc (
        .axi4l_if_from_controller  ( axil_if ),
        .clk_to_peripheral         ( core_clk ),
        .axi4l_if_to_peripheral    ( axil_if__core_clk )
    );

    // smartnic_app_egr register block
    smartnic_app_egr_reg_blk smartnic_app_egr_reg_blk (
        .axil_if    ( axil_if__core_clk ),
        .reg_blk_if ( smartnic_app_egr_regs )
    );


    // -------------------------------------------------------------------------------------------------------
    // APPLICATION-SPECIFIC CONNECTIVITY
    // -------------------------------------------------------------------------------------------------------
    axi4s_intf  #(.DATA_BYTE_WID(DATA_BYTE_WID),
                  .TUSER_WID(TUSER_WID), .TID_WID(TID_WID), .TDEST_WID(TDEST_WID))  mux_in  [NUM_PORTS][2] (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #(.DATA_BYTE_WID(DATA_BYTE_WID),
                  .TUSER_WID(TUSER_WID), .TID_WID(TID_WID), .TDEST_WID(TDEST_WID))  mux_out [NUM_PORTS]    (.aclk(core_clk), .aresetn(core_rstn));

    generate for (genvar i = 0; i < NUM_PORTS; i += 1) begin
        axi4s_intf_pipe axi4s_mux_in_pipe_0 ( .from_tx(axi4s_in[i]),  .to_rx(mux_in[i][0]) );
        axi4s_intf_pipe axi4s_mux_in_pipe_1 ( .from_tx(axi4s_h2c[i]), .to_rx(mux_in[i][1]) );

        axi4s_mux #(.N(2)) axi4s_mux_inst (
            .axi4s_in  (mux_in[i]),
            .axi4s_out (mux_out[i])
        );

        axi4s_full_pipe axis4s_full_pipe_inst (.from_tx(mux_out[i]), .to_rx(axi4s_out[i]));

    end endgenerate

endmodule // smartnic_app_egr
