// smartnic_app module black box. Used for platform level builds.
(*black_box*) module smartnic_app
#(
    parameter int HOST_NUM_IFS = 3,     // Number of HOST interfaces.
    parameter int NUM_PORTS = 2,        // Number of processor ports (per vitisnetp4 processor).
    parameter int NUM_P4_PROC = 2       // Number of vitisnetp4 processors.
) (
    input  logic         core_clk,
    input  logic         core_srst,
    input  logic         axil_aclk,
    input  logic [63:0]  timestamp,

    // P4 AXI-L control interface
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

    // App AXI-L control interface
    // (synchronous to axil_aclk domain)
    // -- Reset
    input  logic         app_axil_aresetn,
    // -- Write address
    input  logic         app_axil_awvalid,
    output logic         app_axil_awready,
    input  logic [31:0]  app_axil_awaddr,
    input  logic [2:0]   app_axil_awprot,
    // -- Write data
    input  logic         app_axil_wvalid,
    output logic         app_axil_wready,
    input  logic [31:0]  app_axil_wdata,
    input  logic [3:0]   app_axil_wstrb,
    // -- Write response
    output logic         app_axil_bvalid,
    input  logic         app_axil_bready,
    output logic [1:0]   app_axil_bresp,
    // -- Read address
    input  logic         app_axil_arvalid,
    output logic         app_axil_arready,
    input  logic [31:0]  app_axil_araddr,
    input  logic [2:0]   app_axil_arprot,
    // -- Read data
    output logic         app_axil_rvalid,
    input  logic         app_axil_rready,
    output logic [31:0]  app_axil_rdata,
    output logic [1:0]   app_axil_rresp,

    // AXI-S app_igr interface
    // (synchronous to core_clk domain)
    input  logic [(NUM_PORTS*  1)-1:0] axis_app_igr_tvalid,
    output logic [(NUM_PORTS*  1)-1:0] axis_app_igr_tready,
    input  logic [(NUM_PORTS*512)-1:0] axis_app_igr_tdata,
    input  logic [(NUM_PORTS* 64)-1:0] axis_app_igr_tkeep,
    input  logic [(NUM_PORTS*  1)-1:0] axis_app_igr_tlast,
    input  logic [(NUM_PORTS*  4)-1:0] axis_app_igr_tid,
    input  logic [(NUM_PORTS*  4)-1:0] axis_app_igr_tdest,
    input  logic [(NUM_PORTS* 16)-1:0] axis_app_igr_tuser_pid,

    // AXI-S app_egr interface
    // (synchronous to core_clk domain)
    output logic [(NUM_PORTS*  1)-1:0] axis_app_egr_tvalid,
    input  logic [(NUM_PORTS*  1)-1:0] axis_app_egr_tready,
    output logic [(NUM_PORTS*512)-1:0] axis_app_egr_tdata,
    output logic [(NUM_PORTS* 64)-1:0] axis_app_egr_tkeep,
    output logic [(NUM_PORTS*  1)-1:0] axis_app_egr_tlast,
    output logic [(NUM_PORTS*  4)-1:0] axis_app_egr_tid,
    output logic [(NUM_PORTS*  4)-1:0] axis_app_egr_tdest,
    output logic [(NUM_PORTS* 16)-1:0] axis_app_egr_tuser_pid,
    output logic [(NUM_PORTS*  1)-1:0] axis_app_egr_tuser_trunc_enable,
    output logic [(NUM_PORTS* 16)-1:0] axis_app_egr_tuser_trunc_length,
    output logic [(NUM_PORTS*  1)-1:0] axis_app_egr_tuser_rss_enable,
    output logic [(NUM_PORTS* 12)-1:0] axis_app_egr_tuser_rss_entropy,

    // AXI-S c2h interface
    // (synchronous to core_clk domain)
    input  logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_h2c_tvalid,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_h2c_tready,
    input  logic [(HOST_NUM_IFS*NUM_PORTS*512)-1:0] axis_h2c_tdata,
    input  logic [(HOST_NUM_IFS*NUM_PORTS* 64)-1:0] axis_h2c_tkeep,
    input  logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_h2c_tlast,
    input  logic [(HOST_NUM_IFS*NUM_PORTS*  4)-1:0] axis_h2c_tid,
    input  logic [(HOST_NUM_IFS*NUM_PORTS*  4)-1:0] axis_h2c_tdest,
    input  logic [(HOST_NUM_IFS*NUM_PORTS* 16)-1:0] axis_h2c_tuser_pid,

    // AXI-S h2c interface
    // (synchronous to core_clk domain)
    output logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_c2h_tvalid,
    input  logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_c2h_tready,
    output logic [(HOST_NUM_IFS*NUM_PORTS*512)-1:0] axis_c2h_tdata,
    output logic [(HOST_NUM_IFS*NUM_PORTS* 64)-1:0] axis_c2h_tkeep,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_c2h_tlast,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  4)-1:0] axis_c2h_tid,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  4)-1:0] axis_c2h_tdest,
    output logic [(HOST_NUM_IFS*NUM_PORTS* 16)-1:0] axis_c2h_tuser_pid,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_c2h_tuser_trunc_enable,
    output logic [(HOST_NUM_IFS*NUM_PORTS* 16)-1:0] axis_c2h_tuser_trunc_length,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_c2h_tuser_rss_enable,
    output logic [(HOST_NUM_IFS*NUM_PORTS* 12)-1:0] axis_c2h_tuser_rss_entropy,

    // flow control signals (one from each egress FIFO).
    input logic [3:0]    egr_flow_ctl
);

endmodule: smartnic_app
