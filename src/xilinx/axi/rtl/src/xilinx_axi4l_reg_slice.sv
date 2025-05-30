module xilinx_axi4l_reg_slice
    import axi4l_pkg::*;
    import xilinx_axi_pkg::*;
#(
    parameter int ADDR_WID  = 32,
    parameter axi4l_bus_width_t BUS_WIDTH = AXI4L_BUS_WIDTH_32,
    parameter xilinx_axi_reg_slice_config_t CONFIG = XILINX_AXI_REG_SLICE_LIGHT,
    parameter string DEVICE_FAMILY = "virtexuplusHBM"
) (
    axi4l_intf.peripheral axi4l_if_from_controller,
    axi4l_intf.controller axi4l_if_to_peripheral
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
    localparam int DATA_WID = 8*get_axi4l_bus_width_in_bytes(BUS_WIDTH);

    // Xilinx AXI-L register slice IP
    `AXI_REGISTER_SLICE_MODULE_NAME #(
        .C_FAMILY              ( DEVICE_FAMILY ),
        .C_AXI_PROTOCOL        ( XILINX_AXI_PROTOCOL_AXI4L ),
        .C_AXI_ID_WIDTH        ( 1 ),
        .C_AXI_ADDR_WIDTH      ( ADDR_WID ),
        .C_AXI_DATA_WIDTH      ( DATA_WID ),
        .C_AXI_SUPPORTS_USER_SIGNALS ( 0 ),
        .C_AXI_AWUSER_WIDTH    ( 1 ),
        .C_AXI_ARUSER_WIDTH    ( 1 ),
        .C_AXI_WUSER_WIDTH     ( 1 ),
        .C_AXI_RUSER_WIDTH     ( 1 ),
        .C_AXI_BUSER_WIDTH     ( 1 ),
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
        .aclk           ( axi4l_if_from_controller.aclk ),
        .aclk2x         ( 1'b0 ),
        .aresetn        ( axi4l_if_from_controller.aresetn ),
        .s_axi_awid     ( 1'b0 ),
        .s_axi_awaddr   ( axi4l_if_from_controller.awaddr ),
        .s_axi_awlen    ( 8'b0 ),
        .s_axi_awsize   ( 3'h00000002 ),
        .s_axi_awburst  ( 2'b1 ),
        .s_axi_awlock   ( 1'b0 ),
        .s_axi_awcache  ( 4'b0 ),
        .s_axi_awprot   ( axi4l_if_from_controller.awprot ),
        .s_axi_awregion ( 4'b0 ),
        .s_axi_awqos    ( 4'b0 ),
        .s_axi_awuser   ( 1'b0 ),
        .s_axi_awvalid  ( axi4l_if_from_controller.awvalid ),
        .s_axi_awready  ( axi4l_if_from_controller.awready ),
        .s_axi_wid      ( 1'b0 ),
        .s_axi_wdata    ( axi4l_if_from_controller.wdata ),
        .s_axi_wstrb    ( axi4l_if_from_controller.wstrb ),
        .s_axi_wlast    ( 1'b0 ),
        .s_axi_wuser    ( 1'b0 ),
        .s_axi_wvalid   ( axi4l_if_from_controller.wvalid ),
        .s_axi_wready   ( axi4l_if_from_controller.wready ),
        .s_axi_bid      (  ),
        .s_axi_bresp    ( axi4l_if_from_controller.bresp ),
        .s_axi_buser    (  ),
        .s_axi_bvalid   ( axi4l_if_from_controller.bvalid ),
        .s_axi_bready   ( axi4l_if_from_controller.bready ),
        .s_axi_arid     ( 1'b0 ),
        .s_axi_araddr   ( axi4l_if_from_controller.araddr ),
        .s_axi_arlen    ( 8'b0 ),
        .s_axi_arsize   ( 3'h00000002 ),
        .s_axi_arburst  ( 2'b1 ),
        .s_axi_arlock   ( 1'b0 ),
        .s_axi_arcache  ( 4'b0 ),
        .s_axi_arprot   ( axi4l_if_from_controller.arprot ),
        .s_axi_arregion ( 4'b0 ),
        .s_axi_arqos    ( 4'b0 ),
        .s_axi_aruser   ( 1'b0 ),
        .s_axi_arvalid  ( axi4l_if_from_controller.arvalid ),
        .s_axi_arready  ( axi4l_if_from_controller.arready ),
        .s_axi_rid      (  ),
        .s_axi_rdata    ( axi4l_if_from_controller.rdata ),
        .s_axi_rresp    ( axi4l_if_from_controller.rresp ),
        .s_axi_rlast    (  ),
        .s_axi_ruser    (  ),
        .s_axi_rvalid   ( axi4l_if_from_controller.rvalid ),
        .s_axi_rready   ( axi4l_if_from_controller.rready ),
        .m_axi_awid     (  ),
        .m_axi_awaddr   ( axi4l_if_to_peripheral.awaddr ),
        .m_axi_awlen    (  ),
        .m_axi_awsize   (  ),
        .m_axi_awburst  (  ),
        .m_axi_awlock   (  ),
        .m_axi_awcache  (  ),
        .m_axi_awprot   ( axi4l_if_to_peripheral.awprot ),
        .m_axi_awregion (  ),
        .m_axi_awqos    (  ),
        .m_axi_awuser   (  ),
        .m_axi_awvalid  ( axi4l_if_to_peripheral.awvalid ),
        .m_axi_awready  ( axi4l_if_to_peripheral.awready ),
        .m_axi_wid      (  ),
        .m_axi_wdata    ( axi4l_if_to_peripheral.wdata ),
        .m_axi_wstrb    ( axi4l_if_to_peripheral.wstrb ),
        .m_axi_wlast    (  ),
        .m_axi_wuser    (  ),
        .m_axi_wvalid   ( axi4l_if_to_peripheral.wvalid ),
        .m_axi_wready   ( axi4l_if_to_peripheral.wready ),
        .m_axi_bid      ( 1'b0 ),
        .m_axi_bresp    ( axi4l_if_to_peripheral.bresp ),
        .m_axi_buser    ( 1'b0 ),
        .m_axi_bvalid   ( axi4l_if_to_peripheral.bvalid ),
        .m_axi_bready   ( axi4l_if_to_peripheral.bready ),
        .m_axi_arid     (  ),
        .m_axi_araddr   ( axi4l_if_to_peripheral.araddr ),
        .m_axi_arlen    (  ),
        .m_axi_arsize   (  ),
        .m_axi_arburst  (  ),
        .m_axi_arlock   (  ),
        .m_axi_arcache  (  ),
        .m_axi_arprot   ( axi4l_if_to_peripheral.arprot ),
        .m_axi_arregion (  ),
        .m_axi_arqos    (  ),
        .m_axi_aruser   (  ),
        .m_axi_arvalid  ( axi4l_if_to_peripheral.arvalid ),
        .m_axi_arready  ( axi4l_if_to_peripheral.arready ),
        .m_axi_rid      ( 1'b0 ),
        .m_axi_rdata    ( axi4l_if_to_peripheral.rdata ),
        .m_axi_rresp    ( axi4l_if_to_peripheral.rresp ),
        .m_axi_rlast    ( 1'b0 ),
        .m_axi_ruser    ( 1'b0 ),
        .m_axi_rvalid   ( axi4l_if_to_peripheral.rvalid ),
        .m_axi_rready   ( axi4l_if_to_peripheral.rready )
    );

    // Assign clock
    assign axi4l_if_to_peripheral.aclk = axi4l_if_from_controller.aclk;

    // Pipeline reset
    util_pipe       #(
        .DATA_T      ( logic ),
        .PIPE_STAGES ( getResetPipeStages(CONFIG) )
    ) i_util_pipe_aresetn (
        .clk      ( axi4l_if_to_peripheral.aclk ),
        .srst     ( 1'b0 ),
        .data_in  ( axi4l_if_from_controller.aresetn ),
        .data_out ( axi4l_if_to_peripheral.aresetn )
    );

endmodule : xilinx_axi4l_reg_slice
