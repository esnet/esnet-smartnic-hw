module smartnic_app_egr
#(
    parameter int NUM_PORTS = 2  // Number of ingress/egress axi4s ports.
 ) (
    input  logic      core_clk,
    input  logic      core_srst,

    axi4s_intf.rx     axi4s_in  [NUM_PORTS],
    axi4s_intf.rx     axi4s_h2c [NUM_PORTS],
    axi4s_intf.tx     axi4s_out [NUM_PORTS],

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
                  .TUSER_WID(TUSER_WID), .TID_WID(TID_WID), .TDEST_WID(TDEST_WID))  mux_in  [NUM_PORTS][2] (.aclk(core_clk));

    axi4s_intf  #(.DATA_BYTE_WID(DATA_BYTE_WID),
                  .TUSER_WID(TUSER_WID), .TID_WID(TID_WID), .TDEST_WID(TDEST_WID))  mux_out [NUM_PORTS]    (.aclk(core_clk));

    generate for (genvar i = 0; i < NUM_PORTS; i += 1) begin
        axi4s_intf_pipe axi4s_mux_in_pipe_0 ( .srst, .from_tx(axi4s_in[i]),   .to_rx(mux_in[i][0]) );
        axi4s_intf_pipe axi4s_mux_in_pipe_1 ( .srst, .from_tx(_axi4s_out[i]), .to_rx(mux_in[i][1]) );

        axi4s_mux #(.N(2)) axi4s_mux_inst (
            .srst,
            .axi4s_in  (mux_in[i]),
            .axi4s_out (mux_out[i])
        );

        axi4s_full_pipe axis4s_full_pipe_inst (.srst, .from_tx(mux_out[i]), .to_rx(axi4s_out[i]));

    end endgenerate


    axi4s_intf #(.DATA_BYTE_WID(DATA_BYTE_WID), .TUSER_WID(TUSER_WID), .TID_WID(TID_WID), .TDEST_WID(TDEST_WID))
               axi4s_h2c_reg [NUM_PORTS] (.aclk(core_clk));
    axi4s_intf #(.DATA_BYTE_WID(DATA_BYTE_WID), .TUSER_WID(TUSER_WID), .TID_WID(TID_WID), .TDEST_WID(TDEST_WID))
               _axi4s_out [NUM_PORTS] (.aclk(core_clk));

    localparam int DATA_WID = DATA_BYTE_WID*8;
    localparam int COL_LEN  = 4096;

    rs_acc_intf #(.DATA_WID(DATA_WID), .COL_LEN(COL_LEN)) enc_in  [NUM_PORTS] (.clk(core_clk));
    rs_acc_intf #(.DATA_WID(DATA_WID), .COL_LEN(COL_LEN)) enc_out [NUM_PORTS] (.clk(core_clk));
    rs_acc_intf #(.DATA_WID(DATA_WID), .COL_LEN(COL_LEN)) col_out [NUM_PORTS] (.clk(core_clk));

    generate for (genvar i = 0; i < NUM_PORTS; i += 1) begin
        always_ff @(posedge core_clk) if (axi4s_h2c[i].tvalid && axi4s_h2c[i].tready) begin
            axi4s_h2c_reg[i].tkeep <= axi4s_h2c[i].tkeep;
            axi4s_h2c_reg[i].tid   <= axi4s_h2c[i].tid;
            axi4s_h2c_reg[i].tdest <= axi4s_h2c[i].tdest;
            axi4s_h2c_reg[i].tuser <= axi4s_h2c[i].tuser;
        end

        assign enc_in[i].data     = axi4s_h2c[i].tdata;
        assign enc_in[i].valid    = axi4s_h2c[i].tvalid;
        assign enc_in[i].blk_size = smartnic_app_egr_regs.app_egr_config.blk_size_enc;

        assign axi4s_h2c[i].tready = enc_in[i].ready;

        rs_acc_encode #(.DATA_WID(DATA_WID), .COL_LEN(COL_LEN)) rs_acc_encode_0 (
            .clk            (core_clk),
            .srst           (core_srst),
            .data_in        (enc_in[i]),
            .data_out       (enc_out[i])
        );

        fec_col_transpose #(
            .DATA_WID      (DATA_WID),
            .COL_WID       (SYM_SIZE),
            .COL_LEN       (COL_LEN),
            .MODE          (SYM_TO_BIT)
        ) fec_sym_to_bit_0 (
            .clk           (core_clk),
            .srst          (core_srst),
            .data_in       (enc_out[i]),
            .data_out      (col_out[i])
        );

        assign _axi4s_out[i].tdata  = col_out[i].data;
        assign _axi4s_out[i].tvalid = col_out[i].valid;
        assign _axi4s_out[i].tkeep  = axi4s_h2c_reg[i].tkeep;
        assign _axi4s_out[i].tid    = axi4s_h2c_reg[i].tid;
        assign _axi4s_out[i].tdest  = axi4s_h2c_reg[i].tdest;
        assign _axi4s_out[i].tuser  = axi4s_h2c_reg[i].tuser;
        assign _axi4s_out[i].tlast  = col_out[i].eos;

        assign col_out[i].ready = _axi4s_out[i].tready;

        //axi4s_full_pipe axis4s_full_pipe_inst (.srst, .from_tx(_axi4s_out[i]), .to_rx(axi4s_out[i]));

    end endgenerate

endmodule // smartnic_app_egr
