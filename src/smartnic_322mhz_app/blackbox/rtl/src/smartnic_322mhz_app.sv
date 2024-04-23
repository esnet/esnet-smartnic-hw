// smartnic_app (empty) stub module. Used for platform level tests.
(*black_box*) module smartnic_app
#(
    parameter int AXI_HBM_NUM_IFS = 16,
    parameter int N = 2, // Number of processor ports (per vitisnetp4 processor).
    parameter int M = 2  // Number of vitisnetp4 processors.
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
    input  logic [(M*  1)-1:0] axil_sdnet_aresetn,
    // -- Write address
    input  logic [(M*  1)-1:0] axil_sdnet_awvalid,
    output logic [(M*  1)-1:0] axil_sdnet_awready,
    input  logic [(M* 32)-1:0] axil_sdnet_awaddr,
    input  logic [(M*  3)-1:0] axil_sdnet_awprot,
    // -- Write data
    input  logic [(M*  1)-1:0] axil_sdnet_wvalid,
    output logic [(M*  1)-1:0] axil_sdnet_wready,
    input  logic [(M* 32)-1:0] axil_sdnet_wdata,
    input  logic [(M*  4)-1:0] axil_sdnet_wstrb,
    // -- Write response
    output logic [(M*  1)-1:0] axil_sdnet_bvalid,
    input  logic [(M*  1)-1:0] axil_sdnet_bready,
    output logic [(M*  2)-1:0] axil_sdnet_bresp,
    // -- Read address
    input  logic [(M*  1)-1:0] axil_sdnet_arvalid,
    output logic [(M*  1)-1:0] axil_sdnet_arready,
    input  logic [(M* 32)-1:0] axil_sdnet_araddr,
    input  logic [(M*  3)-1:0] axil_sdnet_arprot,
    // -- Read data
    output logic [(M*  1)-1:0] axil_sdnet_rvalid,
    input  logic [(M*  1)-1:0] axil_sdnet_rready,
    output logic [(M* 32)-1:0] axil_sdnet_rdata,
    output logic [(M*  2)-1:0] axil_sdnet_rresp,

    // AXI-S data interface (from switch)
    // (synchronous to core_clk domain)
    input  logic [(M*N*  1)-1:0] axis_from_switch_tvalid,
    output logic [(M*N*  1)-1:0] axis_from_switch_tready,
    input  logic [(M*N*512)-1:0] axis_from_switch_tdata,
    input  logic [(M*N* 64)-1:0] axis_from_switch_tkeep,
    input  logic [(M*N*  1)-1:0] axis_from_switch_tlast,
    input  logic [(M*N*  2)-1:0] axis_from_switch_tid,
    input  logic [(M*N*  2)-1:0] axis_from_switch_tdest,
    input  logic [(M*N* 16)-1:0] axis_from_switch_tuser_pid,

    // AXI-S data interface (to switch)
    // (synchronous to core_clk domain)
    output logic [(M*N*  1)-1:0] axis_to_switch_tvalid,
    input  logic [(M*N*  1)-1:0] axis_to_switch_tready,
    output logic [(M*N*512)-1:0] axis_to_switch_tdata,
    output logic [(M*N* 64)-1:0] axis_to_switch_tkeep,
    output logic [(M*N*  1)-1:0] axis_to_switch_tlast,
    output logic [(M*N*  2)-1:0] axis_to_switch_tid,
    output logic [(M*N*  3)-1:0] axis_to_switch_tdest,
    output logic [(M*N* 16)-1:0] axis_to_switch_tuser_pid,
    output logic [(M*N*  1)-1:0] axis_to_switch_tuser_trunc_enable,
    output logic [(M*N* 16)-1:0] axis_to_switch_tuser_trunc_length,
    output logic [(M*N*  1)-1:0] axis_to_switch_tuser_rss_enable,
    output logic [(M*N* 12)-1:0] axis_to_switch_tuser_rss_entropy,

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

endmodule: smartnic_app
