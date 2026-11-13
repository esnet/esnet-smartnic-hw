// Native UltraScale+ QDMA IP wrapper. Streaming adaptation is owned by the host.
module xilinx_alveo_qdma_wrapper #(
    parameter int PCIE_LINK_WID = 16
) (
    // From/to pins
    // -- PCIe
    input  logic                      pcie_rstn,
    input  logic                      pcie_refclk_p,
    input  logic                      pcie_refclk_n,
    input  logic [PCIE_LINK_WID-1:0]  pcie_rxp,
    input  logic [PCIE_LINK_WID-1:0]  pcie_rxn,
    output logic [PCIE_LINK_WID-1:0]  pcie_txp,
    output logic [PCIE_LINK_WID-1:0]  pcie_txn,

    // From/to core
    // -- AXI-L
    axi4l_intf.controller             axil_if,
    // Native QDMA streaming, completion, credit, and clock/reset ports
    output logic               axi_aclk,
    output logic               axi_aresetn,
    input  logic [15 : 0]      dsc_crdt_in_crdt,
    input  logic [10 : 0]      dsc_crdt_in_qid,
    input  logic               dsc_crdt_in_dir,
    input  logic               dsc_crdt_in_fence,
    input  logic               dsc_crdt_in_vld,
    output logic               dsc_crdt_in_rdy,
    output logic [511 : 0]     m_axis_h2c_tdata,
    output logic [31 : 0]      m_axis_h2c_tcrc,
    output logic [10 : 0]      m_axis_h2c_tuser_qid,
    output logic [2 : 0]       m_axis_h2c_tuser_port_id,
    output logic               m_axis_h2c_tuser_err,
    output logic [31 : 0]      m_axis_h2c_tuser_mdata,
    output logic [5 : 0]       m_axis_h2c_tuser_mty,
    output logic               m_axis_h2c_tuser_zero_byte,
    output logic               m_axis_h2c_tvalid,
    output logic               m_axis_h2c_tlast,
    input  logic               m_axis_h2c_tready,
    input  logic [511 : 0]     s_axis_c2h_tdata,
    input  logic [31 : 0]      s_axis_c2h_tcrc,
    input  logic               s_axis_c2h_ctrl_marker,
    input  logic [2 : 0]       s_axis_c2h_ctrl_port_id,
    input  logic [6 : 0]       s_axis_c2h_ctrl_ecc,
    input  logic [15 : 0]      s_axis_c2h_ctrl_len,
    input  logic [10 : 0]      s_axis_c2h_ctrl_qid,
    input  logic               s_axis_c2h_ctrl_has_cmpt,
    input  logic [5 : 0]       s_axis_c2h_mty,
    input  logic               s_axis_c2h_tvalid,
    input  logic               s_axis_c2h_tlast,
    output logic               s_axis_c2h_tready,
    input  logic [511 : 0]     s_axis_c2h_cmpt_tdata,
    input  logic [1 : 0]       s_axis_c2h_cmpt_size,
    input  logic [15 : 0]      s_axis_c2h_cmpt_dpar,
    input  logic               s_axis_c2h_cmpt_tvalid,
    input  logic [10 : 0]      s_axis_c2h_cmpt_ctrl_qid,
    input  logic [1 : 0]       s_axis_c2h_cmpt_ctrl_cmpt_type,
    input  logic [15 : 0]      s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id,
    input  logic [2 : 0]       s_axis_c2h_cmpt_ctrl_port_id,
    input  logic               s_axis_c2h_cmpt_ctrl_marker,
    input  logic               s_axis_c2h_cmpt_ctrl_user_trig,
    input  logic [2 : 0]       s_axis_c2h_cmpt_ctrl_col_idx,
    input  logic [2 : 0]       s_axis_c2h_cmpt_ctrl_err_idx,
    output logic               s_axis_c2h_cmpt_tready,
    input  logic               s_axis_c2h_cmpt_ctrl_no_wrb_marker
);
    // =========================================================================
    // Signals (corresponding to ports on QDMA IP)
    // =========================================================================
    logic sys_clk_gt;
    logic sys_clk;
    logic sys_rst_n;
    logic user_lnk_up;
    logic [PCIE_LINK_WID-1 : 0] pci_exp_txp;
    logic [PCIE_LINK_WID-1 : 0] pci_exp_txn;
    logic [PCIE_LINK_WID-1 : 0] pci_exp_rxp;
    logic [PCIE_LINK_WID-1 : 0] pci_exp_rxn;
    logic usr_irq_in_vld;
    logic [10 : 0] usr_irq_in_vec;
    logic [7 : 0] usr_irq_in_fnc;
    logic usr_irq_out_ack;
    logic usr_irq_out_fail;
    logic [7 : 0] usr_flr_fnc;
    logic usr_flr_set;
    logic [7 : 0] usr_flr_done_fnc;
    logic usr_flr_done_vld;
    logic [255 : 0] h2c_byp_out_dsc;
    logic h2c_byp_out_st_mm;
    logic [1 : 0] h2c_byp_out_dsc_sz;
    logic [10 : 0] h2c_byp_out_qid;
    logic h2c_byp_out_error;
    logic [7 : 0] h2c_byp_out_func;
    logic [15 : 0] h2c_byp_out_cidx;
    logic [2 : 0] h2c_byp_out_port_id;
    logic h2c_byp_out_vld;
    logic h2c_byp_out_rdy;
    logic [3 : 0] h2c_byp_out_fmt;
    logic [255 : 0] c2h_byp_out_dsc;
    logic c2h_byp_out_st_mm;
    logic [10 : 0] c2h_byp_out_qid;
    logic [1 : 0] c2h_byp_out_dsc_sz;
    logic c2h_byp_out_error;
    logic [7 : 0] c2h_byp_out_func;
    logic [15 : 0] c2h_byp_out_cidx;
    logic [2 : 0] c2h_byp_out_port_id;
    logic c2h_byp_out_vld;
    logic c2h_byp_out_rdy;
    logic [3 : 0] c2h_byp_out_fmt;
    logic [6 : 0] c2h_byp_out_pfch_tag;
    logic [63 : 0] c2h_byp_in_st_csh_addr;
    logic [2 : 0] c2h_byp_in_st_csh_port_id;
    logic [10 : 0] c2h_byp_in_st_csh_qid;
    logic c2h_byp_in_st_csh_error;
    logic [7 : 0] c2h_byp_in_st_csh_func;
    logic c2h_byp_in_st_csh_vld;
    logic c2h_byp_in_st_csh_rdy;
    logic [6 : 0] c2h_byp_in_st_csh_pfch_tag;
    logic [63 : 0] h2c_byp_in_st_addr;
    logic [15 : 0] h2c_byp_in_st_len;
    logic h2c_byp_in_st_eop;
    logic h2c_byp_in_st_sop;
    logic h2c_byp_in_st_mrkr_req;
    logic [2 : 0] h2c_byp_in_st_port_id;
    logic h2c_byp_in_st_sdi;
    logic [10 : 0] h2c_byp_in_st_qid;
    logic h2c_byp_in_st_error;
    logic [7 : 0] h2c_byp_in_st_func;
    logic [15 : 0] h2c_byp_in_st_cidx;
    logic h2c_byp_in_st_no_dma;
    logic h2c_byp_in_st_vld;
    logic h2c_byp_in_st_rdy;
    logic tm_dsc_sts_vld;
    logic [2 : 0] tm_dsc_sts_port_id;
    logic tm_dsc_sts_qen;
    logic tm_dsc_sts_byp;
    logic tm_dsc_sts_dir;
    logic tm_dsc_sts_mm;
    logic tm_dsc_sts_error;
    logic [10 : 0] tm_dsc_sts_qid;
    logic [15 : 0] tm_dsc_sts_avl;
    logic tm_dsc_sts_qinv;
    logic tm_dsc_sts_irq_arm;
    logic tm_dsc_sts_rdy;
    logic [15 : 0] tm_dsc_sts_pidx;
    logic [31 : 0] m_axil_awaddr;
    logic [54 : 0] m_axil_awuser;
    logic [2 : 0] m_axil_awprot;
    logic m_axil_awvalid;
    logic m_axil_awready;
    logic [31 : 0] m_axil_wdata;
    logic [3 : 0] m_axil_wstrb;
    logic m_axil_wvalid;
    logic m_axil_wready;
    logic m_axil_bvalid;
    logic [1 : 0] m_axil_bresp;
    logic m_axil_bready;
    logic [31 : 0] m_axil_araddr;
    logic [54 : 0] m_axil_aruser;
    logic [2 : 0] m_axil_arprot;
    logic m_axil_arvalid;
    logic m_axil_arready;
    logic [31 : 0] m_axil_rdata;
    logic [1 : 0] m_axil_rresp;
    logic m_axil_rvalid;
    logic m_axil_rready;
    logic axis_c2h_status_drop;
    logic axis_c2h_status_valid;
    logic axis_c2h_status_cmp;
    logic axis_c2h_status_error;
    logic axis_c2h_status_last;
    logic [10 : 0] axis_c2h_status_qid;
    logic axis_c2h_dmawr_cmp;
    logic soft_reset_n;
    logic phy_ready;
    logic [7 : 0] qsts_out_op;
    logic [63 : 0] qsts_out_data;
    logic [2 : 0] qsts_out_port_id;
    logic [12 : 0] qsts_out_qid;
    logic qsts_out_vld;
    logic qsts_out_rdy;

    // =========================================================================
    // Clock buffer
    // =========================================================================
    IBUFDS_GTE4 i_ibufds_gte4__pcie_refclk (
        .CEB   (1'b0),
        .I     ( pcie_refclk_p ),
        .IB    ( pcie_refclk_n ),
        .O     ( sys_clk_gt ),     // input wire sys_clk_gt
        .ODIV2 ( sys_clk )         // input wire sys_clk
    );

    // =========================================================================
    // Reset
    // =========================================================================
    assign sys_rst_n = pcie_rstn;  // input wire sys_rst_n

    // =========================================================================
    // Status
    // =========================================================================
    // output wire user_lnk_up
    // output wire phy_ready

    // =========================================================================
    // Serial interface
    // =========================================================================
    assign pci_exp_rxp = pcie_rxp; // input wire [15 : 0] pci_exp_rxp
    assign pci_exp_rxn = pcie_rxn; // input wire [15 : 0] pci_exp_rxn
    assign pcie_txp = pci_exp_txp; // output wire [15 : 0] pci_exp_txp
    assign pcie_txn = pci_exp_txn; // output wire [15 : 0] pci_exp_txn

    // =========================================================================
    // User interrupts
    // =========================================================================
    assign usr_irq_in_vld = 1'b0;   // input wire usr_irq_in_vld
    assign usr_irq_in_vec = '0;     // input wire [10 : 0] usr_irq_in_vec
    assign usr_irq_in_fnc = '0;     // input wire [7 : 0] usr_irq_in_fnc

    // output wire usr_irq_out_ack
    // output wire usr_irq_out_fail

    // =========================================================================
    // Function-level reset
    // =========================================================================
    assign usr_flr_done_vld = 1'b0;   // input wire usr_flr_done_vld
    assign usr_flr_done_fnc = '0;     // input wire [7 : 0] usr_flr_done_fnc

    // output wire [7 : 0] usr_flr_fnc
    // output wire usr_flr_set

    // =========================================================================
    // H2C bypass
    // =========================================================================

    assign h2c_byp_in_st_addr = '0;        // input wire [63 : 0] h2c_byp_in_st_addr
    assign h2c_byp_in_st_len = '0;         // input wire [15 : 0] h2c_byp_in_st_len
    assign h2c_byp_in_st_eop = 1'b0;       // input wire h2c_byp_in_st_eop
    assign h2c_byp_in_st_sop = 1'b0;       // input wire h2c_byp_in_st_sop
    assign h2c_byp_in_st_mrkr_req = 1'b0;  // input wire h2c_byp_in_st_mrkr_req
    assign h2c_byp_in_st_port_id = '0;     // input wire [2 : 0] h2c_byp_in_st_port_id
    assign h2c_byp_in_st_sdi = 1'b0;       // input wire h2c_byp_in_st_sdi
    assign h2c_byp_in_st_qid = '0;         // input wire [10 : 0] h2c_byp_in_st_qid
    assign h2c_byp_in_st_error = 1'b0;     // input wire h2c_byp_in_st_error
    assign h2c_byp_in_st_func = '0;        // input wire [7 : 0] h2c_byp_in_st_func
    assign h2c_byp_in_st_cidx = '0;        // input wire [15 : 0] h2c_byp_in_st_cidx
    assign h2c_byp_in_st_no_dma = 1'b0;    // input wire h2c_byp_in_st_no_dma
    assign h2c_byp_in_st_vld = 1'b0;       // input wire h2c_byp_in_st_vld

    // output wire h2c_byp_in_st_rdy

    assign h2c_byp_out_rdy = 1'b1;          // input wire h2c_byp_out_rdy

    // output wire [255 : 0] h2c_byp_out_dsc
    // output wire h2c_byp_out_st_mm
    // output wire [1 : 0] h2c_byp_out_dsc_sz
    // output wire [10 : 0] h2c_byp_out_qid
    // output wire h2c_byp_out_error
    // output wire [7 : 0] h2c_byp_out_func
    // output wire [15 : 0] h2c_byp_out_cidx
    // output wire [2 : 0] h2c_byp_out_port_id
    // output wire h2c_byp_out_vld
    // output wire [3 : 0] h2c_byp_out_fmt

    // =========================================================================
    // C2H bypass
    // =========================================================================
    assign c2h_byp_out_rdy = 1'b1;  // input wire c2h_byp_out_rdy

    // output wire [255 : 0] c2h_byp_out_dsc
    // output wire c2h_byp_out_st_mm
    // output wire [10 : 0] c2h_byp_out_qid
    // output wire [1 : 0] c2h_byp_out_dsc_sz
    // output wire c2h_byp_out_error
    // output wire [7 : 0] c2h_byp_out_func
    // output wire [15 : 0] c2h_byp_out_cidx
    // output wire [2 : 0] c2h_byp_out_port_id
    // output wire c2h_byp_out_vld
    // output wire [3 : 0] c2h_byp_out_fmt
    // output wire [6 : 0] c2h_byp_out_pfch_tag

    assign c2h_byp_in_st_csh_addr = '0;     // input wire [63 : 0] c2h_byp_in_st_csh_addr
    assign c2h_byp_in_st_csh_port_id = '0;  // input wire [2 : 0] c2h_byp_in_st_csh_port_id
    assign c2h_byp_in_st_csh_qid = '0;      // input wire [10 : 0] c2h_byp_in_st_csh_qid
    assign c2h_byp_in_st_csh_error = 1'b0;  // input wire c2h_byp_in_st_csh_error
    assign c2h_byp_in_st_csh_func = '0;     // input wire [7 : 0] c2h_byp_in_st_csh_func
    assign c2h_byp_in_st_csh_vld = 1'b0;    // input wire c2h_byp_in_st_csh_vld
    assign c2h_byp_in_st_csh_pfch_tag = '0; // input wire [6 : 0] c2h_byp_in_st_csh_pfch_tag

    // output wire c2h_byp_in_st_csh_rdy

    // =========================================================================
    // Traffic management (descriptor status)
    // =========================================================================
    assign tm_dsc_sts_rdy = 1'b1;  // input wire tm_dsc_sts_rdy

    // output wire tm_dsc_sts_vld
    // output wire [2 : 0] tm_dsc_sts_port_id
    // output wire tm_dsc_sts_qen
    // output wire tm_dsc_sts_byp
    // output wire tm_dsc_sts_dir
    // output wire tm_dsc_sts_mm
    // output wire tm_dsc_sts_error
    // output wire [10 : 0] tm_dsc_sts_qid
    // output wire [15 : 0] tm_dsc_sts_avl
    // output wire tm_dsc_sts_qinv
    // output wire tm_dsc_sts_irq_arm
    // output wire [15 : 0] tm_dsc_sts_pidx

    // =========================================================================
    // Traffic management (descriptor credits)
    // =========================================================================

    // output wire dsc_crdt_in_rdy

    // =========================================================================
    // AXI-L Controller
    // =========================================================================
    assign axil_if.aclk = axi_aclk;             // output wire axi_aclk
    assign axil_if.aresetn = axi_aresetn;       // output wire axi_aresetn
    assign axil_if.awaddr = m_axil_awaddr;      // output wire [31 : 0] m_axil_awaddr
    //assign axil_if.awuser = m_axil_awuser;    // output wire [54 : 0] m_axil_awuser
    assign axil_if.awprot = m_axil_awprot;      // output wire [2 : 0] m_axil_awprot
    assign axil_if.awvalid = m_axil_awvalid;    // output wire m_axil_awvalid
    assign m_axil_awready = axil_if.awready;    // input wire m_axil_awready
    assign axil_if.wdata = m_axil_wdata;        // output wire [31 : 0] m_axil_wdata
    assign axil_if.wstrb = m_axil_wstrb;        // output wire [3 : 0] m_axil_wstrb
    assign axil_if.wvalid = m_axil_wvalid;      // output wire m_axil_wvalid
    assign m_axil_wready = axil_if.wready;      // input wire m_axil_wready
    assign m_axil_bvalid = axil_if.bvalid;      // input wire m_axil_bvalid
    assign m_axil_bresp = axil_if.bresp;        // input wire [1 : 0] m_axil_bresp
    assign axil_if.bready = m_axil_bready;      // output wire m_axil_bready
    assign axil_if.araddr = m_axil_araddr;      // output wire [31 : 0] m_axil_araddr
    //assign axil_if.aruser = m_axil_aruser;    // output wire [54 : 0] m_axil_aruser
    assign axil_if.arprot = m_axil_arprot;      // output wire [2 : 0] m_axil_arprot
    assign axil_if.arvalid = m_axil_arvalid;    // output wire m_axil_arvalid
    assign m_axil_arready = axil_if.arready;    // input wire m_axil_arready
    assign m_axil_rdata = axil_if.rdata;        // input wire [31 : 0] m_axil_rdata
    assign m_axil_rresp = axil_if.rresp;        // input wire [1 : 0] m_axil_rresp
    assign m_axil_rvalid = axil_if.rvalid;      // input wire m_axil_rvalid
    assign axil_if.rready = m_axil_rready;      // output wire m_axil_rready

    // =========================================================================
    // Soft reset
    // =========================================================================
    assign soft_reset_n = 1'b1;  // input wire soft_reset_n

    // =========================================================================
    // Queue status
    // =========================================================================
    // output wire [7 : 0] qsts_out_op
    // output wire [63 : 0] qsts_out_data
    // output wire [2 : 0] qsts_out_port_id
    // output wire [12 : 0] qsts_out_qid
    // output wire qsts_out_vld
    assign qsts_out_rdy = 1'b1;  // input wire qsts_out_rdy

    // =========================================================================
    // QDMA IP instantiation
    // =========================================================================
    // NOTE: Use instantiation template exactly as provided in IP (including whitespace, but with
    //       generic instance name commented out) to enable trivial diffs to simplify upgrades or changes,
    //       identify added/removed signals, etc.
    // 
xilinx_alveo_usplus_qdma i_xilinx_alveo_usplus_qdma (
//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
//xilinx_alveo_usplus_qdma your_instance_name (
  .sys_clk(sys_clk),                                                            // input wire sys_clk
  .sys_clk_gt(sys_clk_gt),                                                      // input wire sys_clk_gt
  .sys_rst_n(sys_rst_n),                                                        // input wire sys_rst_n
  .user_lnk_up(user_lnk_up),                                                    // output wire user_lnk_up
  .pci_exp_txp(pci_exp_txp),                                                    // output wire [15 : 0] pci_exp_txp
  .pci_exp_txn(pci_exp_txn),                                                    // output wire [15 : 0] pci_exp_txn
  .pci_exp_rxp(pci_exp_rxp),                                                    // input wire [15 : 0] pci_exp_rxp
  .pci_exp_rxn(pci_exp_rxn),                                                    // input wire [15 : 0] pci_exp_rxn
  .axi_aclk(axi_aclk),                                                          // output wire axi_aclk
  .axi_aresetn(axi_aresetn),                                                    // output wire axi_aresetn
  .usr_irq_in_vld(usr_irq_in_vld),                                              // input wire usr_irq_in_vld
  .usr_irq_in_vec(usr_irq_in_vec),                                              // input wire [10 : 0] usr_irq_in_vec
  .usr_irq_in_fnc(usr_irq_in_fnc),                                              // input wire [7 : 0] usr_irq_in_fnc
  .usr_irq_out_ack(usr_irq_out_ack),                                            // output wire usr_irq_out_ack
  .usr_irq_out_fail(usr_irq_out_fail),                                          // output wire usr_irq_out_fail
//  .usr_flr_fnc(usr_flr_fnc),                                                    // output wire [7 : 0] usr_flr_fnc
//  .usr_flr_set(usr_flr_set),                                                    // output wire usr_flr_set
//  .usr_flr_done_fnc(usr_flr_done_fnc),                                          // input wire [7 : 0] usr_flr_done_fnc
//  .usr_flr_done_vld(usr_flr_done_vld),                                          // input wire usr_flr_done_vld
  .h2c_byp_out_dsc(h2c_byp_out_dsc),                                            // output wire [255 : 0] h2c_byp_out_dsc
  .h2c_byp_out_st_mm(h2c_byp_out_st_mm),                                        // output wire h2c_byp_out_st_mm
  .h2c_byp_out_dsc_sz(h2c_byp_out_dsc_sz),                                      // output wire [1 : 0] h2c_byp_out_dsc_sz
  .h2c_byp_out_qid(h2c_byp_out_qid),                                            // output wire [10 : 0] h2c_byp_out_qid
  .h2c_byp_out_error(h2c_byp_out_error),                                        // output wire h2c_byp_out_error
  .h2c_byp_out_func(h2c_byp_out_func),                                          // output wire [7 : 0] h2c_byp_out_func
  .h2c_byp_out_cidx(h2c_byp_out_cidx),                                          // output wire [15 : 0] h2c_byp_out_cidx
  .h2c_byp_out_port_id(h2c_byp_out_port_id),                                    // output wire [2 : 0] h2c_byp_out_port_id
  .h2c_byp_out_vld(h2c_byp_out_vld),                                            // output wire h2c_byp_out_vld
  .h2c_byp_out_rdy(h2c_byp_out_rdy),                                            // input wire h2c_byp_out_rdy
  .h2c_byp_out_fmt(h2c_byp_out_fmt),                                            // output wire [3 : 0] h2c_byp_out_fmt
  .c2h_byp_out_dsc(c2h_byp_out_dsc),                                            // output wire [255 : 0] c2h_byp_out_dsc
  .c2h_byp_out_st_mm(c2h_byp_out_st_mm),                                        // output wire c2h_byp_out_st_mm
  .c2h_byp_out_qid(c2h_byp_out_qid),                                            // output wire [10 : 0] c2h_byp_out_qid
  .c2h_byp_out_dsc_sz(c2h_byp_out_dsc_sz),                                      // output wire [1 : 0] c2h_byp_out_dsc_sz
  .c2h_byp_out_error(c2h_byp_out_error),                                        // output wire c2h_byp_out_error
  .c2h_byp_out_func(c2h_byp_out_func),                                          // output wire [7 : 0] c2h_byp_out_func
  .c2h_byp_out_cidx(c2h_byp_out_cidx),                                          // output wire [15 : 0] c2h_byp_out_cidx
  .c2h_byp_out_port_id(c2h_byp_out_port_id),                                    // output wire [2 : 0] c2h_byp_out_port_id
  .c2h_byp_out_vld(c2h_byp_out_vld),                                            // output wire c2h_byp_out_vld
  .c2h_byp_out_rdy(c2h_byp_out_rdy),                                            // input wire c2h_byp_out_rdy
  .c2h_byp_out_fmt(c2h_byp_out_fmt),                                            // output wire [3 : 0] c2h_byp_out_fmt
  .c2h_byp_out_pfch_tag(c2h_byp_out_pfch_tag),                                  // output wire [6 : 0] c2h_byp_out_pfch_tag
  .c2h_byp_in_st_csh_addr(c2h_byp_in_st_csh_addr),                              // input wire [63 : 0] c2h_byp_in_st_csh_addr
  .c2h_byp_in_st_csh_port_id(c2h_byp_in_st_csh_port_id),                        // input wire [2 : 0] c2h_byp_in_st_csh_port_id
  .c2h_byp_in_st_csh_qid(c2h_byp_in_st_csh_qid),                                // input wire [10 : 0] c2h_byp_in_st_csh_qid
  .c2h_byp_in_st_csh_error(c2h_byp_in_st_csh_error),                            // input wire c2h_byp_in_st_csh_error
  .c2h_byp_in_st_csh_func(c2h_byp_in_st_csh_func),                              // input wire [7 : 0] c2h_byp_in_st_csh_func
  .c2h_byp_in_st_csh_vld(c2h_byp_in_st_csh_vld),                                // input wire c2h_byp_in_st_csh_vld
  .c2h_byp_in_st_csh_rdy(c2h_byp_in_st_csh_rdy),                                // output wire c2h_byp_in_st_csh_rdy
  .c2h_byp_in_st_csh_pfch_tag(c2h_byp_in_st_csh_pfch_tag),                      // input wire [6 : 0] c2h_byp_in_st_csh_pfch_tag
  .h2c_byp_in_st_addr(h2c_byp_in_st_addr),                                      // input wire [63 : 0] h2c_byp_in_st_addr
  .h2c_byp_in_st_len(h2c_byp_in_st_len),                                        // input wire [15 : 0] h2c_byp_in_st_len
  .h2c_byp_in_st_eop(h2c_byp_in_st_eop),                                        // input wire h2c_byp_in_st_eop
  .h2c_byp_in_st_sop(h2c_byp_in_st_sop),                                        // input wire h2c_byp_in_st_sop
  .h2c_byp_in_st_mrkr_req(h2c_byp_in_st_mrkr_req),                              // input wire h2c_byp_in_st_mrkr_req
  .h2c_byp_in_st_port_id(h2c_byp_in_st_port_id),                                // input wire [2 : 0] h2c_byp_in_st_port_id
  .h2c_byp_in_st_sdi(h2c_byp_in_st_sdi),                                        // input wire h2c_byp_in_st_sdi
  .h2c_byp_in_st_qid(h2c_byp_in_st_qid),                                        // input wire [10 : 0] h2c_byp_in_st_qid
  .h2c_byp_in_st_error(h2c_byp_in_st_error),                                    // input wire h2c_byp_in_st_error
  .h2c_byp_in_st_func(h2c_byp_in_st_func),                                      // input wire [7 : 0] h2c_byp_in_st_func
  .h2c_byp_in_st_cidx(h2c_byp_in_st_cidx),                                      // input wire [15 : 0] h2c_byp_in_st_cidx
  .h2c_byp_in_st_no_dma(h2c_byp_in_st_no_dma),                                  // input wire h2c_byp_in_st_no_dma
  .h2c_byp_in_st_vld(h2c_byp_in_st_vld),                                        // input wire h2c_byp_in_st_vld
  .h2c_byp_in_st_rdy(h2c_byp_in_st_rdy),                                        // output wire h2c_byp_in_st_rdy
  .tm_dsc_sts_vld(tm_dsc_sts_vld),                                              // output wire tm_dsc_sts_vld
  .tm_dsc_sts_port_id(tm_dsc_sts_port_id),                                      // output wire [2 : 0] tm_dsc_sts_port_id
  .tm_dsc_sts_qen(tm_dsc_sts_qen),                                              // output wire tm_dsc_sts_qen
  .tm_dsc_sts_byp(tm_dsc_sts_byp),                                              // output wire tm_dsc_sts_byp
  .tm_dsc_sts_dir(tm_dsc_sts_dir),                                              // output wire tm_dsc_sts_dir
  .tm_dsc_sts_mm(tm_dsc_sts_mm),                                                // output wire tm_dsc_sts_mm
  .tm_dsc_sts_error(tm_dsc_sts_error),                                          // output wire tm_dsc_sts_error
  .tm_dsc_sts_qid(tm_dsc_sts_qid),                                              // output wire [10 : 0] tm_dsc_sts_qid
  .tm_dsc_sts_avl(tm_dsc_sts_avl),                                              // output wire [15 : 0] tm_dsc_sts_avl
  .tm_dsc_sts_qinv(tm_dsc_sts_qinv),                                            // output wire tm_dsc_sts_qinv
  .tm_dsc_sts_irq_arm(tm_dsc_sts_irq_arm),                                      // output wire tm_dsc_sts_irq_arm
  .tm_dsc_sts_rdy(tm_dsc_sts_rdy),                                              // input wire tm_dsc_sts_rdy
  .tm_dsc_sts_pidx(tm_dsc_sts_pidx),                                            // output wire [15 : 0] tm_dsc_sts_pidx
  .dsc_crdt_in_crdt(dsc_crdt_in_crdt),                                          // input wire [15 : 0] dsc_crdt_in_crdt
  .dsc_crdt_in_qid(dsc_crdt_in_qid),                                            // input wire [10 : 0] dsc_crdt_in_qid
  .dsc_crdt_in_dir(dsc_crdt_in_dir),                                            // input wire dsc_crdt_in_dir
  .dsc_crdt_in_fence(dsc_crdt_in_fence),                                        // input wire dsc_crdt_in_fence
  .dsc_crdt_in_vld(dsc_crdt_in_vld),                                            // input wire dsc_crdt_in_vld
  .dsc_crdt_in_rdy(dsc_crdt_in_rdy),                                            // output wire dsc_crdt_in_rdy
  .m_axil_awaddr(m_axil_awaddr),                                                // output wire [31 : 0] m_axil_awaddr
  .m_axil_awuser(m_axil_awuser),                                                // output wire [54 : 0] m_axil_awuser
  .m_axil_awprot(m_axil_awprot),                                                // output wire [2 : 0] m_axil_awprot
  .m_axil_awvalid(m_axil_awvalid),                                              // output wire m_axil_awvalid
  .m_axil_awready(m_axil_awready),                                              // input wire m_axil_awready
  .m_axil_wdata(m_axil_wdata),                                                  // output wire [31 : 0] m_axil_wdata
  .m_axil_wstrb(m_axil_wstrb),                                                  // output wire [3 : 0] m_axil_wstrb
  .m_axil_wvalid(m_axil_wvalid),                                                // output wire m_axil_wvalid
  .m_axil_wready(m_axil_wready),                                                // input wire m_axil_wready
  .m_axil_bvalid(m_axil_bvalid),                                                // input wire m_axil_bvalid
  .m_axil_bresp(m_axil_bresp),                                                  // input wire [1 : 0] m_axil_bresp
  .m_axil_bready(m_axil_bready),                                                // output wire m_axil_bready
  .m_axil_araddr(m_axil_araddr),                                                // output wire [31 : 0] m_axil_araddr
  .m_axil_aruser(m_axil_aruser),                                                // output wire [54 : 0] m_axil_aruser
  .m_axil_arprot(m_axil_arprot),                                                // output wire [2 : 0] m_axil_arprot
  .m_axil_arvalid(m_axil_arvalid),                                              // output wire m_axil_arvalid
  .m_axil_arready(m_axil_arready),                                              // input wire m_axil_arready
  .m_axil_rdata(m_axil_rdata),                                                  // input wire [31 : 0] m_axil_rdata
  .m_axil_rresp(m_axil_rresp),                                                  // input wire [1 : 0] m_axil_rresp
  .m_axil_rvalid(m_axil_rvalid),                                                // input wire m_axil_rvalid
  .m_axil_rready(m_axil_rready),                                                // output wire m_axil_rready
  .m_axis_h2c_tdata(m_axis_h2c_tdata),                                          // output wire [511 : 0] m_axis_h2c_tdata
  .m_axis_h2c_tcrc(m_axis_h2c_tcrc),                                            // output wire [31 : 0] m_axis_h2c_tcrc
  .m_axis_h2c_tuser_qid(m_axis_h2c_tuser_qid),                                  // output wire [10 : 0] m_axis_h2c_tuser_qid
  .m_axis_h2c_tuser_port_id(m_axis_h2c_tuser_port_id),                          // output wire [2 : 0] m_axis_h2c_tuser_port_id
  .m_axis_h2c_tuser_err(m_axis_h2c_tuser_err),                                  // output wire m_axis_h2c_tuser_err
  .m_axis_h2c_tuser_mdata(m_axis_h2c_tuser_mdata),                              // output wire [31 : 0] m_axis_h2c_tuser_mdata
  .m_axis_h2c_tuser_mty(m_axis_h2c_tuser_mty),                                  // output wire [5 : 0] m_axis_h2c_tuser_mty
  .m_axis_h2c_tuser_zero_byte(m_axis_h2c_tuser_zero_byte),                      // output wire m_axis_h2c_tuser_zero_byte
  .m_axis_h2c_tvalid(m_axis_h2c_tvalid),                                        // output wire m_axis_h2c_tvalid
  .m_axis_h2c_tlast(m_axis_h2c_tlast),                                          // output wire m_axis_h2c_tlast
  .m_axis_h2c_tready(m_axis_h2c_tready),                                        // input wire m_axis_h2c_tready
  .s_axis_c2h_tdata(s_axis_c2h_tdata),                                          // input wire [511 : 0] s_axis_c2h_tdata
  .s_axis_c2h_tcrc(s_axis_c2h_tcrc),                                            // input wire [31 : 0] s_axis_c2h_tcrc
  .s_axis_c2h_ctrl_marker(s_axis_c2h_ctrl_marker),                              // input wire s_axis_c2h_ctrl_marker
  .s_axis_c2h_ctrl_port_id(s_axis_c2h_ctrl_port_id),                            // input wire [2 : 0] s_axis_c2h_ctrl_port_id
  .s_axis_c2h_ctrl_ecc(s_axis_c2h_ctrl_ecc),                                    // input wire [6 : 0] s_axis_c2h_ctrl_ecc
  .s_axis_c2h_ctrl_len(s_axis_c2h_ctrl_len),                                    // input wire [15 : 0] s_axis_c2h_ctrl_len
  .s_axis_c2h_ctrl_qid(s_axis_c2h_ctrl_qid),                                    // input wire [10 : 0] s_axis_c2h_ctrl_qid
  .s_axis_c2h_ctrl_has_cmpt(s_axis_c2h_ctrl_has_cmpt),                          // input wire s_axis_c2h_ctrl_has_cmpt
  .s_axis_c2h_mty(s_axis_c2h_mty),                                              // input wire [5 : 0] s_axis_c2h_mty
  .s_axis_c2h_tvalid(s_axis_c2h_tvalid),                                        // input wire s_axis_c2h_tvalid
  .s_axis_c2h_tlast(s_axis_c2h_tlast),                                          // input wire s_axis_c2h_tlast
  .s_axis_c2h_tready(s_axis_c2h_tready),                                        // output wire s_axis_c2h_tready
  .s_axis_c2h_cmpt_tdata(s_axis_c2h_cmpt_tdata),                                // input wire [511 : 0] s_axis_c2h_cmpt_tdata
  .s_axis_c2h_cmpt_size(s_axis_c2h_cmpt_size),                                  // input wire [1 : 0] s_axis_c2h_cmpt_size
  .s_axis_c2h_cmpt_dpar(s_axis_c2h_cmpt_dpar),                                  // input wire [15 : 0] s_axis_c2h_cmpt_dpar
  .s_axis_c2h_cmpt_tvalid(s_axis_c2h_cmpt_tvalid),                              // input wire s_axis_c2h_cmpt_tvalid
  .s_axis_c2h_cmpt_ctrl_qid(s_axis_c2h_cmpt_ctrl_qid),                          // input wire [10 : 0] s_axis_c2h_cmpt_ctrl_qid
  .s_axis_c2h_cmpt_ctrl_cmpt_type(s_axis_c2h_cmpt_ctrl_cmpt_type),              // input wire [1 : 0] s_axis_c2h_cmpt_ctrl_cmpt_type
  .s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id(s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id),  // input wire [15 : 0] s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id
  .s_axis_c2h_cmpt_ctrl_port_id(s_axis_c2h_cmpt_ctrl_port_id),                  // input wire [2 : 0] s_axis_c2h_cmpt_ctrl_port_id
  .s_axis_c2h_cmpt_ctrl_marker(s_axis_c2h_cmpt_ctrl_marker),                    // input wire s_axis_c2h_cmpt_ctrl_marker
  .s_axis_c2h_cmpt_ctrl_user_trig(s_axis_c2h_cmpt_ctrl_user_trig),              // input wire s_axis_c2h_cmpt_ctrl_user_trig
  .s_axis_c2h_cmpt_ctrl_col_idx(s_axis_c2h_cmpt_ctrl_col_idx),                  // input wire [2 : 0] s_axis_c2h_cmpt_ctrl_col_idx
  .s_axis_c2h_cmpt_ctrl_err_idx(s_axis_c2h_cmpt_ctrl_err_idx),                  // input wire [2 : 0] s_axis_c2h_cmpt_ctrl_err_idx
  .s_axis_c2h_cmpt_tready(s_axis_c2h_cmpt_tready),                              // output wire s_axis_c2h_cmpt_tready
  .s_axis_c2h_cmpt_ctrl_no_wrb_marker(s_axis_c2h_cmpt_ctrl_no_wrb_marker),      // input wire s_axis_c2h_cmpt_ctrl_no_wrb_marker
  .axis_c2h_status_drop(axis_c2h_status_drop),                                  // output wire axis_c2h_status_drop
  .axis_c2h_status_valid(axis_c2h_status_valid),                                // output wire axis_c2h_status_valid
  .axis_c2h_status_cmp(axis_c2h_status_cmp),                                    // output wire axis_c2h_status_cmp
  .axis_c2h_status_error(axis_c2h_status_error),                                // output wire axis_c2h_status_error
  .axis_c2h_status_last(axis_c2h_status_last),                                  // output wire axis_c2h_status_last
  .axis_c2h_status_qid(axis_c2h_status_qid),                                    // output wire [10 : 0] axis_c2h_status_qid
  .axis_c2h_dmawr_cmp(axis_c2h_dmawr_cmp),                                      // output wire axis_c2h_dmawr_cmp
  .soft_reset_n(soft_reset_n),                                                  // input wire soft_reset_n
  .phy_ready(phy_ready),                                                        // output wire phy_ready
  .qsts_out_op(qsts_out_op),                                                    // output wire [7 : 0] qsts_out_op
  .qsts_out_data(qsts_out_data),                                                // output wire [63 : 0] qsts_out_data
  .qsts_out_port_id(qsts_out_port_id),                                          // output wire [2 : 0] qsts_out_port_id
  .qsts_out_qid(qsts_out_qid),                                                  // output wire [12 : 0] qsts_out_qid
  .qsts_out_vld(qsts_out_vld),                                                  // output wire qsts_out_vld
  .qsts_out_rdy(qsts_out_rdy)                                                  // input wire qsts_out_rdy
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

endmodule : xilinx_alveo_qdma_wrapper
