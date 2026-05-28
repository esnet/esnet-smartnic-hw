module xilinx_aved_adapter (
    // Clocks and resets from AVED BD
    input  wire        clk_pl,
    input  wire        resetn_pl_periph,

    // Management AXI4-Lite (BD master -> adapter slave)
    input  wire [31:0] m_axi_usr_mgmt_awaddr,
    input  wire [2:0]  m_axi_usr_mgmt_awprot,
    input  wire        m_axi_usr_mgmt_awvalid,
    output wire        m_axi_usr_mgmt_awready,
    input  wire [31:0] m_axi_usr_mgmt_wdata,
    input  wire [3:0]  m_axi_usr_mgmt_wstrb,
    input  wire        m_axi_usr_mgmt_wvalid,
    output wire        m_axi_usr_mgmt_wready,
    output wire [1:0]  m_axi_usr_mgmt_bresp,
    output wire        m_axi_usr_mgmt_bvalid,
    input  wire        m_axi_usr_mgmt_bready,
    input  wire [31:0] m_axi_usr_mgmt_araddr,
    input  wire [2:0]  m_axi_usr_mgmt_arprot,
    input  wire        m_axi_usr_mgmt_arvalid,
    output wire        m_axi_usr_mgmt_arready,
    output wire [31:0] m_axi_usr_mgmt_rdata,
    output wire [1:0]  m_axi_usr_mgmt_rresp,
    output wire        m_axi_usr_mgmt_rvalid,
    input  wire        m_axi_usr_mgmt_rready,

    // AXI4-Lite controller output (carries clk/reset via aclk/aresetn)
    axi4l_intf.controller axil_if
);
    // Vivado SmartConnect delivers the absolute address (lower 32 bits) to
    // the slave port rather than the aperture-relative offset.  Strip the
    // base by masking to the M04 usr_mgmt aperture size (8 MB = 23 bits).
    localparam int USR_MGMT_APERTURE_BITS = 23;

    wire [31:0] awaddr_offset = {{(32-USR_MGMT_APERTURE_BITS){1'b0}},
                                  m_axi_usr_mgmt_awaddr[USR_MGMT_APERTURE_BITS-1:0]};
    wire [31:0] araddr_offset = {{(32-USR_MGMT_APERTURE_BITS){1'b0}},
                                  m_axi_usr_mgmt_araddr[USR_MGMT_APERTURE_BITS-1:0]};

    axi4l_intf_from_signals i_axi4l_intf_from_signals (
        .aclk     ( clk_pl                   ),
        .aresetn  ( resetn_pl_periph         ),
        .awvalid  ( m_axi_usr_mgmt_awvalid  ),
        .awready  ( m_axi_usr_mgmt_awready  ),
        .awaddr   ( awaddr_offset            ),
        .awprot   ( m_axi_usr_mgmt_awprot   ),
        .wvalid   ( m_axi_usr_mgmt_wvalid   ),
        .wready   ( m_axi_usr_mgmt_wready   ),
        .wdata    ( m_axi_usr_mgmt_wdata    ),
        .wstrb    ( m_axi_usr_mgmt_wstrb    ),
        .bvalid   ( m_axi_usr_mgmt_bvalid   ),
        .bready   ( m_axi_usr_mgmt_bready   ),
        .bresp    ( m_axi_usr_mgmt_bresp    ),
        .arvalid  ( m_axi_usr_mgmt_arvalid  ),
        .arready  ( m_axi_usr_mgmt_arready  ),
        .araddr   ( araddr_offset            ),
        .arprot   ( m_axi_usr_mgmt_arprot   ),
        .rvalid   ( m_axi_usr_mgmt_rvalid   ),
        .rready   ( m_axi_usr_mgmt_rready   ),
        .rdata    ( m_axi_usr_mgmt_rdata    ),
        .rresp    ( m_axi_usr_mgmt_rresp    ),
        .axi4l_if ( axil_if                 )
    );

endmodule : xilinx_aved_adapter
