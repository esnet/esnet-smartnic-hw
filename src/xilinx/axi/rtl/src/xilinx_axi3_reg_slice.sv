module xilinx_axi3_reg_slice
    import xilinx_axi_pkg::*;
#(
    parameter int ADDR_WID  = 32,
    parameter int DATA_BYTE_WID = 32,
    parameter type ID_T = logic,
    parameter type USER_T = logic,
    parameter xilinx_axi_reg_slice_config_t CONFIG = XILINX_AXI_REG_SLICE_FULL,
    parameter string DEVICE_FAMILY = "virtexuplusHBM"
) (
    axi3_intf.peripheral axi3_if_from_controller,
    axi3_intf.controller axi3_if_to_peripheral
);

    function automatic int getResetPipeStages(input xilinx_axi_reg_slice_config_t _config);
        case (_config)
            XILINX_AXI_REG_SLICE_BYPASS,
            XILINX_AXI_REG_SLICE_REVERSE            : return 0;
            XILINX_AXI_REG_SLICE_SLR_CROSSING       : return 3;
            XILINX_AXI_REG_SLICE_MULTI_SLR_CROSSING : return 4;
            default                                 : return 1;
        endcase
    endfunction

    // Parameters
    localparam int DATA_WID   = DATA_BYTE_WID * 8;

    // Xilinx AXI-L register slice IP
    axi_register_slice_v2_1_30_axi_register_slice #(
        .C_FAMILY              ( DEVICE_FAMILY ),
        .C_AXI_PROTOCOL        ( XILINX_AXI_PROTOCOL_AXI3 ),
        .C_AXI_ID_WIDTH        ( $bits(ID_T) ),
        .C_AXI_ADDR_WIDTH      ( ADDR_WID ),
        .C_AXI_DATA_WIDTH      ( DATA_WID ),
        .C_AXI_SUPPORTS_USER_SIGNALS ( 1 ),
        .C_AXI_AWUSER_WIDTH    ( $bits(USER_T) ),
        .C_AXI_ARUSER_WIDTH    ( $bits(USER_T) ),
        .C_AXI_WUSER_WIDTH     ( $bits(USER_T) ),
        .C_AXI_RUSER_WIDTH     ( $bits(USER_T) ),
        .C_AXI_BUSER_WIDTH     ( $bits(USER_T) ),
        .C_REG_CONFIG_AW       ( CONFIG ),
        .C_REG_CONFIG_W        ( CONFIG ),
        .C_REG_CONFIG_B        ( CONFIG ),
        .C_REG_CONFIG_AR       ( CONFIG ),
        .C_REG_CONFIG_R        ( CONFIG ),
        .C_RESERVE_MODE        ( 0 ),
        .C_NUM_SLR_CROSSINGS   ( 0 ),
        .C_PIPELINES_MASTER_AW ( 0 ),
        .C_PIPELINES_MASTER_W  ( 0 ),
        .C_PIPELINES_MASTER_B  ( 0 ),
        .C_PIPELINES_MASTER_AR ( 0 ),
        .C_PIPELINES_MASTER_R  ( 0 ),
        .C_PIPELINES_SLAVE_AW  ( 0 ),
        .C_PIPELINES_SLAVE_W   ( 0 ),
        .C_PIPELINES_SLAVE_B   ( 0 ),
        .C_PIPELINES_SLAVE_AR  ( 0 ),
        .C_PIPELINES_SLAVE_R   ( 0 ),
        .C_PIPELINES_MIDDLE_AW ( 0 ),
        .C_PIPELINES_MIDDLE_W  ( 0 ),
        .C_PIPELINES_MIDDLE_B  ( 0 ),
        .C_PIPELINES_MIDDLE_AR ( 0 ),
        .C_PIPELINES_MIDDLE_R  ( 0 )
    ) inst (
        .aclk           ( axi3_if_from_controller.aclk ),
        .aclk2x         ( 1'b0 ),
        .aresetn        ( axi3_if_from_controller.aresetn ),
        .s_axi_awid     ( axi3_if_from_controller.awid ),
        .s_axi_awaddr   ( axi3_if_from_controller.awaddr ),
        .s_axi_awlen    ( axi3_if_from_controller.awlen ),
        .s_axi_awsize   ( axi3_if_from_controller.awsize ),
        .s_axi_awburst  ( axi3_if_from_controller.awburst ),
        .s_axi_awlock   ( axi3_if_from_controller.awlock ),
        .s_axi_awcache  ( axi3_if_from_controller.awcache ),
        .s_axi_awprot   ( axi3_if_from_controller.awprot ),
        .s_axi_awregion ( axi3_if_from_controller.awregion ),
        .s_axi_awqos    ( axi3_if_from_controller.awqos ),
        .s_axi_awuser   ( axi3_if_from_controller.awuser ),
        .s_axi_awvalid  ( axi3_if_from_controller.awvalid ),
        .s_axi_awready  ( axi3_if_from_controller.awready ),
        .s_axi_wid      ( axi3_if_from_controller.wid ),
        .s_axi_wdata    ( axi3_if_from_controller.wdata ),
        .s_axi_wstrb    ( axi3_if_from_controller.wstrb ),
        .s_axi_wlast    ( axi3_if_from_controller.wlast ),
        .s_axi_wuser    ( axi3_if_from_controller.wuser ),
        .s_axi_wvalid   ( axi3_if_from_controller.wvalid ),
        .s_axi_wready   ( axi3_if_from_controller.wready ),
        .s_axi_bid      ( axi3_if_from_controller.bid ),
        .s_axi_bresp    ( axi3_if_from_controller.bresp ),
        .s_axi_buser    ( axi3_if_from_controller.buser ),
        .s_axi_bvalid   ( axi3_if_from_controller.bvalid ),
        .s_axi_bready   ( axi3_if_from_controller.bready ),
        .s_axi_arid     ( axi3_if_from_controller.arid ),
        .s_axi_araddr   ( axi3_if_from_controller.araddr ),
        .s_axi_arlen    ( axi3_if_from_controller.arlen ),
        .s_axi_arsize   ( axi3_if_from_controller.arsize ),
        .s_axi_arburst  ( axi3_if_from_controller.arburst ),
        .s_axi_arlock   ( axi3_if_from_controller.arlock ),
        .s_axi_arcache  ( axi3_if_from_controller.arcache ),
        .s_axi_arprot   ( axi3_if_from_controller.arprot ),
        .s_axi_arregion ( axi3_if_from_controller.arregion ),
        .s_axi_arqos    ( axi3_if_from_controller.arqos ),
        .s_axi_aruser   ( axi3_if_from_controller.aruser ),
        .s_axi_arvalid  ( axi3_if_from_controller.arvalid ),
        .s_axi_arready  ( axi3_if_from_controller.arready ),
        .s_axi_rid      ( axi3_if_from_controller.rid ),
        .s_axi_rdata    ( axi3_if_from_controller.rdata ),
        .s_axi_rresp    ( axi3_if_from_controller.rresp ),
        .s_axi_rlast    ( axi3_if_from_controller.rlast ),
        .s_axi_ruser    ( axi3_if_from_controller.ruser ),
        .s_axi_rvalid   ( axi3_if_from_controller.rvalid ),
        .s_axi_rready   ( axi3_if_from_controller.rready ),
        .m_axi_awid     ( axi3_if_to_peripheral.awid ),
        .m_axi_awaddr   ( axi3_if_to_peripheral.awaddr ),
        .m_axi_awlen    ( axi3_if_to_peripheral.awlen ),
        .m_axi_awsize   ( axi3_if_to_peripheral.awsize ),
        .m_axi_awburst  ( axi3_if_to_peripheral.awburst ),
        .m_axi_awlock   ( axi3_if_to_peripheral.awlock ),
        .m_axi_awcache  ( axi3_if_to_peripheral.awcache ),
        .m_axi_awprot   ( axi3_if_to_peripheral.awprot ),
        .m_axi_awregion ( axi3_if_to_peripheral.awregion ),
        .m_axi_awqos    ( axi3_if_to_peripheral.awqos ),
        .m_axi_awuser   ( axi3_if_to_peripheral.awuser ),
        .m_axi_awvalid  ( axi3_if_to_peripheral.awvalid ),
        .m_axi_awready  ( axi3_if_to_peripheral.awready ),
        .m_axi_wid      ( axi3_if_to_peripheral.wid ),
        .m_axi_wdata    ( axi3_if_to_peripheral.wdata ),
        .m_axi_wstrb    ( axi3_if_to_peripheral.wstrb ),
        .m_axi_wlast    ( axi3_if_to_peripheral.wlast ),
        .m_axi_wuser    ( axi3_if_to_peripheral.wuser ),
        .m_axi_wvalid   ( axi3_if_to_peripheral.wvalid ),
        .m_axi_wready   ( axi3_if_to_peripheral.wready ),
        .m_axi_bid      ( axi3_if_to_peripheral.bid ),
        .m_axi_bresp    ( axi3_if_to_peripheral.bresp ),
        .m_axi_buser    ( axi3_if_to_peripheral.buser ),
        .m_axi_bvalid   ( axi3_if_to_peripheral.bvalid ),
        .m_axi_bready   ( axi3_if_to_peripheral.bready ),
        .m_axi_arid     ( axi3_if_to_peripheral.arid ),
        .m_axi_araddr   ( axi3_if_to_peripheral.araddr ),
        .m_axi_arlen    ( axi3_if_to_peripheral.arlen ),
        .m_axi_arsize   ( axi3_if_to_peripheral.arsize ),
        .m_axi_arburst  ( axi3_if_to_peripheral.arburst ),
        .m_axi_arlock   ( axi3_if_to_peripheral.arlock ),
        .m_axi_arcache  ( axi3_if_to_peripheral.arcache ),
        .m_axi_arprot   ( axi3_if_to_peripheral.arprot ),
        .m_axi_arregion ( axi3_if_to_peripheral.arregion ),
        .m_axi_arqos    ( axi3_if_to_peripheral.arqos ),
        .m_axi_aruser   ( axi3_if_to_peripheral.aruser ),
        .m_axi_arvalid  ( axi3_if_to_peripheral.arvalid ),
        .m_axi_arready  ( axi3_if_to_peripheral.arready ),
        .m_axi_rid      ( axi3_if_to_peripheral.rid ),
        .m_axi_rdata    ( axi3_if_to_peripheral.rdata ),
        .m_axi_rresp    ( axi3_if_to_peripheral.rresp ),
        .m_axi_rlast    ( axi3_if_to_peripheral.rlast ),
        .m_axi_ruser    ( axi3_if_to_peripheral.ruser ),
        .m_axi_rvalid   ( axi3_if_to_peripheral.rvalid ),
        .m_axi_rready   ( axi3_if_to_peripheral.rready )
    );

    // Assign clock
    assign axi3_if_to_peripheral.aclk = axi3_if_from_controller.aclk;

    // Pipeline reset
    util_pipe       #(
        .DATA_T      ( logic ),
        .PIPE_STAGES ( getResetPipeStages(CONFIG) )
    ) i_util_pipe_aresetn (
        .clk      ( axi3_if_to_peripheral.aclk ),
        .srst     ( 1'b0 ),
        .data_in  ( axi3_if_from_controller.aresetn ),
        .data_out ( axi3_if_to_peripheral.aresetn )
    );

endmodule : xilinx_axi3_reg_slice
