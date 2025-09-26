module xilinx_axi3_reg_slice
    import xilinx_axi_pkg::*;
#(
    parameter xilinx_axi_reg_slice_config_t CONFIG = XILINX_AXI_REG_SLICE_FULL,
    parameter string DEVICE_FAMILY = "virtexuplusHBM"
) (
    axi3_intf.peripheral from_controller,
    axi3_intf.controller to_peripheral
);
    // Parameters
    localparam int ADDR_WID      = from_controller.ADDR_WID;
    localparam int DATA_BYTE_WID = from_controller.DATA_BYTE_WID;
    localparam int ID_WID        = from_controller.ID_WID;
    localparam int USER_WID      = from_controller.USER_WID;
    
    // Parameter check
    initial begin
        std_pkg::param_check(to_peripheral.DATA_BYTE_WID, DATA_BYTE_WID, "to_peripheral.DATA_BYTE_WID");
        std_pkg::param_check(to_peripheral.ADDR_WID,      ADDR_WID,      "to_peripheral.ADDR_WID");
        std_pkg::param_check(to_peripheral.ID_WID,        ID_WID,        "to_peripheral.ID_WID");
        std_pkg::param_check(to_peripheral.USER_WID,      USER_WID,      "to_peripheral.USER_WID");
    end

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
    localparam int DATA_WID = DATA_BYTE_WID * 8;

    // Xilinx AXI-L register slice IP
    `AXI_REGISTER_SLICE_MODULE_NAME #(
        .C_FAMILY              ( DEVICE_FAMILY ),
        .C_AXI_PROTOCOL        ( XILINX_AXI_PROTOCOL_AXI3 ),
        .C_AXI_ID_WIDTH        ( ID_WID ),
        .C_AXI_ADDR_WIDTH      ( ADDR_WID ),
        .C_AXI_DATA_WIDTH      ( DATA_WID ),
        .C_AXI_SUPPORTS_USER_SIGNALS ( 1 ),
        .C_AXI_AWUSER_WIDTH    ( USER_WID ),
        .C_AXI_ARUSER_WIDTH    ( USER_WID ),
        .C_AXI_WUSER_WIDTH     ( USER_WID ),
        .C_AXI_RUSER_WIDTH     ( USER_WID ),
        .C_AXI_BUSER_WIDTH     ( USER_WID ),
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
        .aclk           ( from_controller.aclk ),
        .aclk2x         ( 1'b0 ),
        .aresetn        ( from_controller.aresetn ),
        .s_axi_awid     ( from_controller.awid ),
        .s_axi_awaddr   ( from_controller.awaddr ),
        .s_axi_awlen    ( from_controller.awlen ),
        .s_axi_awsize   ( from_controller.awsize ),
        .s_axi_awburst  ( from_controller.awburst ),
        .s_axi_awlock   ( from_controller.awlock ),
        .s_axi_awcache  ( from_controller.awcache ),
        .s_axi_awprot   ( from_controller.awprot ),
        .s_axi_awregion ( from_controller.awregion ),
        .s_axi_awqos    ( from_controller.awqos ),
        .s_axi_awuser   ( from_controller.awuser ),
        .s_axi_awvalid  ( from_controller.awvalid ),
        .s_axi_awready  ( from_controller.awready ),
        .s_axi_wid      ( from_controller.wid ),
        .s_axi_wdata    ( from_controller.wdata ),
        .s_axi_wstrb    ( from_controller.wstrb ),
        .s_axi_wlast    ( from_controller.wlast ),
        .s_axi_wuser    ( from_controller.wuser ),
        .s_axi_wvalid   ( from_controller.wvalid ),
        .s_axi_wready   ( from_controller.wready ),
        .s_axi_bid      ( from_controller.bid ),
        .s_axi_bresp    ( from_controller.bresp ),
        .s_axi_buser    ( from_controller.buser ),
        .s_axi_bvalid   ( from_controller.bvalid ),
        .s_axi_bready   ( from_controller.bready ),
        .s_axi_arid     ( from_controller.arid ),
        .s_axi_araddr   ( from_controller.araddr ),
        .s_axi_arlen    ( from_controller.arlen ),
        .s_axi_arsize   ( from_controller.arsize ),
        .s_axi_arburst  ( from_controller.arburst ),
        .s_axi_arlock   ( from_controller.arlock ),
        .s_axi_arcache  ( from_controller.arcache ),
        .s_axi_arprot   ( from_controller.arprot ),
        .s_axi_arregion ( from_controller.arregion ),
        .s_axi_arqos    ( from_controller.arqos ),
        .s_axi_aruser   ( from_controller.aruser ),
        .s_axi_arvalid  ( from_controller.arvalid ),
        .s_axi_arready  ( from_controller.arready ),
        .s_axi_rid      ( from_controller.rid ),
        .s_axi_rdata    ( from_controller.rdata ),
        .s_axi_rresp    ( from_controller.rresp ),
        .s_axi_rlast    ( from_controller.rlast ),
        .s_axi_ruser    ( from_controller.ruser ),
        .s_axi_rvalid   ( from_controller.rvalid ),
        .s_axi_rready   ( from_controller.rready ),
        .m_axi_awid     ( to_peripheral.awid ),
        .m_axi_awaddr   ( to_peripheral.awaddr ),
        .m_axi_awlen    ( to_peripheral.awlen ),
        .m_axi_awsize   ( to_peripheral.awsize ),
        .m_axi_awburst  ( to_peripheral.awburst ),
        .m_axi_awlock   ( to_peripheral.awlock ),
        .m_axi_awcache  ( to_peripheral.awcache ),
        .m_axi_awprot   ( to_peripheral.awprot ),
        .m_axi_awregion ( to_peripheral.awregion ),
        .m_axi_awqos    ( to_peripheral.awqos ),
        .m_axi_awuser   ( to_peripheral.awuser ),
        .m_axi_awvalid  ( to_peripheral.awvalid ),
        .m_axi_awready  ( to_peripheral.awready ),
        .m_axi_wid      ( to_peripheral.wid ),
        .m_axi_wdata    ( to_peripheral.wdata ),
        .m_axi_wstrb    ( to_peripheral.wstrb ),
        .m_axi_wlast    ( to_peripheral.wlast ),
        .m_axi_wuser    ( to_peripheral.wuser ),
        .m_axi_wvalid   ( to_peripheral.wvalid ),
        .m_axi_wready   ( to_peripheral.wready ),
        .m_axi_bid      ( to_peripheral.bid ),
        .m_axi_bresp    ( to_peripheral.bresp ),
        .m_axi_buser    ( to_peripheral.buser ),
        .m_axi_bvalid   ( to_peripheral.bvalid ),
        .m_axi_bready   ( to_peripheral.bready ),
        .m_axi_arid     ( to_peripheral.arid ),
        .m_axi_araddr   ( to_peripheral.araddr ),
        .m_axi_arlen    ( to_peripheral.arlen ),
        .m_axi_arsize   ( to_peripheral.arsize ),
        .m_axi_arburst  ( to_peripheral.arburst ),
        .m_axi_arlock   ( to_peripheral.arlock ),
        .m_axi_arcache  ( to_peripheral.arcache ),
        .m_axi_arprot   ( to_peripheral.arprot ),
        .m_axi_arregion ( to_peripheral.arregion ),
        .m_axi_arqos    ( to_peripheral.arqos ),
        .m_axi_aruser   ( to_peripheral.aruser ),
        .m_axi_arvalid  ( to_peripheral.arvalid ),
        .m_axi_arready  ( to_peripheral.arready ),
        .m_axi_rid      ( to_peripheral.rid ),
        .m_axi_rdata    ( to_peripheral.rdata ),
        .m_axi_rresp    ( to_peripheral.rresp ),
        .m_axi_rlast    ( to_peripheral.rlast ),
        .m_axi_ruser    ( to_peripheral.ruser ),
        .m_axi_rvalid   ( to_peripheral.rvalid ),
        .m_axi_rready   ( to_peripheral.rready )
    );

endmodule : xilinx_axi3_reg_slice
