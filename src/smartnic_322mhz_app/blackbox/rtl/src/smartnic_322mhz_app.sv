// smartnic_322mhz_app (empty) stub module. Used for platform level tests.
(*black_box*) module smartnic_322mhz_app
#(
    parameter int AXI_HBM_NUM_IFS = 16
) (
    input  logic         core_clk,
    input  logic         core_rstn,
    input  logic         axil_aclk,
    input  logic [63:0]  timestamp,

    // AXI-L control interface
    // (synchronous to axil_aclk domain)
    // -- Reset
    input  logic         axil_aresetn,
    // -- Write address
    input  logic         axil_awvalid,
    output logic         axil_awready,
    input  logic [31:0]  axil_awaddr,
    input  logic [2:0]   axil_awprot,
    // -- Write data
    input  logic         axil_wvalid,
    output logic         axil_wready,
    input  logic [31:0]  axil_wdata,
    input  logic [3:0]   axil_wstrb,
    // -- Write response
    output logic         axil_bvalid,
    input  logic         axil_bready,
    output logic [1:0]   axil_bresp,
    // -- Read address
    input  logic         axil_arvalid,
    output logic         axil_arready,
    input  logic [31:0]  axil_araddr,
    input  logic [2:0]   axil_arprot,
    // -- Read data
    output logic         axil_rvalid,
    input  logic         axil_rready,
    output logic [31:0]  axil_rdata,
    output logic [1:0]   axil_rresp,

    // (SDNet) AXI-L control interface
    // (synchronous to axil_aclk domain)
    // -- Reset
    input  logic         axil_sdnet_aresetn,
    // -- Write address
    input  logic         axil_sdnet_awvalid,
    output logic         axil_sdnet_awready,
    input  logic [31:0]  axil_sdnet_awaddr,
    input  logic [2:0]   axil_sdnet_awprot,
    // -- Write data
    input  logic         axil_sdnet_wvalid,
    output logic         axil_sdnet_wready,
    input  logic [31:0]  axil_sdnet_wdata,
    input  logic [3:0]   axil_sdnet_wstrb,
    // -- Write response
    output logic         axil_sdnet_bvalid,
    input  logic         axil_sdnet_bready,
    output logic [1:0]   axil_sdnet_bresp,
    // -- Read address
    input  logic         axil_sdnet_arvalid,
    output logic         axil_sdnet_arready,
    input  logic [31:0]  axil_sdnet_araddr,
    input  logic [2:0]   axil_sdnet_arprot,
    // -- Read data
    output logic         axil_sdnet_rvalid,
    input  logic         axil_sdnet_rready,
    output logic [31:0]  axil_sdnet_rdata,
    output logic [1:0]   axil_sdnet_rresp,

    // AXI-S data interface (from switch)
    // (synchronous to core_clk domain)
    input  logic         axis_from_switch_0_tvalid,
    output logic         axis_from_switch_0_tready,
    input  logic [511:0] axis_from_switch_0_tdata,
    input  logic [63:0]  axis_from_switch_0_tkeep,
    input  logic         axis_from_switch_0_tlast,
    input  logic [1:0]   axis_from_switch_0_tid,
    input  logic [1:0]   axis_from_switch_0_tdest,
    input  logic [15:0]  axis_from_switch_0_tuser_pid,

    // AXI-S data interface (to switch)
    // (synchronous to core_clk domain)
    output logic         axis_to_switch_0_tvalid,
    input  logic         axis_to_switch_0_tready,
    output logic [511:0] axis_to_switch_0_tdata,
    output logic [63:0]  axis_to_switch_0_tkeep,
    output logic         axis_to_switch_0_tlast,
    output logic [1:0]   axis_to_switch_0_tid,
    output logic [2:0]   axis_to_switch_0_tdest,
    output logic [15:0]  axis_to_switch_0_tuser_pid,
    output logic         axis_to_switch_0_tuser_trunc_enable,
    output logic [15:0]  axis_to_switch_0_tuser_trunc_length,
    output logic         axis_to_switch_0_tuser_rss_enable,
    output logic [11:0]  axis_to_switch_0_tuser_rss_entropy,

    // AXI-S data interface (from host)
    // (synchronous to core_clk domain)
    input  logic         axis_from_switch_1_tvalid,
    output logic         axis_from_switch_1_tready,
    input  logic [511:0] axis_from_switch_1_tdata,
    input  logic [63:0]  axis_from_switch_1_tkeep,
    input  logic         axis_from_switch_1_tlast,
    input  logic [1:0]   axis_from_switch_1_tid,
    input  logic [1:0]   axis_from_switch_1_tdest,
    input  logic [15:0]  axis_from_switch_1_tuser_pid,

    // AXI-S data interface (to host)
    // (synchronous to core_clk domain)
    output logic         axis_to_switch_1_tvalid,
    input  logic         axis_to_switch_1_tready,
    output logic [511:0] axis_to_switch_1_tdata,
    output logic [63:0]  axis_to_switch_1_tkeep,
    output logic         axis_to_switch_1_tlast,
    output logic [1:0]   axis_to_switch_1_tid,
    output logic [2:0]   axis_to_switch_1_tdest,
    output logic [15:0]  axis_to_switch_1_tuser_pid,
    output logic         axis_to_switch_1_tuser_trunc_enable,
    output logic [15:0]  axis_to_switch_1_tuser_trunc_length,
    output logic         axis_to_switch_1_tuser_rss_enable,
    output logic [11:0]  axis_to_switch_1_tuser_rss_entropy,

    // flow control signals (one from each egress FIFO).
    input logic [3:0]    egr_flow_ctl,

    // AXI3 interfaces to HBM
    // (synchronous to core clock domain)
    output logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_aclk,
    output logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_aresetn,
    output logic [(AXI_HBM_NUM_IFS*  6)-1:0] axi_to_hbm_awid,
    output logic [(AXI_HBM_NUM_IFS* 33)-1:0] axi_to_hbm_awaddr,
    output logic [(AXI_HBM_NUM_IFS*  4)-1:0] axi_to_hbm_awlen,
    output logic [(AXI_HBM_NUM_IFS*  3)-1:0] axi_to_hbm_awsize,
    output logic [(AXI_HBM_NUM_IFS*  2)-1:0] axi_to_hbm_awburst,
    output logic [(AXI_HBM_NUM_IFS*  2)-1:0] axi_to_hbm_awlock,
    output logic [(AXI_HBM_NUM_IFS*  4)-1:0] axi_to_hbm_awcache,
    output logic [(AXI_HBM_NUM_IFS*  3)-1:0] axi_to_hbm_awprot,
    output logic [(AXI_HBM_NUM_IFS*  4)-1:0] axi_to_hbm_awqos,
    output logic [(AXI_HBM_NUM_IFS*  4)-1:0] axi_to_hbm_awregion,
    output logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_awvalid,
    input  logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_awready,
    output logic [(AXI_HBM_NUM_IFS*  6)-1:0] axi_to_hbm_wid,
    output logic [(AXI_HBM_NUM_IFS*256)-1:0] axi_to_hbm_wdata,
    output logic [(AXI_HBM_NUM_IFS* 32)-1:0] axi_to_hbm_wstrb,
    output logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_wlast,
    output logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_wvalid,
    input  logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_wready,
    input  logic [(AXI_HBM_NUM_IFS*  6)-1:0] axi_to_hbm_bid,
    input  logic [(AXI_HBM_NUM_IFS*  2)-1:0] axi_to_hbm_bresp,
    input  logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_bvalid,
    output logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_bready,
    output logic [(AXI_HBM_NUM_IFS*  6)-1:0] axi_to_hbm_arid,
    output logic [(AXI_HBM_NUM_IFS* 33)-1:0] axi_to_hbm_araddr,
    output logic [(AXI_HBM_NUM_IFS*  4)-1:0] axi_to_hbm_arlen,
    output logic [(AXI_HBM_NUM_IFS*  3)-1:0] axi_to_hbm_arsize,
    output logic [(AXI_HBM_NUM_IFS*  2)-1:0] axi_to_hbm_arburst,
    output logic [(AXI_HBM_NUM_IFS*  2)-1:0] axi_to_hbm_arlock,
    output logic [(AXI_HBM_NUM_IFS*  4)-1:0] axi_to_hbm_arcache,
    output logic [(AXI_HBM_NUM_IFS*  3)-1:0] axi_to_hbm_arprot,
    output logic [(AXI_HBM_NUM_IFS*  4)-1:0] axi_to_hbm_arqos,
    output logic [(AXI_HBM_NUM_IFS*  4)-1:0] axi_to_hbm_arregion,
    output logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_arvalid,
    input  logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_arready,
    input  logic [(AXI_HBM_NUM_IFS*  6)-1:0] axi_to_hbm_rid,
    input  logic [(AXI_HBM_NUM_IFS*256)-1:0] axi_to_hbm_rdata,
    input  logic [(AXI_HBM_NUM_IFS*  2)-1:0] axi_to_hbm_rresp,
    input  logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_rlast,
    input  logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_rvalid,
    output logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_rready
);

endmodule: smartnic_322mhz_app
