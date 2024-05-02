module smartnic_app_igr
#(
    parameter int N = 2  // Number of ingress/egress axi4s ports.
 ) (
    input  logic      core_clk,
    input  logic      core_rstn,

    axi4s_intf.rx     axi4s_in[N],
    axi4s_intf.tx     axi4s_out[N],

    axi4l_intf.peripheral axil_if
);

    // ----------------------------------------------------------------------
    //  axil register map. axil intf, regio block and decoder instantiations.
    // ----------------------------------------------------------------------
    axi4l_intf  axil_to_smartnic_app_igr ();
    axi4l_intf  axil_to_smartnic_app_igr__core_clk ();

    smartnic_app_igr_reg_intf  smartnic_app_igr_regs ();

    // smartnic_app_igr register decoder
    smartnic_app_igr_decoder smartnic_app_igr_decoder_inst (
       .axil_if                   ( axil_if ),
       .smartnic_app_igr_axil_if  ( axil_to_smartnic_app_igr )
    );

    // pass AXI-L interface from aclk (AXI-L clock) to core clk domain
    axi4l_intf_cdc i_axil_intf_cdc (
        .axi4l_if_from_controller  ( axil_to_smartnic_app_igr ),
        .clk_to_peripheral         ( core_clk ),
        .axi4l_if_to_peripheral    ( axil_to_smartnic_app_igr__core_clk )
    );

    // smartnic_app_igr register block
    smartnic_app_igr_reg_blk smartnic_app_igr_reg_blk (
        .axil_if    ( axil_to_smartnic_app_igr__core_clk ),
        .reg_blk_if ( smartnic_app_igr_regs )
    );


    // -------------------------------------------------------------------------------------------------------
    // APPLICATION-SPECIFIC CONNECTIVITY
    // -------------------------------------------------------------------------------------------------------

    generate for (genvar i = 0; i < N; i += 1) begin
        axi4s_full_pipe axis4s_full_pipe_inst (.axi4s_if_from_tx(axi4s_in[i]), .axi4s_if_to_rx(axi4s_out[i]));
    end endgenerate

endmodule // smartnic_app_igr
