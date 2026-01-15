module smartnic_app_igr
#(
    parameter int NUM_PORTS = 2  // Number of ingress/egress axi4s ports.
 ) (
    input  logic      core_clk,
    input  logic      core_srst,

    axi4s_intf.rx     axi4s_in  [NUM_PORTS],
    axi4s_intf.tx     axi4s_out [NUM_PORTS],
    axi4s_intf.tx     axi4s_c2h [NUM_PORTS],

    axi4l_intf.peripheral axil_if
);
    import smartnic_pkg::*;
    import axi4s_pkg::*;
    import fec_pkg::*;

    localparam int DATA_BYTE_WID = axi4s_in[0].DATA_BYTE_WID;
    localparam int TID_WID       = axi4s_in[0].TID_WID;
    localparam int TDEST_WID     = axi4s_in[0].TDEST_WID;
    localparam int TUSER_WID     = axi4s_in[0].TUSER_WID;

    localparam int FEC_STAGES = 10;

    // ----------------------------------------------------------------------
    //  axil register map. axil intf, regio block and decoder instantiations.
    // ----------------------------------------------------------------------
    axi4l_intf  axil_if__core_clk ();

    smartnic_app_igr_reg_intf  smartnic_app_igr_regs ();

    logic srst;

    assign srst = core_srst;

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
    axi4s_intf  #(.DATA_BYTE_WID(DATA_BYTE_WID), .TID_WID(TID_WID), .TDEST_WID(TDEST_WID), .TUSER_WID(TUSER_WID))
        demux_out [NUM_PORTS][2] (.aclk(core_clk));

    axi4s_intf  #(.DATA_BYTE_WID(DATA_BYTE_WID), .TID_WID(TID_WID), .TDEST_WID(TDEST_WID), .TUSER_WID(TUSER_WID))
        fec_pipe [FEC_STAGES+1][NUM_PORTS] (.aclk(core_clk));

    logic  demux_sel [NUM_PORTS];

    generate for (genvar i = 0; i < NUM_PORTS; i += 1) begin : g__port
        port_t axi4s_in_tdest;
        assign axi4s_in_tdest = axi4s_in[i].tdest;
        assign demux_sel[i] = (axi4s_in_tdest.encoded.typ == VF0) ||
                              smartnic_app_igr_regs.app_igr_config.demux_sel;

        axi4s_intf_demux #(.N(2)) axi4s_demux_inst (
            .srst,
            .from_tx (axi4s_in[i]),
            .to_rx   (demux_out[i]),
            .sel     (demux_sel[i])
        );

//        axi4s_full_pipe axi4s_full_pipe_0 (.srst, .from_tx(demux_out[i][0]), .to_rx(axi4s_out[i]));

        logic [DATA_BYTE_WID-1:0][7:0] data_out, dec_data_in;

        logic [DATA_BYTE_WID*RS_2T/RS_K-1:0][7:0] parity_out;

        logic data_out_valid, dec_data_in_valid;
        logic data_out_ready, dec_data_in_ready;

        fec_encode fec_encode_0 (
            .clk              (core_clk),
            .srst             (core_srst),

            .data_in          (demux_out[i][0].tdata),
            .data_in_valid    (demux_out[i][0].tvalid),
            .data_in_ready    (demux_out[i][0].tready),

            .data_out         (data_out),
            .parity_out       (parity_out),
            .data_out_valid   (data_out_valid),
            .data_out_ready   (data_out_ready)
        );

        fec_err_inject fec_err_inject_0 (
            .clk              (core_clk),
            .srst             (core_srst),

            .data_in          (data_out),
            .parity_in        (parity_out),
            .err_loc_in       (smartnic_app_igr_regs.app_igr_config.err_loc_inj),
            .data_in_valid    (data_out_valid),
            .data_in_ready    (data_out_ready),

            .data_out         (dec_data_in),
            .data_out_valid   (dec_data_in_valid),
            .data_out_ready   (dec_data_in_ready)
        );

        fec_decode fec_decode_0 (
            .clk              (core_clk),
            .srst             (core_srst),

            .data_in          (dec_data_in),
            .err_loc          (smartnic_app_igr_regs.app_igr_config.err_loc_dec),
            .data_in_valid    (dec_data_in_valid),
            .data_in_ready    (dec_data_in_ready),

            .data_out         (axi4s_out[i].tdata),
            .data_out_valid   (axi4s_out[i].tvalid),
            .data_out_ready   (axi4s_out[i].tready)
        );

        assign fec_pipe[0][i].tvalid = demux_out[i][0].tvalid;
        assign fec_pipe[0][i].tdata  = demux_out[i][0].tdata;
        assign fec_pipe[0][i].tkeep  = demux_out[i][0].tkeep;
        assign fec_pipe[0][i].tlast  = demux_out[i][0].tlast;
        assign fec_pipe[0][i].tid    = demux_out[i][0].tid;
        assign fec_pipe[0][i].tdest  = demux_out[i][0].tdest;
        assign fec_pipe[0][i].tuser  = demux_out[i][0].tuser;

        assign fec_pipe[FEC_STAGES][i].tready = axi4s_out[i].tready;

        for (genvar j=0; j<FEC_STAGES; j++) begin : g__fec_pipe
            axi4s_intf_pipe #(.MODE(PUSH)) fec_pipe_0 (
                .srst     (core_srst),
                .from_tx  (fec_pipe[j][i]),
                .to_rx    (fec_pipe[j+1][i])
            );
        end : g__fec_pipe
        
        assign axi4s_out[i].tkeep   = fec_pipe[FEC_STAGES][i].tkeep;
        assign axi4s_out[i].tlast   = fec_pipe[FEC_STAGES][i].tlast;
        assign axi4s_out[i].tid     = fec_pipe[FEC_STAGES][i].tid;
        assign axi4s_out[i].tdest   = fec_pipe[FEC_STAGES][i].tdest;
        assign axi4s_out[i].tuser   = fec_pipe[FEC_STAGES][i].tuser;

        axi4s_full_pipe axi4s_full_pipe_1 (.srst, .from_tx(demux_out[i][1]), .to_rx(axi4s_c2h[i]));

    end : g__port
    endgenerate

endmodule // smartnic_app_igr
