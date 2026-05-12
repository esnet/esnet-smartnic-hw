    // Clocks from BD
    input         clk_pl;
    input         clk_usr_0;
    input         clk_usr_1;

    // Resets from BD (active-low)
    input         resetn_pl_ic;
    input         resetn_pl_periph;
    input         resetn_usr_0_ic;
    input         resetn_usr_0_periph;
    input         resetn_usr_1_ic;
    input         resetn_usr_1_periph;

    // Management AXI4-Lite interface (BD master -> adapter slave)
    input  [31:0] m_axi_usr_mgmt_awaddr;
    input  [2:0]  m_axi_usr_mgmt_awprot;
    input         m_axi_usr_mgmt_awvalid;
    output        m_axi_usr_mgmt_awready;
    input  [31:0] m_axi_usr_mgmt_wdata;
    input  [3:0]  m_axi_usr_mgmt_wstrb;
    input         m_axi_usr_mgmt_wvalid;
    output        m_axi_usr_mgmt_wready;
    output [1:0]  m_axi_usr_mgmt_bresp;
    output        m_axi_usr_mgmt_bvalid;
    input         m_axi_usr_mgmt_bready;
    input  [31:0] m_axi_usr_mgmt_araddr;
    input  [2:0]  m_axi_usr_mgmt_arprot;
    input         m_axi_usr_mgmt_arvalid;
    output        m_axi_usr_mgmt_arready;
    output [31:0] m_axi_usr_mgmt_rdata;
    output [1:0]  m_axi_usr_mgmt_rresp;
    output        m_axi_usr_mgmt_rvalid;
    input         m_axi_usr_mgmt_rready;
