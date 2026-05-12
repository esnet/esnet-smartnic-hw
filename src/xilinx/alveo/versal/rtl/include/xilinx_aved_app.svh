    // Clocks from BD
    wire        clk_pl;
    wire        clk_usr_0;
    wire        clk_usr_1;

    // Resets from BD (active-low)
    wire        resetn_pl_ic;
    wire        resetn_pl_periph;
    wire        resetn_usr_0_ic;
    wire        resetn_usr_0_periph;
    wire        resetn_usr_1_ic;
    wire        resetn_usr_1_periph;

    // Management AXI4-Lite interface (BD master -> adapter slave)
    wire [31:0] m_axi_usr_mgmt_awaddr;
    wire [2:0]  m_axi_usr_mgmt_awprot;
    wire        m_axi_usr_mgmt_awvalid;
    wire        m_axi_usr_mgmt_awready;
    wire [31:0] m_axi_usr_mgmt_wdata;
    wire [3:0]  m_axi_usr_mgmt_wstrb;
    wire        m_axi_usr_mgmt_wvalid;
    wire        m_axi_usr_mgmt_wready;
    wire [1:0]  m_axi_usr_mgmt_bresp;
    wire        m_axi_usr_mgmt_bvalid;
    wire        m_axi_usr_mgmt_bready;
    wire [31:0] m_axi_usr_mgmt_araddr;
    wire [2:0]  m_axi_usr_mgmt_arprot;
    wire        m_axi_usr_mgmt_arvalid;
    wire        m_axi_usr_mgmt_arready;
    wire [31:0] m_axi_usr_mgmt_rdata;
    wire [1:0]  m_axi_usr_mgmt_rresp;
    wire        m_axi_usr_mgmt_rvalid;
    wire        m_axi_usr_mgmt_rready;

    // SMBus tristate signals (BD -> IOBUF)
    wire        smbus_0_scl_i;
    wire        smbus_0_scl_o;
    wire        smbus_0_scl_t;
    wire        smbus_0_sda_i;
    wire        smbus_0_sda_o;
    wire        smbus_0_sda_t;
