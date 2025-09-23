module smartnic_app_igr
#(
    parameter int NUM_PORTS = 2  // Number of ingress/egress axi4s ports.
 ) (
    input  logic      core_clk,
    input  logic      core_rstn,

    axi4s_intf.rx     axi4s_in  [NUM_PORTS],
    axi4s_intf.tx     axi4s_out [NUM_PORTS],
    axi4s_intf.tx     axi4s_c2h [NUM_PORTS],

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

    smartnic_app_igr_reg_intf  smartnic_app_igr_regs ();

    // pass AXI-L interface from aclk (AXI-L clock) to core clk domain
    axi4l_intf_cdc i_axil_intf_cdc (
        .axi4l_if_from_controller  ( axil_if ),
        .clk_to_peripheral         ( core_clk ),
        .axi4l_if_to_peripheral    ( axil_if__core_clk )
    );

    // smartnic_app_igr register block
    smartnic_app_igr_reg_blk smartnic_app_igr_reg_blk (
        .axil_if    ( axil_if__core_clk ),
        .reg_blk_if ( smartnic_app_igr_regs )
    );


    // -------------------------------------------------------------------------------------------------------
    // APPLICATION-SPECIFIC CONNECTIVITY
    // -------------------------------------------------------------------------------------------------------
    axi4s_intf  #(.DATA_BYTE_WID(DATA_BYTE_WID),
        .TUSER_WID(TUSER_WID), .TID_WID(TID_WID), .TDEST_WID(TDEST_WID))  demux_out [NUM_PORTS][2] (.aclk(core_clk), .aresetn(core_rstn));

    generate for (genvar i = 0; i < NUM_PORTS; i += 1) begin
        axi4s_intf_demux #(.N(2)) axi4s_demux_inst (
            .from_tx (axi4s_in[i]),
            .to_rx   (demux_out[i]),
            .sel     (smartnic_app_igr_regs.app_igr_config.demux_sel)
        );

        axi4s_full_pipe axi4s_full_pipe_0 (.from_tx(demux_out[i][0]), .to_rx(axi4s_out[i]));
        axi4s_full_pipe axi4s_full_pipe_1 (.from_tx(demux_out[i][1]), .to_rx(axi4s_c2h[i]));

    end endgenerate

endmodule // smartnic_app_igr
