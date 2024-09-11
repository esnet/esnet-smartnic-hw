module xilinx_axi4s_reg_slice
    import xilinx_axis_pkg::*;
#(
    parameter int  DATA_BYTE_WID = 8,
    parameter type TID_T = logic,
    parameter type TDEST_T = logic,
    parameter type TUSER_T = logic,
    parameter xilinx_axis_reg_slice_config_t CONFIG = XILINX_AXIS_REG_SLICE_DEFAULT,
    parameter string DEVICE_FAMILY = "virtexuplusHBM"
) (
    axi4s_intf.rx axi4s_from_tx,
    axi4s_intf.tx axi4s_to_rx
);

    function automatic int getResetPipeStages(input xilinx_axis_reg_slice_config_t _config);
        case (_config)
            XILINX_AXIS_REG_SLICE_BYPASS         : return 0;
            XILINX_AXIS_REG_SLICE_SLR_CROSSING   : return 3;
            XILINX_AXIS_REG_SLICE_AUTO_PIPELINED : return 4;
            default                              : return 1;
        endcase
    endfunction

    // Xilinx AXI-S register slice
    axis_register_slice_v1_1_29_axis_register_slice #(
        .C_FAMILY            ( DEVICE_FAMILY ),
        .C_AXIS_TDATA_WIDTH  ( DATA_BYTE_WID*8 ),
        .C_AXIS_TID_WIDTH    ( $bits(TID_T) ),
        .C_AXIS_TDEST_WIDTH  ( $bits(TDEST_T) ),
        .C_AXIS_TUSER_WIDTH  ( $bits(TUSER_T) ),
        .C_AXIS_SIGNAL_SET   ( 32'b00000000000000000000000011111011 ), // No TSTRB
        .C_REG_CONFIG        ( CONFIG ),
        .C_NUM_SLR_CROSSINGS ( 0 ),
        .C_PIPELINES_MASTER  ( 0 ),
        .C_PIPELINES_SLAVE   ( 0 ),
        .C_PIPELINES_MIDDLE  ( 0 )
    ) inst (
        .aclk          ( axi4s_from_tx.aclk ),
        .aclk2x        ( 1'b0 ),
        .aresetn       ( axi4s_from_tx.aresetn ),
        .aclken        ( 1'b1 ),
        .s_axis_tvalid ( axi4s_from_tx.tvalid ),
        .s_axis_tready ( axi4s_from_tx.tready ),
        .s_axis_tdata  ( axi4s_from_tx.tdata ),
        .s_axis_tstrb  ( '1 ),
        .s_axis_tkeep  ( axi4s_from_tx.tkeep ),
        .s_axis_tlast  ( axi4s_from_tx.tlast ),
        .s_axis_tid    ( axi4s_from_tx.tid ),
        .s_axis_tdest  ( axi4s_from_tx.tdest ),
        .s_axis_tuser  ( axi4s_from_tx.tuser ),
        .m_axis_tvalid ( axi4s_to_rx.tvalid ),
        .m_axis_tready ( axi4s_to_rx.tready ),
        .m_axis_tdata  ( axi4s_to_rx.tdata ),
        .m_axis_tstrb  ( ),
        .m_axis_tkeep  ( axi4s_to_rx.tkeep ),
        .m_axis_tlast  ( axi4s_to_rx.tlast ),
        .m_axis_tid    ( axi4s_to_rx.tid ),
        .m_axis_tdest  ( axi4s_to_rx.tdest ),
        .m_axis_tuser  ( axi4s_to_rx.tuser)
    );

    assign axi4s_to_rx.aclk = axi4s_from_tx.aclk;

    // Pipeline reset
    util_pipe       #(
        .DATA_T      ( logic ),
        .PIPE_STAGES ( getResetPipeStages(CONFIG) )
    ) i_util_pipe_aresetn (
        .clk      ( axi4s_to_rx.aclk ),
        .srst     ( 1'b0 ),
        .data_in  ( axi4s_from_tx.aresetn ),
        .data_out ( axi4s_to_rx.aresetn )
    );


endmodule : xilinx_axi4s_reg_slice
