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

    localparam int  DATA_BYTE_WID = axi4s_in[0].DATA_BYTE_WID;
    localparam type TID_T         = axi4s_in[0].TID_T;
    localparam type TDEST_T       = axi4s_in[0].TDEST_T;
    localparam type TUSER_T       = axi4s_in[0].TUSER_T;

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
                  .TUSER_T(TUSER_T), .TID_T(TID_T), .TDEST_T(TDEST_T))  demux_out [NUM_PORTS][2] ();

    generate for (genvar i = 0; i < NUM_PORTS; i += 1) begin
        axi4s_intf_demux #(.N(2)) axi4s_demux_inst (
            .axi4s_in  (axi4s_in[i]),
            .axi4s_out (demux_out[i]),
            .sel       (smartnic_app_igr_regs.app_igr_config.demux_sel)
        );

        axi4s_full_pipe axi4s_full_pipe_0 (.axi4s_if_from_tx(demux_out[i][0]), .axi4s_if_to_rx(axi4s_out[i]));
        axi4s_full_pipe axi4s_full_pipe_1 (.axi4s_if_from_tx(demux_out[i][1]), .axi4s_if_to_rx(axi4s_c2h[i]));

    end endgenerate

endmodule // smartnic_app_igr
