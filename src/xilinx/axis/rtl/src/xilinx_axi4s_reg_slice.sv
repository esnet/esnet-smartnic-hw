module xilinx_axi4s_reg_slice
    import xilinx_axis_pkg::*;
#(
    parameter xilinx_axis_reg_slice_config_t CONFIG = XILINX_AXIS_REG_SLICE_DEFAULT,
    parameter string DEVICE_FAMILY = "virtexuplusHBM"
) (
    axi4s_intf.rx from_tx,
    axi4s_intf.tx to_rx
);

    localparam int DATA_BYTE_WID = from_tx.DATA_BYTE_WID;
    localparam int TID_WID = from_tx.TID_WID;
    localparam int TDEST_WID = from_tx.TDEST_WID;
    localparam int TUSER_WID = from_tx.TUSER_WID;

    // Parameter check
    initial begin
        std_pkg::param_check(to_rx.DATA_BYTE_WID, DATA_BYTE_WID, "to_rx.DATA_BYTE_WID");
        std_pkg::param_check(to_rx.TID_WID,       TID_WID,       "to_rx.TID_WID");
        std_pkg::param_check(to_rx.TDEST_WID,     TDEST_WID,     "to_rx.TDEST_WID");
        std_pkg::param_check(to_rx.TUSER_WID,     TUSER_WID,     "to_rx.TUSER_WID");
    end

    function automatic int getResetPipeStages(input xilinx_axis_reg_slice_config_t _config);
        case (_config)
            XILINX_AXIS_REG_SLICE_BYPASS         : return 0;
            XILINX_AXIS_REG_SLICE_SLR_CROSSING   : return 3;
            XILINX_AXIS_REG_SLICE_AUTO_PIPELINED : return 4;
            default                              : return 1;
        endcase
    endfunction

    // Xilinx AXI-S register slice
    `AXIS_REGISTER_SLICE_MODULE_NAME #(
        .C_FAMILY            ( DEVICE_FAMILY ),
        .C_AXIS_TDATA_WIDTH  ( DATA_BYTE_WID*8 ),
        .C_AXIS_TID_WIDTH    ( TID_WID ),
        .C_AXIS_TDEST_WIDTH  ( TDEST_WID ),
        .C_AXIS_TUSER_WIDTH  ( TUSER_WID ),
        .C_AXIS_SIGNAL_SET   ( 32'b00000000000000000000000011111011 ), // No TSTRB
        .C_REG_CONFIG        ( CONFIG ),
        .C_NUM_SLR_CROSSINGS ( 0 ),
        .C_PIPELINES_MASTER  ( 0 ),
        .C_PIPELINES_SLAVE   ( 0 ),
        .C_PIPELINES_MIDDLE  ( 0 )
    ) inst (
        .aclk          ( from_tx.aclk ),
        .aclk2x        ( 1'b0 ),
        .aresetn       ( from_tx.aresetn ),
        .aclken        ( 1'b1 ),
        .s_axis_tvalid ( from_tx.tvalid ),
        .s_axis_tready ( from_tx.tready ),
        .s_axis_tdata  ( from_tx.tdata ),
        .s_axis_tstrb  ( '1 ),
        .s_axis_tkeep  ( from_tx.tkeep ),
        .s_axis_tlast  ( from_tx.tlast ),
        .s_axis_tid    ( from_tx.tid ),
        .s_axis_tdest  ( from_tx.tdest ),
        .s_axis_tuser  ( from_tx.tuser ),
        .m_axis_tvalid ( to_rx.tvalid ),
        .m_axis_tready ( to_rx.tready ),
        .m_axis_tdata  ( to_rx.tdata ),
        .m_axis_tstrb  ( ),
        .m_axis_tkeep  ( to_rx.tkeep ),
        .m_axis_tlast  ( to_rx.tlast ),
        .m_axis_tid    ( to_rx.tid ),
        .m_axis_tdest  ( to_rx.tdest ),
        .m_axis_tuser  ( to_rx.tuser)
    );

endmodule : xilinx_axi4s_reg_slice
