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

    localparam int DATA_WID      = DATA_BYTE_WID*8;
    localparam int PARITY_WID    = DATA_WID*RS_2T/RS_K;
    localparam int SYM_PER_COL   = 512;
    localparam int FEC_STAGES    = 7;

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

        logic [DATA_WID+86-1:0] data_out;  // data_out includes both packet data and meta data.
        logic [PARITY_WID -1:0] parity_out;
        logic data_out_valid;
        logic data_out_ready;

/*
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
*/

        logic [DATA_WID-1:0] rs_acc_data_in;
        logic rs_acc_valid;
        logic rs_acc_ready;

        fec_blk_transpose #(.DATA_WID(DATA_WID), .NUM_COL(RS_K), .SYM_PER_COL(SYM_PER_COL),
            .MODE           (CW_TO_COL)
        ) fec_cw_to_col_inst (
            .clk            (core_clk),
            .srst           (core_srst),
            .data_in        (demux_out[i][0].tdata),
            .data_in_valid  (demux_out[i][0].tvalid),
            .data_in_ready  (demux_out[i][0].tready),
            .data_out       (rs_acc_data_in),
            .data_out_valid (rs_acc_data_in_valid),
            .data_out_ready (rs_acc_data_in_ready)
        );

        logic [DATA_WID-1:0] parity;
        logic parity_valid;
        logic parity_ready;

        rs_acc #(.DATA_WID(DATA_WID), .SYM_PER_COL(SYM_PER_COL)) rs_acc_inst (
            .clk              (core_clk),
            .srst             (core_srst),
            .data_in          (rs_acc_data_in),
            .data_in_valid    (rs_acc_data_in_valid),
            .data_in_ready    (rs_acc_data_in_ready),
            .parity_out       (parity),
            .parity_out_valid (parity_valid),
            .parity_out_ready (parity_ready)
        );

        logic [DATA_WID-1:0] col_to_cw_data_out;
        logic col_to_cw_valid;
        logic col_to_cw_ready;

        fec_blk_transpose #(.DATA_WID(DATA_WID), .NUM_COL(RS_2T), .SYM_PER_COL(SYM_PER_COL),
            .MODE           (COL_TO_CW)
        ) fec_col_to_cw_inst (
            .clk            (core_clk),
            .srst           (core_srst),
            .data_in        (parity),
            .data_in_valid  (parity_valid),
            .data_in_ready  (parity_ready),
            .data_out       (col_to_cw_data_out),
            .data_out_valid (col_to_cw_valid),
            .data_out_ready (col_to_cw_ready)
        );

        bus_intf #(DATA_WID)   _rd_if (.clk(core_clk));
        bus_intf #(PARITY_WID)  rd_if (.clk(core_clk));

        assign col_to_cw_ready  = _rd_if.ready;
        assign _rd_if.data      = col_to_cw_data_out;
        assign _rd_if.valid     = col_to_cw_valid;

        bus_width_converter #(.BIGENDIAN(0)) bus_width_converter_inst (
            .srst (srst),
            .from_tx (_rd_if),
            .to_rx (rd_if)
        );

        // instantiate data and parity FIFOs.
        logic [DATA_WID+86-1:0] data_fifo_in;  // data_fifo_in includes both packet data and meta data.
        logic data_fifo_wr, data_fifo_wr_rdy, data_fifo_rd, data_fifo_empty;

        logic [DATA_WID/SYM_SIZE-1:0][SYM_SIZE-1:0] parity_fifo_in;
        logic parity_fifo_wr, parity_fifo_wr_rdy, parity_fifo_rd, parity_fifo_empty;

        // data FIFO.
        assign data_fifo_in = {demux_out[i][0].tlast,
                               demux_out[i][0].tuser,
                               demux_out[i][0].tdest,
                               demux_out[i][0].tid,
                               demux_out[i][0].tkeep,
                               demux_out[i][0].tdata};
        assign data_fifo_wr =  demux_out[i][0].tvalid && demux_out[i][0].tready;
        assign data_fifo_rd = parity_fifo_rd;

        fifo_sync #(.DATA_WID(DATA_WID+86), .DEPTH(128)) fifo_sync_inst1 (
            .clk       (core_clk),
            .srst      (core_srst),
            .wr_rdy    (data_fifo_wr_rdy),
            .wr        (data_fifo_wr),
            .wr_data   (data_fifo_in),
            .wr_count  (),
            .full      (),
            .oflow     (),
            .rd        (data_fifo_rd),
            .rd_ack    (),
            .rd_data   (data_out),
            .rd_count  (),
            .empty     (data_fifo_empty),
            .uflow     ()
        );

        // parity FIFO.
        assign parity_fifo_in = rd_if.data;
        assign parity_fifo_wr = parity_fifo_wr_rdy && rd_if.valid;
        assign rd_if.ready    = parity_fifo_wr_rdy;
        assign parity_fifo_rd = data_out_ready && !data_fifo_empty && !parity_fifo_empty;

        fifo_sync #(.DATA_WID(PARITY_WID), .DEPTH(128)) fifo_sync_inst0 (
            .clk       (core_clk),
            .srst      (core_srst),
            .wr_rdy    (parity_fifo_wr_rdy),
            .wr        (parity_fifo_wr),
            .wr_data   (parity_fifo_in),
            .wr_count  (),
            .full      (),
            .oflow     (),
            .rd        (parity_fifo_rd),
            .rd_ack    (),
            .rd_data   (parity_out),
            .rd_count  (),
            .empty     (parity_fifo_empty),
            .uflow     ()
        );



        logic [DATA_WID-1:0] dec_data_in;
        logic                dec_data_in_valid;
        logic                dec_data_in_ready;

        fec_err_inject #(.DATA_WID(DATA_WID), .NUM_THREADS(1)) fec_err_inject_0 (
            .clk              (core_clk),
            .srst             (core_srst),

            .data_in          (data_out[DATA_WID-1:0]),
            .parity_in        (parity_out),
            .err_loc_in       (smartnic_app_igr_regs.app_igr_config.err_loc_inj),
            .data_in_valid    (parity_fifo_rd),
            .data_in_ready    (data_out_ready),

            .data_out         (dec_data_in),
            .data_out_valid   (dec_data_in_valid),
            .data_out_ready   (dec_data_in_ready)
        );

        fec_decode #(.DATA_WID(DATA_WID), .NUM_THREADS(1)) fec_decode_0 (
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

        assign fec_pipe[0][i].tvalid = data_fifo_rd;
        assign fec_pipe[0][i].tdata  = data_out[0   +: 512];
        assign fec_pipe[0][i].tkeep  = data_out[512 +: 64];
        assign fec_pipe[0][i].tid    = data_out[576 +: 4];
        assign fec_pipe[0][i].tdest  = data_out[580 +: 4];
        assign fec_pipe[0][i].tuser  = data_out[584 +: 13];
        assign fec_pipe[0][i].tlast  = data_out[597 +: 1];
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
