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
    import fec_pkg::*;

    localparam int DATA_BYTE_WID = axi4s_in[0].DATA_BYTE_WID;
    localparam int TID_WID       = axi4s_in[0].TID_WID;
    localparam int TDEST_WID     = axi4s_in[0].TDEST_WID;
    localparam int TUSER_WID     = axi4s_in[0].TUSER_WID;

    logic srst;
    assign srst = core_srst;

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
        .TUSER_WID(TUSER_WID), .TID_WID(TID_WID), .TDEST_WID(TDEST_WID))  demux_out [NUM_PORTS][2] (.aclk(core_clk));
    axi4s_intf  #(.DATA_BYTE_WID(DATA_BYTE_WID),
        .TUSER_WID(TUSER_WID), .TID_WID(TID_WID), .TDEST_WID(TDEST_WID))  fec_in [NUM_PORTS] (.aclk(core_clk));


    generate for (genvar i = 0; i < NUM_PORTS; i += 1) begin
        axi4s_intf_demux #(.N(2)) axi4s_demux_inst (
            .srst,
            .from_tx (axi4s_in[i]),
            .to_rx   (demux_out[i]),
            .sel     (smartnic_app_igr_regs.app_igr_config.demux_sel)
        );

        axi4s_full_pipe axi4s_full_pipe_0 (.srst, .from_tx(demux_out[i][0]), .to_rx(axi4s_out[i]));
        axi4s_full_pipe axi4s_full_pipe_1 (.srst, .from_tx(demux_out[i][1]), .to_rx(fec_in[i]));

    end endgenerate

    // xilinx_axi4s_ila #(.PIPE_STAGES(2)) xilinx_axi4s_fec_in (.axis_in(fec_in[0]));

    axi4s_intf #(.DATA_BYTE_WID(DATA_BYTE_WID), .TUSER_WID(TUSER_WID), .TID_WID(TID_WID), .TDEST_WID(TDEST_WID))
               _axi4s_c2h [NUM_PORTS] (.aclk(core_clk));

    localparam int DATA_WID = DATA_BYTE_WID*8;
    localparam int COL_LEN  = 4096;

    rs_acc_intf #(.DATA_WID(DATA_WID), .COL_LEN(COL_LEN)) col_in  [NUM_PORTS] (.clk(core_clk));
    rs_acc_intf #(.DATA_WID(DATA_WID), .COL_LEN(COL_LEN)) col_out [NUM_PORTS] (.clk(core_clk));
    rs_acc_intf #(.DATA_WID(DATA_WID), .COL_LEN(COL_LEN)) inj_out [NUM_PORTS] (.clk(core_clk));
    rs_acc_intf #(.DATA_WID(DATA_WID), .COL_LEN(COL_LEN)) dec_out [NUM_PORTS] (.clk(core_clk));

    /*
    axi4s_intf  #(.DATA_BYTE_WID(DATA_BYTE_WID), .TUSER_WID(TUSER_WID), .TID_WID(TID_WID),
                  .TDEST_WID(TDEST_WID))  axi4s_dec_in (.aclk(core_clk));

    assign axi4s_dec_in.tdata  = inj_out[0].data;
    assign axi4s_dec_in.tkeep  = {'0, inj_out[0].blk_size};
    assign axi4s_dec_in.tvalid = inj_out[0].valid;
    assign axi4s_dec_in.tready = inj_out[0].ready;
    */
    // xilinx_axi4s_ila #(.PIPE_STAGES(2)) xilinx_axi4s_dec_in (.axis_in(axi4s_dec_in));

    generate for (genvar i = 0; i < NUM_PORTS; i += 1) begin
        assign col_in[i].data     = fec_in[i].tdata;
        assign col_in[i].valid    = fec_in[i].tvalid;
        assign col_in[i].blk_size = smartnic_app_igr_regs.app_igr_config.blk_size_dec;

        assign fec_in[i].tready = col_in[i].ready;

        fec_col_transpose #(
            .DATA_WID      (DATA_WID),
            .COL_WID       (SYM_SIZE),
            .COL_LEN       (COL_LEN),
            .MODE          (BIT_TO_SYM)
        ) fec_sym_to_bit_0 (
            .clk           (core_clk),
            .srst          (core_srst),
            .data_in       (col_in[i]),
            .data_out      (col_out[i])
        );

        rs_acc_err_inj #(.DATA_WID(DATA_WID), .COL_LEN(COL_LEN)) rs_acc_err_inj_0 (
            .clk           (core_clk),
            .srst          (core_srst),
            .err_loc_vec   (RS_ERR_LOC_LUT[smartnic_app_igr_regs.app_igr_config.err_loc_inj]),
            .data_in       (col_out[i]),
            .data_out      (inj_out[i])
        );

        rs_acc_decode #(.DATA_WID(DATA_WID), .COL_LEN(COL_LEN)) rs_acc_decode_0 (
            .clk            (core_clk),
            .srst           (core_srst),
            .err_loc        (smartnic_app_igr_regs.app_igr_config.err_loc_dec),
            .data_in        (inj_out[i]),
            .data_out       (dec_out[i])
        );

        assign _axi4s_c2h[i].tdata  = dec_out[i].data;
        assign _axi4s_c2h[i].tvalid = dec_out[i].valid;
        assign _axi4s_c2h[i].tkeep  = '1;  // temporily (?) tie metadata signals.
        assign _axi4s_c2h[i].tid    = '0;
        assign _axi4s_c2h[i].tdest  = '0;
        assign _axi4s_c2h[i].tuser  = '0;
        assign _axi4s_c2h[i].tlast  = dec_out[i].eos;

        assign dec_out[i].ready = _axi4s_c2h[i].tready;

        axi4s_full_pipe axis4s_full_pipe_inst (.srst, .from_tx(_axi4s_c2h[i]), .to_rx(axi4s_c2h[i]));

    end endgenerate


endmodule // smartnic_app_igr
