module smartnic_hash2qid #(
    parameter int  DATA_BYTE_WID = 8,
    parameter type TID_T   = logic,
    parameter type TDEST_T = logic,
    parameter type TUSER_T = logic
) (
    input logic    core_clk,
    input logic    core_rstn,

    axi4s_intf.rx  axi4s_in,
    axi4s_intf.tx  axi4s_out,

    axi4l_intf.peripheral  axil_if
);
    import smartnic_pkg::*;

    // ----------------------------------------------------------------
    //  axi4l interface instantiations
    // ----------------------------------------------------------------

    // axi4l interface synchronizer
    axi4l_intf axil__core_clk ();

    axi4l_intf_cdc axil_cdc (
        .axi4l_if_from_controller  ( axil_if ),
        .clk_to_peripheral         ( core_clk ),
        .axi4l_if_to_peripheral    ( axil__core_clk )
    );

    // smartnic_hash2qid register block
    smartnic_hash2qid_reg_intf   smartnic_hash2qid_regs ();
                              
    smartnic_hash2qid_reg_blk smartnic_hash2qid_reg_blk_0 (
        .axil_if    (axil__core_clk),
        .reg_blk_if (smartnic_hash2qid_regs)
    );


    axi4s_intf  #(.DATA_BYTE_WID(DATA_BYTE_WID), .TID_T(TID_T), .TDEST_T(TDEST_T), .TUSER_T(TUSER_T))  axi4s_in_p1 ();
    axi4s_intf  #(.DATA_BYTE_WID(DATA_BYTE_WID), .TID_T(TID_T), .TDEST_T(TDEST_T), .TUSER_T(TUSER_T))  axi4s_in_p2 ();
    axi4s_intf  #(.DATA_BYTE_WID(DATA_BYTE_WID), .TID_T(TID_T), .TDEST_T(TDEST_T), .TUSER_T(TUSER_T))  axi4s_in_p3 ();


    // -- pipe stage 1 --
    logic [11:0] pf_table_qid, vf0_table_qid, vf1_table_qid, vf2_table_qid;
    always @(posedge core_clk) begin
         pf_table_qid <= smartnic_hash2qid_regs.pf_table [axi4s_in.tuser.rss_entropy[6:0]];
        vf0_table_qid <= smartnic_hash2qid_regs.vf0_table[axi4s_in.tuser.rss_entropy[6:0]];
        vf1_table_qid <= smartnic_hash2qid_regs.vf1_table[axi4s_in.tuser.rss_entropy[6:0]];
        vf2_table_qid <= smartnic_hash2qid_regs.vf2_table[axi4s_in.tuser.rss_entropy[6:0]];
    end

    axi4s_intf_pipe axi4s_in_pipe_1 (.axi4s_if_from_tx(axi4s_in),    .axi4s_if_to_rx(axi4s_in_p1));


    // -- pipe stage 2 --
    // extract host_if_id from top bits of tuser.rss_entropy.
    h2c_t host_if_id;
    assign host_if_id = axi4s_in_p1.tuser.rss_entropy[11:10];

    logic [11:0] qid, base;

    always @(posedge core_clk) begin
        if (!axi4s_in_p1.tuser.rss_enable)
            qid <=  '0;
        else case (host_if_id)
            H2C_PF  : qid <=  pf_table_qid;
            H2C_VF0 : qid <= vf0_table_qid;
            H2C_VF1 : qid <= vf1_table_qid;
            H2C_VF2 : qid <= vf2_table_qid;
        endcase

        base <= smartnic_hash2qid_regs.q_config[host_if_id];
    end

    axi4s_intf_pipe axi4s_in_pipe_2 (.axi4s_if_from_tx(axi4s_in_p1), .axi4s_if_to_rx(axi4s_in_p2));


    // -- pipe stage 3 --
    logic [11:0] rss_entropy;
    always @(posedge core_clk) rss_entropy <= qid + base;

    axi4s_intf_pipe axi4s_in_pipe_3 (.axi4s_if_from_tx(axi4s_in_p2), .axi4s_if_to_rx(axi4s_in_p3));


    // -- output stage --
    assign axi4s_in_p3.tready = axi4s_out.tready;

    assign axi4s_out.aclk    = axi4s_in_p3.aclk;
    assign axi4s_out.aresetn = axi4s_in_p3.aresetn;
    assign axi4s_out.tvalid  = axi4s_in_p3.tvalid;
    assign axi4s_out.tdata   = axi4s_in_p3.tdata;
    assign axi4s_out.tkeep   = axi4s_in_p3.tkeep;
    assign axi4s_out.tlast   = axi4s_in_p3.tlast;
    assign axi4s_out.tid     = axi4s_in_p3.tid;
    assign axi4s_out.tdest   = axi4s_in_p3.tdest;

    // overwrite tuser.rss_entropy with qid.
    always_comb begin
        axi4s_out.tuser             = axi4s_in_p3.tuser;
        axi4s_out.tuser.rss_enable  = 1'b1;
        axi4s_out.tuser.rss_entropy = rss_entropy;
    end

endmodule // smartnic_hash2qid
