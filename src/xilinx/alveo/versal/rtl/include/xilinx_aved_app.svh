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

    // PCIE0 clock (from BD)
    wire        clk_pcie0;

    // PCIE0 raw reset sources (from BD, active-low outputs)
    wire        aresetn_pl0;          // PS global reset
    wire        aresetn_pcie0_link;   // CPM5 PCIE0 link reset (dma0_axi_aresetn)

    // Shell-facing signals — functional names exposed at esnet_smartnic boundary.
    // xilinx_aved_adapter maps these to/from AVED BD port names internally.
    wire        sys_clk;       // system/debug clock
    wire        pcie_clk;      // PCIe interface clock
    wire        pcie_rstn_in;  // combined pre-JTAG reset (active-low)
    wire        pcie_rstn;     // post-JTAG synthesised reset (active-low)

    // PCIE0 raw AXI4 master (BD → user RTL slave, 512-bit data)
    // Signal widths taken from the Vivado-generated BD wrapper.
    wire [63:0]  m_axi_pcie0_awaddr;
    wire [1:0]   m_axi_pcie0_awid;
    wire [7:0]   m_axi_pcie0_awlen;
    wire [2:0]   m_axi_pcie0_awsize;
    wire [1:0]   m_axi_pcie0_awburst;
    wire         m_axi_pcie0_awlock;
    wire [3:0]   m_axi_pcie0_awcache;
    wire [2:0]   m_axi_pcie0_awprot;
    wire [3:0]   m_axi_pcie0_awqos;
    wire [3:0]   m_axi_pcie0_awregion;
    wire [17:0]  m_axi_pcie0_awuser;
    wire         m_axi_pcie0_awvalid;
    wire         m_axi_pcie0_awready;
    wire [511:0] m_axi_pcie0_wdata;
    wire [63:0]  m_axi_pcie0_wstrb;
    wire         m_axi_pcie0_wlast;
    wire         m_axi_pcie0_wvalid;
    wire         m_axi_pcie0_wready;
    wire [1:0]   m_axi_pcie0_bid;
    wire [1:0]   m_axi_pcie0_bresp;
    wire         m_axi_pcie0_bvalid;
    wire         m_axi_pcie0_bready;
    wire [63:0]  m_axi_pcie0_araddr;
    wire [1:0]   m_axi_pcie0_arid;
    wire [7:0]   m_axi_pcie0_arlen;
    wire [2:0]   m_axi_pcie0_arsize;
    wire [1:0]   m_axi_pcie0_arburst;
    wire         m_axi_pcie0_arlock;
    wire [3:0]   m_axi_pcie0_arcache;
    wire [2:0]   m_axi_pcie0_arprot;
    wire [3:0]   m_axi_pcie0_arqos;
    wire [3:0]   m_axi_pcie0_arregion;
    wire [17:0]  m_axi_pcie0_aruser;
    wire         m_axi_pcie0_arvalid;
    wire         m_axi_pcie0_arready;
    wire [511:0] m_axi_pcie0_rdata;
    wire [1:0]   m_axi_pcie0_rid;
    wire [1:0]   m_axi_pcie0_rresp;
    wire         m_axi_pcie0_rlast;
    wire         m_axi_pcie0_rvalid;
    wire         m_axi_pcie0_rready;

    // PCIE0 H2C stream (BD master → user logic)
    wire         dma0_m_axis_h2c_0_tvalid;
    wire [511:0] dma0_m_axis_h2c_0_tdata;
    wire         dma0_m_axis_h2c_0_tlast;
    wire         dma0_m_axis_h2c_0_tready;
    wire [11:0]  dma0_m_axis_h2c_0_qid;
    wire [2:0]   dma0_m_axis_h2c_0_port_id;
    wire [31:0]  dma0_m_axis_h2c_0_mdata;
    wire [5:0]   dma0_m_axis_h2c_0_mty;
    wire [31:0]  dma0_m_axis_h2c_0_tcrc;
    wire         dma0_m_axis_h2c_0_err;
    wire         dma0_m_axis_h2c_0_zero_byte;

    // PCIE0 C2H stream (user logic → BD slave)
    wire         dma0_s_axis_c2h_0_tvalid;
    wire [511:0] dma0_s_axis_c2h_0_tdata;
    wire         dma0_s_axis_c2h_0_tlast;
    wire         dma0_s_axis_c2h_0_tready;
    wire [11:0]  dma0_s_axis_c2h_0_ctrl_qid;
    wire [15:0]  dma0_s_axis_c2h_0_ctrl_len;
    wire [2:0]   dma0_s_axis_c2h_0_ctrl_port_id;
    wire         dma0_s_axis_c2h_0_ctrl_has_cmpt;
    wire         dma0_s_axis_c2h_0_ctrl_marker;
    wire [5:0]   dma0_s_axis_c2h_0_mty;
    wire [6:0]   dma0_s_axis_c2h_0_ecc;
    wire [31:0]  dma0_s_axis_c2h_0_tcrc;

    // PCIE0 C2H completion write-back (user logic → BD slave)
    wire         dma0_s_axis_c2h_cmpt_0_tvalid;
    wire [511:0] dma0_s_axis_c2h_cmpt_0_data;
    wire [1:0]   dma0_s_axis_c2h_cmpt_0_size;
    wire [11:0]  dma0_s_axis_c2h_cmpt_0_qid;
    wire [2:0]   dma0_s_axis_c2h_cmpt_0_port_id;
    wire [1:0]   dma0_s_axis_c2h_cmpt_0_cmpt_type;
    wire [15:0]  dma0_s_axis_c2h_cmpt_0_wait_pld_pkt_id;
    wire [15:0]  dma0_s_axis_c2h_cmpt_0_dpar;
    wire [2:0]   dma0_s_axis_c2h_cmpt_0_col_idx;
    wire [2:0]   dma0_s_axis_c2h_cmpt_0_err_idx;
    wire         dma0_s_axis_c2h_cmpt_0_user_trig;
    wire         dma0_s_axis_c2h_cmpt_0_marker;
    wire         dma0_s_axis_c2h_cmpt_0_no_wrb_marker;
    wire         dma0_s_axis_c2h_cmpt_0_tready;

    // PCIE0 descriptor credit in (user logic → BD slave)
    wire [15:0]  dma0_dsc_crdt_in_0_crdt;
    wire         dma0_dsc_crdt_in_0_dir;
    wire         dma0_dsc_crdt_in_0_fence;
    wire [11:0]  dma0_dsc_crdt_in_0_qid;
    wire         dma0_dsc_crdt_in_0_valid;
    wire         dma0_dsc_crdt_in_0_rdy;

    // PCIE0 queue status output (BD → user logic)
    wire [63:0]  dma0_qsts_out_0_data;
    wire [7:0]   dma0_qsts_out_0_op;
    wire [2:0]   dma0_qsts_out_0_port_id;
    wire [12:0]  dma0_qsts_out_0_qid;
    wire         dma0_qsts_out_0_vld;
    wire         dma0_qsts_out_0_rdy;

    // PCIE0 traffic manager descriptor status (BD → user logic)
    wire [15:0]  dma0_tm_dsc_sts_0_avl;
    wire         dma0_tm_dsc_sts_0_byp;
    wire         dma0_tm_dsc_sts_0_dir;
    wire         dma0_tm_dsc_sts_0_error;
    wire         dma0_tm_dsc_sts_0_irq_arm;
    wire         dma0_tm_dsc_sts_0_mm;
    wire [15:0]  dma0_tm_dsc_sts_0_pidx;
    wire [2:0]   dma0_tm_dsc_sts_0_port_id;
    wire         dma0_tm_dsc_sts_0_qen;
    wire [11:0]  dma0_tm_dsc_sts_0_qid;
    wire         dma0_tm_dsc_sts_0_qinv;
    wire         dma0_tm_dsc_sts_0_rdy;
    wire         dma0_tm_dsc_sts_0_valid;

    // PCIE0 user interrupt (user logic → BD slave)
    wire [10:0]  dma0_usr_irq_0_vec;
    wire [12:0]  dma0_usr_irq_0_fnc;
    wire         dma0_usr_irq_0_valid;
    wire         dma0_usr_irq_0_ack;
    wire         dma0_usr_irq_0_fail;

    // PCIE0 function level reset notification (BD → user logic)
    wire [12:0]  dma0_usr_flr_0_fnc;
    wire         dma0_usr_flr_0_set;
    wire         dma0_usr_flr_0_clear;
    wire [12:0]  dma0_usr_flr_0_done_fnc;
    wire         dma0_usr_flr_0_done_vld;

    // SMBus tristate signals (BD -> IOBUF)
    wire        smbus_0_scl_i;
    wire        smbus_0_scl_o;
    wire        smbus_0_scl_t;
    wire        smbus_0_sda_i;
    wire        smbus_0_sda_o;
    wire        smbus_0_sda_t;
