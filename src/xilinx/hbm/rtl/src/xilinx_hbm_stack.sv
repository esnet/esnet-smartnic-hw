module xilinx_hbm_stack
    import xilinx_hbm_pkg::*;
#(
    parameter stack_t   STACK   = STACK_LEFT,
    parameter density_t DENSITY = DENSITY_4G
) (
    // Clock/reset
    input wire logic       clk,
    input wire logic       srst,

    // HBM reference clock
    input wire logic       hbm_ref_clk,

    // 100MHz clock (for APB)
    input wire logic       clk_100mhz,

    // AXI-L control interface
    axi4l_intf.peripheral  axil_if,

    // AXI3 memory interfaces
    axi3_intf.peripheral   axi_if [PSEUDO_CHANNELS_PER_STACK]
);
    // Parameters
    localparam int ADDR_WID = get_addr_wid(DENSITY);

    // Signals
    logic       init_done;
    logic       dram_status_cattrip;
    logic [6:0] dram_status_temp;

    // -------------------------------------------
    // Interfaces
    // -------------------------------------------
    apb_intf   apb_if ();
    axi3_intf #(.DATA_BYTE_WID(AXI_DATA_BYTE_WID), .ADDR_WID(ADDR_WID), .ID_T(axi_id_t)) __axi_if [PSEUDO_CHANNELS_PER_STACK] (.aclk(clk));
    axi3_intf #(.DATA_BYTE_WID(AXI_DATA_BYTE_WID), .ADDR_WID(ADDR_WID), .ID_T(axi_id_t)) axi_if__ctrl (.aclk(clk));

    // -------------------------------------------
    // Instantiations
    // -------------------------------------------
    xilinx_hbm_stack_ctrl #(
        .STACK   ( STACK ),
        .DENSITY ( DENSITY )  
    ) i_xilinx_hbm_stack_ctrl (
        .apb_clk ( clk_100mhz ),
        .control_proxy_axi_if  ( axi_if__ctrl ),
        .*
    );

    // Connect AXI-3 interfaces
    generate
        for (genvar g_ch = 0; g_ch < PSEUDO_CHANNELS_PER_STACK-1; g_ch++) begin : g__ps
            // Connect external AXI-3 interface directly
            axi3_intf_connector i_axi3_connector (.axi3_if_from_controller(axi_if[g_ch]), .axi3_if_to_peripheral(__axi_if[g_ch]));
        end : g__ps
    endgenerate
    // On channel N-1, isolate and tie off external interface
    axi3_intf_peripheral_term i_axi3_peripheral_term__ctrl (.axi3_if (axi_if[PSEUDO_CHANNELS_PER_STACK-1]));
    // .. and drive memory accesses from register proxy
    axi3_intf_connector i_axi3_connector__ctrl (.axi3_if_from_controller(axi_if__ctrl), .axi3_if_to_peripheral(__axi_if[PSEUDO_CHANNELS_PER_STACK-1]));

    // Xilinx HBM IP (single stack) ports
    // -----------------------------------------
    // Reference clock
    wire logic                         HBM_REF_CLK_0;
    // Channel 0
    wire logic                         AXI_00_ACLK;
    wire logic                         AXI_00_ARESET_N;
    wire logic [ADDR_WID-1:0]          AXI_00_ARADDR;
    wire logic [1:0]                   AXI_00_ARBURST;
    wire axi_id_t                      AXI_00_ARID;
    wire logic [3:0]                   AXI_00_ARLEN;
    wire logic [2:0]                   AXI_00_ARSIZE;
    wire logic                         AXI_00_ARVALID;
    wire logic [ADDR_WID-1:0]          AXI_00_AWADDR;
    wire logic [1:0]                   AXI_00_AWBURST;
    wire axi_id_t                      AXI_00_AWID;
    wire logic [3:0]                   AXI_00_AWLEN;
    wire logic [2:0]                   AXI_00_AWSIZE;
    wire logic                         AXI_00_AWVALID;
    wire logic                         AXI_00_RREADY;
    wire logic                         AXI_00_BREADY;
    wire logic [AXI_DATA_WID-1:0]      AXI_00_WDATA;
    wire logic                         AXI_00_WLAST;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_00_WSTRB;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_00_WDATA_PARITY;
    wire logic                         AXI_00_WVALID;
    wire logic                         AXI_00_ARREADY;
    wire logic                         AXI_00_AWREADY;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_00_RDATA_PARITY;
    wire logic [AXI_DATA_WID-1:0]      AXI_00_RDATA;
    wire axi_id_t                      AXI_00_RID;
    wire logic                         AXI_00_RLAST;
    wire logic [1:0]                   AXI_00_RRESP;
    wire logic                         AXI_00_RVALID;
    wire logic                         AXI_00_WREADY;
    wire axi_id_t                      AXI_00_BID;
    wire logic [1:0]                   AXI_00_BRESP;
    wire logic                         AXI_00_BVALID;
    // Channel 1
    wire logic                         AXI_01_ACLK;
    wire logic                         AXI_01_ARESET_N;
    wire logic [ADDR_WID-1:0]          AXI_01_ARADDR;
    wire logic [1:0]                   AXI_01_ARBURST;
    wire axi_id_t                      AXI_01_ARID;
    wire logic [3:0]                   AXI_01_ARLEN;
    wire logic [2:0]                   AXI_01_ARSIZE;
    wire logic                         AXI_01_ARVALID;
    wire logic [ADDR_WID-1:0]          AXI_01_AWADDR;
    wire logic [1:0]                   AXI_01_AWBURST;
    wire axi_id_t                      AXI_01_AWID;
    wire logic [3:0]                   AXI_01_AWLEN;
    wire logic [2:0]                   AXI_01_AWSIZE;
    wire logic                         AXI_01_AWVALID;
    wire logic                         AXI_01_RREADY;
    wire logic                         AXI_01_BREADY;
    wire logic [AXI_DATA_WID-1:0]      AXI_01_WDATA;
    wire logic                         AXI_01_WLAST;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_01_WSTRB;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_01_WDATA_PARITY;
    wire logic                         AXI_01_WVALID;
    wire logic                         AXI_01_ARREADY;
    wire logic                         AXI_01_AWREADY;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_01_RDATA_PARITY;
    wire logic [AXI_DATA_WID-1:0]      AXI_01_RDATA;
    wire axi_id_t                      AXI_01_RID;
    wire logic                         AXI_01_RLAST;
    wire logic [1:0]                   AXI_01_RRESP;
    wire logic                         AXI_01_RVALID;
    wire logic                         AXI_01_WREADY;
    wire axi_id_t                      AXI_01_BID;
    wire logic [1:0]                   AXI_01_BRESP;
    wire logic                         AXI_01_BVALID;
    // Channel 2
    wire logic                         AXI_02_ACLK;
    wire logic                         AXI_02_ARESET_N;
    wire logic [ADDR_WID-1:0]          AXI_02_ARADDR;
    wire logic [1:0]                   AXI_02_ARBURST;
    wire axi_id_t                      AXI_02_ARID;
    wire logic [3:0]                   AXI_02_ARLEN;
    wire logic [2:0]                   AXI_02_ARSIZE;
    wire logic                         AXI_02_ARVALID;
    wire logic [ADDR_WID-1:0]          AXI_02_AWADDR;
    wire logic [1:0]                   AXI_02_AWBURST;
    wire axi_id_t                      AXI_02_AWID;
    wire logic [3:0]                   AXI_02_AWLEN;
    wire logic [2:0]                   AXI_02_AWSIZE;
    wire logic                         AXI_02_AWVALID;
    wire logic                         AXI_02_RREADY;
    wire logic                         AXI_02_BREADY;
    wire logic [AXI_DATA_WID-1:0]      AXI_02_WDATA;
    wire logic                         AXI_02_WLAST;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_02_WSTRB;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_02_WDATA_PARITY;
    wire logic                         AXI_02_WVALID;
    wire logic                         AXI_02_ARREADY;
    wire logic                         AXI_02_AWREADY;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_02_RDATA_PARITY;
    wire logic [AXI_DATA_WID-1:0]      AXI_02_RDATA;
    wire axi_id_t                      AXI_02_RID;
    wire logic                         AXI_02_RLAST;
    wire logic [1:0]                   AXI_02_RRESP;
    wire logic                         AXI_02_RVALID;
    wire logic                         AXI_02_WREADY;
    wire axi_id_t                      AXI_02_BID;
    wire logic [1:0]                   AXI_02_BRESP;
    wire logic                         AXI_02_BVALID;
    // Channel 3
    wire logic                         AXI_03_ACLK;
    wire logic                         AXI_03_ARESET_N;
    wire logic [ADDR_WID-1:0]          AXI_03_ARADDR;
    wire logic [1:0]                   AXI_03_ARBURST;
    wire axi_id_t                      AXI_03_ARID;
    wire logic [3:0]                   AXI_03_ARLEN;
    wire logic [2:0]                   AXI_03_ARSIZE;
    wire logic                         AXI_03_ARVALID;
    wire logic [ADDR_WID-1:0]          AXI_03_AWADDR;
    wire logic [1:0]                   AXI_03_AWBURST;
    wire axi_id_t                      AXI_03_AWID;
    wire logic [3:0]                   AXI_03_AWLEN;
    wire logic [2:0]                   AXI_03_AWSIZE;
    wire logic                         AXI_03_AWVALID;
    wire logic                         AXI_03_RREADY;
    wire logic                         AXI_03_BREADY;
    wire logic [AXI_DATA_WID-1:0]      AXI_03_WDATA;
    wire logic                         AXI_03_WLAST;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_03_WSTRB;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_03_WDATA_PARITY;
    wire logic                         AXI_03_WVALID;
    wire logic                         AXI_03_ARREADY;
    wire logic                         AXI_03_AWREADY;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_03_RDATA_PARITY;
    wire logic [AXI_DATA_WID-1:0]      AXI_03_RDATA;
    wire axi_id_t                      AXI_03_RID;
    wire logic                         AXI_03_RLAST;
    wire logic [1:0]                   AXI_03_RRESP;
    wire logic                         AXI_03_RVALID;
    wire logic                         AXI_03_WREADY;
    wire axi_id_t                      AXI_03_BID;
    wire logic [1:0]                   AXI_03_BRESP;
    wire logic                         AXI_03_BVALID;
    // Channel 4
    wire logic                         AXI_04_ACLK;
    wire logic                         AXI_04_ARESET_N;
    wire logic [ADDR_WID-1:0]          AXI_04_ARADDR;
    wire logic [1:0]                   AXI_04_ARBURST;
    wire axi_id_t                      AXI_04_ARID;
    wire logic [3:0]                   AXI_04_ARLEN;
    wire logic [2:0]                   AXI_04_ARSIZE;
    wire logic                         AXI_04_ARVALID;
    wire logic [ADDR_WID-1:0]          AXI_04_AWADDR;
    wire logic [1:0]                   AXI_04_AWBURST;
    wire axi_id_t                      AXI_04_AWID;
    wire logic [3:0]                   AXI_04_AWLEN;
    wire logic [2:0]                   AXI_04_AWSIZE;
    wire logic                         AXI_04_AWVALID;
    wire logic                         AXI_04_RREADY;
    wire logic                         AXI_04_BREADY;
    wire logic [AXI_DATA_WID-1:0]      AXI_04_WDATA;
    wire logic                         AXI_04_WLAST;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_04_WSTRB;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_04_WDATA_PARITY;
    wire logic                         AXI_04_WVALID;
    wire logic                         AXI_04_ARREADY;
    wire logic                         AXI_04_AWREADY;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_04_RDATA_PARITY;
    wire logic [AXI_DATA_WID-1:0]      AXI_04_RDATA;
    wire axi_id_t                      AXI_04_RID;
    wire logic                         AXI_04_RLAST;
    wire logic [1:0]                   AXI_04_RRESP;
    wire logic                         AXI_04_RVALID;
    wire logic                         AXI_04_WREADY;
    wire axi_id_t                      AXI_04_BID;
    wire logic [1:0]                   AXI_04_BRESP;
    wire logic                         AXI_04_BVALID;
    // Channel 5
    wire logic                         AXI_05_ACLK;
    wire logic                         AXI_05_ARESET_N;
    wire logic [ADDR_WID-1:0]          AXI_05_ARADDR;
    wire logic [1:0]                   AXI_05_ARBURST;
    wire axi_id_t                      AXI_05_ARID;
    wire logic [3:0]                   AXI_05_ARLEN;
    wire logic [2:0]                   AXI_05_ARSIZE;
    wire logic                         AXI_05_ARVALID;
    wire logic [ADDR_WID-1:0]          AXI_05_AWADDR;
    wire logic [1:0]                   AXI_05_AWBURST;
    wire axi_id_t                      AXI_05_AWID;
    wire logic [3:0]                   AXI_05_AWLEN;
    wire logic [2:0]                   AXI_05_AWSIZE;
    wire logic                         AXI_05_AWVALID;
    wire logic                         AXI_05_RREADY;
    wire logic                         AXI_05_BREADY;
    wire logic [AXI_DATA_WID-1:0]      AXI_05_WDATA;
    wire logic                         AXI_05_WLAST;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_05_WSTRB;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_05_WDATA_PARITY;
    wire logic                         AXI_05_WVALID;
    wire logic                         AXI_05_ARREADY;
    wire logic                         AXI_05_AWREADY;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_05_RDATA_PARITY;
    wire logic [AXI_DATA_WID-1:0]      AXI_05_RDATA;
    wire axi_id_t                      AXI_05_RID;
    wire logic                         AXI_05_RLAST;
    wire logic [1:0]                   AXI_05_RRESP;
    wire logic                         AXI_05_RVALID;
    wire logic                         AXI_05_WREADY;
    wire axi_id_t                      AXI_05_BID;
    wire logic [1:0]                   AXI_05_BRESP;
    wire logic                         AXI_05_BVALID;
    // Channel 6
    wire logic                         AXI_06_ACLK;
    wire logic                         AXI_06_ARESET_N;
    wire logic [ADDR_WID-1:0]          AXI_06_ARADDR;
    wire logic [1:0]                   AXI_06_ARBURST;
    wire axi_id_t                      AXI_06_ARID;
    wire logic [3:0]                   AXI_06_ARLEN;
    wire logic [2:0]                   AXI_06_ARSIZE;
    wire logic                         AXI_06_ARVALID;
    wire logic [ADDR_WID-1:0]          AXI_06_AWADDR;
    wire logic [1:0]                   AXI_06_AWBURST;
    wire axi_id_t                      AXI_06_AWID;
    wire logic [3:0]                   AXI_06_AWLEN;
    wire logic [2:0]                   AXI_06_AWSIZE;
    wire logic                         AXI_06_AWVALID;
    wire logic                         AXI_06_RREADY;
    wire logic                         AXI_06_BREADY;
    wire logic [AXI_DATA_WID-1:0]      AXI_06_WDATA;
    wire logic                         AXI_06_WLAST;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_06_WSTRB;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_06_WDATA_PARITY;
    wire logic                         AXI_06_WVALID;
    wire logic                         AXI_06_ARREADY;
    wire logic                         AXI_06_AWREADY;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_06_RDATA_PARITY;
    wire logic [AXI_DATA_WID-1:0]      AXI_06_RDATA;
    wire axi_id_t                      AXI_06_RID;
    wire logic                         AXI_06_RLAST;
    wire logic [1:0]                   AXI_06_RRESP;
    wire logic                         AXI_06_RVALID;
    wire logic                         AXI_06_WREADY;
    wire axi_id_t                      AXI_06_BID;
    wire logic [1:0]                   AXI_06_BRESP;
    wire logic                         AXI_06_BVALID;
    // Channel 7
    wire logic                         AXI_07_ACLK;
    wire logic                         AXI_07_ARESET_N;
    wire logic [ADDR_WID-1:0]          AXI_07_ARADDR;
    wire logic [1:0]                   AXI_07_ARBURST;
    wire axi_id_t                      AXI_07_ARID;
    wire logic [3:0]                   AXI_07_ARLEN;
    wire logic [2:0]                   AXI_07_ARSIZE;
    wire logic                         AXI_07_ARVALID;
    wire logic [ADDR_WID-1:0]          AXI_07_AWADDR;
    wire logic [1:0]                   AXI_07_AWBURST;
    wire axi_id_t                      AXI_07_AWID;
    wire logic [3:0]                   AXI_07_AWLEN;
    wire logic [2:0]                   AXI_07_AWSIZE;
    wire logic                         AXI_07_AWVALID;
    wire logic                         AXI_07_RREADY;
    wire logic                         AXI_07_BREADY;
    wire logic [AXI_DATA_WID-1:0]      AXI_07_WDATA;
    wire logic                         AXI_07_WLAST;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_07_WSTRB;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_07_WDATA_PARITY;
    wire logic                         AXI_07_WVALID;
    wire logic                         AXI_07_ARREADY;
    wire logic                         AXI_07_AWREADY;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_07_RDATA_PARITY;
    wire logic [AXI_DATA_WID-1:0]      AXI_07_RDATA;
    wire axi_id_t                      AXI_07_RID;
    wire logic                         AXI_07_RLAST;
    wire logic [1:0]                   AXI_07_RRESP;
    wire logic                         AXI_07_RVALID;
    wire logic                         AXI_07_WREADY;
    wire axi_id_t                      AXI_07_BID;
    wire logic [1:0]                   AXI_07_BRESP;
    wire logic                         AXI_07_BVALID;
    // Channel 8
    wire logic                         AXI_08_ACLK;
    wire logic                         AXI_08_ARESET_N;
    wire logic [ADDR_WID-1:0]          AXI_08_ARADDR;
    wire logic [1:0]                   AXI_08_ARBURST;
    wire axi_id_t                      AXI_08_ARID;
    wire logic [3:0]                   AXI_08_ARLEN;
    wire logic [2:0]                   AXI_08_ARSIZE;
    wire logic                         AXI_08_ARVALID;
    wire logic [ADDR_WID-1:0]          AXI_08_AWADDR;
    wire logic [1:0]                   AXI_08_AWBURST;
    wire axi_id_t                      AXI_08_AWID;
    wire logic [3:0]                   AXI_08_AWLEN;
    wire logic [2:0]                   AXI_08_AWSIZE;
    wire logic                         AXI_08_AWVALID;
    wire logic                         AXI_08_RREADY;
    wire logic                         AXI_08_BREADY;
    wire logic [AXI_DATA_WID-1:0]      AXI_08_WDATA;
    wire logic                         AXI_08_WLAST;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_08_WSTRB;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_08_WDATA_PARITY;
    wire logic                         AXI_08_WVALID;
    wire logic                         AXI_08_ARREADY;
    wire logic                         AXI_08_AWREADY;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_08_RDATA_PARITY;
    wire logic [AXI_DATA_WID-1:0]      AXI_08_RDATA;
    wire axi_id_t                      AXI_08_RID;
    wire logic                         AXI_08_RLAST;
    wire logic [1:0]                   AXI_08_RRESP;
    wire logic                         AXI_08_RVALID;
    wire logic                         AXI_08_WREADY;
    wire axi_id_t                      AXI_08_BID;
    wire logic [1:0]                   AXI_08_BRESP;
    wire logic                         AXI_08_BVALID;
    // Channel 9
    wire logic                         AXI_09_ACLK;
    wire logic                         AXI_09_ARESET_N;
    wire logic [ADDR_WID-1:0]          AXI_09_ARADDR;
    wire logic [1:0]                   AXI_09_ARBURST;
    wire axi_id_t                      AXI_09_ARID;
    wire logic [3:0]                   AXI_09_ARLEN;
    wire logic [2:0]                   AXI_09_ARSIZE;
    wire logic                         AXI_09_ARVALID;
    wire logic [ADDR_WID-1:0]          AXI_09_AWADDR;
    wire logic [1:0]                   AXI_09_AWBURST;
    wire axi_id_t                      AXI_09_AWID;
    wire logic [3:0]                   AXI_09_AWLEN;
    wire logic [2:0]                   AXI_09_AWSIZE;
    wire logic                         AXI_09_AWVALID;
    wire logic                         AXI_09_RREADY;
    wire logic                         AXI_09_BREADY;
    wire logic [AXI_DATA_WID-1:0]      AXI_09_WDATA;
    wire logic                         AXI_09_WLAST;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_09_WSTRB;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_09_WDATA_PARITY;
    wire logic                         AXI_09_WVALID;
    wire logic                         AXI_09_ARREADY;
    wire logic                         AXI_09_AWREADY;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_09_RDATA_PARITY;
    wire logic [AXI_DATA_WID-1:0]      AXI_09_RDATA;
    wire axi_id_t                      AXI_09_RID;
    wire logic                         AXI_09_RLAST;
    wire logic [1:0]                   AXI_09_RRESP;
    wire logic                         AXI_09_RVALID;
    wire logic                         AXI_09_WREADY;
    wire axi_id_t                      AXI_09_BID;
    wire logic [1:0]                   AXI_09_BRESP;
    wire logic                         AXI_09_BVALID;
    // Channel 10
    wire logic                         AXI_10_ACLK;
    wire logic                         AXI_10_ARESET_N;
    wire logic [ADDR_WID-1:0]          AXI_10_ARADDR;
    wire logic [1:0]                   AXI_10_ARBURST;
    wire axi_id_t                      AXI_10_ARID;
    wire logic [3:0]                   AXI_10_ARLEN;
    wire logic [2:0]                   AXI_10_ARSIZE;
    wire logic                         AXI_10_ARVALID;
    wire logic [ADDR_WID-1:0]          AXI_10_AWADDR;
    wire logic [1:0]                   AXI_10_AWBURST;
    wire axi_id_t                      AXI_10_AWID;
    wire logic [3:0]                   AXI_10_AWLEN;
    wire logic [2:0]                   AXI_10_AWSIZE;
    wire logic                         AXI_10_AWVALID;
    wire logic                         AXI_10_RREADY;
    wire logic                         AXI_10_BREADY;
    wire logic [AXI_DATA_WID-1:0]      AXI_10_WDATA;
    wire logic                         AXI_10_WLAST;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_10_WSTRB;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_10_WDATA_PARITY;
    wire logic                         AXI_10_WVALID;
    wire logic                         AXI_10_ARREADY;
    wire logic                         AXI_10_AWREADY;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_10_RDATA_PARITY;
    wire logic [AXI_DATA_WID-1:0]      AXI_10_RDATA;
    wire axi_id_t                      AXI_10_RID;
    wire logic                         AXI_10_RLAST;
    wire logic [1:0]                   AXI_10_RRESP;
    wire logic                         AXI_10_RVALID;
    wire logic                         AXI_10_WREADY;
    wire axi_id_t                      AXI_10_BID;
    wire logic [1:0]                   AXI_10_BRESP;
    wire logic                         AXI_10_BVALID;
    // Channel 11
    wire logic                         AXI_11_ACLK;
    wire logic                         AXI_11_ARESET_N;
    wire logic [ADDR_WID-1:0]          AXI_11_ARADDR;
    wire logic [1:0]                   AXI_11_ARBURST;
    wire axi_id_t                      AXI_11_ARID;
    wire logic [3:0]                   AXI_11_ARLEN;
    wire logic [2:0]                   AXI_11_ARSIZE;
    wire logic                         AXI_11_ARVALID;
    wire logic [ADDR_WID-1:0]          AXI_11_AWADDR;
    wire logic [1:0]                   AXI_11_AWBURST;
    wire axi_id_t                      AXI_11_AWID;
    wire logic [3:0]                   AXI_11_AWLEN;
    wire logic [2:0]                   AXI_11_AWSIZE;
    wire logic                         AXI_11_AWVALID;
    wire logic                         AXI_11_RREADY;
    wire logic                         AXI_11_BREADY;
    wire logic [AXI_DATA_WID-1:0]      AXI_11_WDATA;
    wire logic                         AXI_11_WLAST;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_11_WSTRB;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_11_WDATA_PARITY;
    wire logic                         AXI_11_WVALID;
    wire logic                         AXI_11_ARREADY;
    wire logic                         AXI_11_AWREADY;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_11_RDATA_PARITY;
    wire logic [AXI_DATA_WID-1:0]      AXI_11_RDATA;
    wire axi_id_t                      AXI_11_RID;
    wire logic                         AXI_11_RLAST;
    wire logic [1:0]                   AXI_11_RRESP;
    wire logic                         AXI_11_RVALID;
    wire logic                         AXI_11_WREADY;
    wire axi_id_t                      AXI_11_BID;
    wire logic [1:0]                   AXI_11_BRESP;
    wire logic                         AXI_11_BVALID;
    // Channel 12
    wire logic                         AXI_12_ACLK;
    wire logic                         AXI_12_ARESET_N;
    wire logic [ADDR_WID-1:0]          AXI_12_ARADDR;
    wire logic [1:0]                   AXI_12_ARBURST;
    wire axi_id_t                      AXI_12_ARID;
    wire logic [3:0]                   AXI_12_ARLEN;
    wire logic [2:0]                   AXI_12_ARSIZE;
    wire logic                         AXI_12_ARVALID;
    wire logic [ADDR_WID-1:0]          AXI_12_AWADDR;
    wire logic [1:0]                   AXI_12_AWBURST;
    wire axi_id_t                      AXI_12_AWID;
    wire logic [3:0]                   AXI_12_AWLEN;
    wire logic [2:0]                   AXI_12_AWSIZE;
    wire logic                         AXI_12_AWVALID;
    wire logic                         AXI_12_RREADY;
    wire logic                         AXI_12_BREADY;
    wire logic [AXI_DATA_WID-1:0]      AXI_12_WDATA;
    wire logic                         AXI_12_WLAST;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_12_WSTRB;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_12_WDATA_PARITY;
    wire logic                         AXI_12_WVALID;
    wire logic                         AXI_12_ARREADY;
    wire logic                         AXI_12_AWREADY;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_12_RDATA_PARITY;
    wire logic [AXI_DATA_WID-1:0]      AXI_12_RDATA;
    wire axi_id_t                      AXI_12_RID;
    wire logic                         AXI_12_RLAST;
    wire logic [1:0]                   AXI_12_RRESP;
    wire logic                         AXI_12_RVALID;
    wire logic                         AXI_12_WREADY;
    wire axi_id_t                      AXI_12_BID;
    wire logic [1:0]                   AXI_12_BRESP;
    wire logic                         AXI_12_BVALID;
    // Channel 13
    wire logic                         AXI_13_ACLK;
    wire logic                         AXI_13_ARESET_N;
    wire logic [ADDR_WID-1:0]          AXI_13_ARADDR;
    wire logic [1:0]                   AXI_13_ARBURST;
    wire axi_id_t                      AXI_13_ARID;
    wire logic [3:0]                   AXI_13_ARLEN;
    wire logic [2:0]                   AXI_13_ARSIZE;
    wire logic                         AXI_13_ARVALID;
    wire logic [ADDR_WID-1:0]          AXI_13_AWADDR;
    wire logic [1:0]                   AXI_13_AWBURST;
    wire axi_id_t                      AXI_13_AWID;
    wire logic [3:0]                   AXI_13_AWLEN;
    wire logic [2:0]                   AXI_13_AWSIZE;
    wire logic                         AXI_13_AWVALID;
    wire logic                         AXI_13_RREADY;
    wire logic                         AXI_13_BREADY;
    wire logic [AXI_DATA_WID-1:0]      AXI_13_WDATA;
    wire logic                         AXI_13_WLAST;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_13_WSTRB;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_13_WDATA_PARITY;
    wire logic                         AXI_13_WVALID;
    wire logic                         AXI_13_ARREADY;
    wire logic                         AXI_13_AWREADY;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_13_RDATA_PARITY;
    wire logic [AXI_DATA_WID-1:0]      AXI_13_RDATA;
    wire axi_id_t                      AXI_13_RID;
    wire logic                         AXI_13_RLAST;
    wire logic [1:0]                   AXI_13_RRESP;
    wire logic                         AXI_13_RVALID;
    wire logic                         AXI_13_WREADY;
    wire axi_id_t                      AXI_13_BID;
    wire logic [1:0]                   AXI_13_BRESP;
    wire logic                         AXI_13_BVALID;
    // Channel 14
    wire logic                         AXI_14_ACLK;
    wire logic                         AXI_14_ARESET_N;
    wire logic [ADDR_WID-1:0]          AXI_14_ARADDR;
    wire logic [1:0]                   AXI_14_ARBURST;
    wire axi_id_t                      AXI_14_ARID;
    wire logic [3:0]                   AXI_14_ARLEN;
    wire logic [2:0]                   AXI_14_ARSIZE;
    wire logic                         AXI_14_ARVALID;
    wire logic [ADDR_WID-1:0]          AXI_14_AWADDR;
    wire logic [1:0]                   AXI_14_AWBURST;
    wire axi_id_t                      AXI_14_AWID;
    wire logic [3:0]                   AXI_14_AWLEN;
    wire logic [2:0]                   AXI_14_AWSIZE;
    wire logic                         AXI_14_AWVALID;
    wire logic                         AXI_14_RREADY;
    wire logic                         AXI_14_BREADY;
    wire logic [AXI_DATA_WID-1:0]      AXI_14_WDATA;
    wire logic                         AXI_14_WLAST;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_14_WSTRB;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_14_WDATA_PARITY;
    wire logic                         AXI_14_WVALID;
    wire logic                         AXI_14_ARREADY;
    wire logic                         AXI_14_AWREADY;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_14_RDATA_PARITY;
    wire logic [AXI_DATA_WID-1:0]      AXI_14_RDATA;
    wire axi_id_t                      AXI_14_RID;
    wire logic                         AXI_14_RLAST;
    wire logic [1:0]                   AXI_14_RRESP;
    wire logic                         AXI_14_RVALID;
    wire logic                         AXI_14_WREADY;
    wire axi_id_t                      AXI_14_BID;
    wire logic [1:0]                   AXI_14_BRESP;
    wire logic                         AXI_14_BVALID;
    // Channel 15
    wire logic                         AXI_15_ACLK;
    wire logic                         AXI_15_ARESET_N;
    wire logic [ADDR_WID-1:0]          AXI_15_ARADDR;
    wire logic [1:0]                   AXI_15_ARBURST;
    wire axi_id_t                      AXI_15_ARID;
    wire logic [3:0]                   AXI_15_ARLEN;
    wire logic [2:0]                   AXI_15_ARSIZE;
    wire logic                         AXI_15_ARVALID;
    wire logic [ADDR_WID-1:0]          AXI_15_AWADDR;
    wire logic [1:0]                   AXI_15_AWBURST;
    wire axi_id_t                      AXI_15_AWID;
    wire logic [3:0]                   AXI_15_AWLEN;
    wire logic [2:0]                   AXI_15_AWSIZE;
    wire logic                         AXI_15_AWVALID;
    wire logic                         AXI_15_RREADY;
    wire logic                         AXI_15_BREADY;
    wire logic [AXI_DATA_WID-1:0]      AXI_15_WDATA;
    wire logic                         AXI_15_WLAST;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_15_WSTRB;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_15_WDATA_PARITY;
    wire logic                         AXI_15_WVALID;
    wire logic                         AXI_15_ARREADY;
    wire logic                         AXI_15_AWREADY;
    wire logic [AXI_DATA_BYTE_WID-1:0] AXI_15_RDATA_PARITY;
    wire logic [AXI_DATA_WID-1:0]      AXI_15_RDATA;
    wire axi_id_t                      AXI_15_RID;
    wire logic                         AXI_15_RLAST;
    wire logic [1:0]                   AXI_15_RRESP;
    wire logic                         AXI_15_RVALID;
    wire logic                         AXI_15_WREADY;
    wire axi_id_t                      AXI_15_BID;
    wire logic [1:0]                   AXI_15_BRESP;
    wire logic                         AXI_15_BVALID;
    // APB interface
    wire logic [31:0]                  APB_0_PWDATA;
    wire logic [21:0]                  APB_0_PADDR;
    wire logic                         APB_0_PCLK;
    wire logic                         APB_0_PENABLE;
    wire logic                         APB_0_PRESET_N;
    wire logic                         APB_0_PSEL;
    wire logic                         APB_0_PWRITE;
    wire logic [31:0]                  APB_0_PRDATA;
    wire logic                         APB_0_PREADY;
    wire logic                         APB_0_PSLVERR;
    wire logic                         apb_complete_0;
    // DRAM status
    wire logic                         DRAM_0_STAT_CATTRIP;
    wire logic [6:0]                   DRAM_0_STAT_TEMP;
  
    // Xilinx HBM controller wrapper interface
    xilinx_hbm_stack_if #(
        .DENSITY ( DENSITY )
    ) i_xilinx_hbm_stack_if (
        .axi_if ( __axi_if ),
        .*
    );
 
`ifndef SYNTHESIS
    
    // HBM simulations not supported in Vivado Simulator
    // (instantiate functional model instead)
    xilinx_hbm_4g_bfm i_hbm_4g_bfm (
        .AXI_00_ARADDR ( {'0, AXI_00_ARADDR} ),
        .AXI_00_AWADDR ( {'0, AXI_00_AWADDR} ),
        .AXI_01_ARADDR ( {'0, AXI_01_ARADDR} ),
        .AXI_01_AWADDR ( {'0, AXI_01_AWADDR} ),
        .AXI_02_ARADDR ( {'0, AXI_02_ARADDR} ),
        .AXI_02_AWADDR ( {'0, AXI_02_AWADDR} ),
        .AXI_03_ARADDR ( {'0, AXI_03_ARADDR} ),
        .AXI_03_AWADDR ( {'0, AXI_03_AWADDR} ),
        .AXI_04_ARADDR ( {'0, AXI_04_ARADDR} ),
        .AXI_04_AWADDR ( {'0, AXI_04_AWADDR} ),
        .AXI_05_ARADDR ( {'0, AXI_05_ARADDR} ),
        .AXI_05_AWADDR ( {'0, AXI_05_AWADDR} ),
        .AXI_06_ARADDR ( {'0, AXI_06_ARADDR} ),
        .AXI_06_AWADDR ( {'0, AXI_06_AWADDR} ),
        .AXI_07_ARADDR ( {'0, AXI_07_ARADDR} ),
        .AXI_07_AWADDR ( {'0, AXI_07_AWADDR} ),
        .AXI_08_ARADDR ( {'0, AXI_08_ARADDR} ),
        .AXI_08_AWADDR ( {'0, AXI_08_AWADDR} ),
        .AXI_09_ARADDR ( {'0, AXI_09_ARADDR} ),
        .AXI_09_AWADDR ( {'0, AXI_09_AWADDR} ),
        .AXI_10_ARADDR ( {'0, AXI_10_ARADDR} ),
        .AXI_10_AWADDR ( {'0, AXI_10_AWADDR} ),
        .AXI_11_ARADDR ( {'0, AXI_11_ARADDR} ),
        .AXI_11_AWADDR ( {'0, AXI_11_AWADDR} ),
        .AXI_12_ARADDR ( {'0, AXI_12_ARADDR} ),
        .AXI_12_AWADDR ( {'0, AXI_12_AWADDR} ),
        .AXI_13_ARADDR ( {'0, AXI_13_ARADDR} ),
        .AXI_13_AWADDR ( {'0, AXI_13_AWADDR} ),
        .AXI_14_ARADDR ( {'0, AXI_14_ARADDR} ),
        .AXI_14_AWADDR ( {'0, AXI_14_AWADDR} ),
        .AXI_15_ARADDR ( {'0, AXI_15_ARADDR} ),
        .AXI_15_AWADDR ( {'0, AXI_15_AWADDR} ),
        .*
    );

`else // SYNTHESIS
   
    // Xilinx HBM controller instantiation
    generate
        if (STACK == STACK_LEFT) begin : g__hbm_left
            xilinx_hbm_left i_xilinx_hbm_left (
                .AXI_00_ARADDR ( {'0, AXI_00_ARADDR} ),
                .AXI_00_AWADDR ( {'0, AXI_00_AWADDR} ),
                .AXI_01_ARADDR ( {'0, AXI_01_ARADDR} ),
                .AXI_01_AWADDR ( {'0, AXI_01_AWADDR} ),
                .AXI_02_ARADDR ( {'0, AXI_02_ARADDR} ),
                .AXI_02_AWADDR ( {'0, AXI_02_AWADDR} ),
                .AXI_03_ARADDR ( {'0, AXI_03_ARADDR} ),
                .AXI_03_AWADDR ( {'0, AXI_03_AWADDR} ),
                .AXI_04_ARADDR ( {'0, AXI_04_ARADDR} ),
                .AXI_04_AWADDR ( {'0, AXI_04_AWADDR} ),
                .AXI_05_ARADDR ( {'0, AXI_05_ARADDR} ),
                .AXI_05_AWADDR ( {'0, AXI_05_AWADDR} ),
                .AXI_06_ARADDR ( {'0, AXI_06_ARADDR} ),
                .AXI_06_AWADDR ( {'0, AXI_06_AWADDR} ),
                .AXI_07_ARADDR ( {'0, AXI_07_ARADDR} ),
                .AXI_07_AWADDR ( {'0, AXI_07_AWADDR} ),
                .AXI_08_ARADDR ( {'0, AXI_08_ARADDR} ),
                .AXI_08_AWADDR ( {'0, AXI_08_AWADDR} ),
                .AXI_09_ARADDR ( {'0, AXI_09_ARADDR} ),
                .AXI_09_AWADDR ( {'0, AXI_09_AWADDR} ),
                .AXI_10_ARADDR ( {'0, AXI_10_ARADDR} ),
                .AXI_10_AWADDR ( {'0, AXI_10_AWADDR} ),
                .AXI_11_ARADDR ( {'0, AXI_11_ARADDR} ),
                .AXI_11_AWADDR ( {'0, AXI_11_AWADDR} ),
                .AXI_12_ARADDR ( {'0, AXI_12_ARADDR} ),
                .AXI_12_AWADDR ( {'0, AXI_12_AWADDR} ),
                .AXI_13_ARADDR ( {'0, AXI_13_ARADDR} ),
                .AXI_13_AWADDR ( {'0, AXI_13_AWADDR} ),
                .AXI_14_ARADDR ( {'0, AXI_14_ARADDR} ),
                .AXI_14_AWADDR ( {'0, AXI_14_AWADDR} ),
                .AXI_15_ARADDR ( {'0, AXI_15_ARADDR} ),
                .AXI_15_AWADDR ( {'0, AXI_15_AWADDR} ),
                .*
            );
        end : g__hbm_left
        else begin : g__hbm_right
            xilinx_hbm_right i_xilinx_hbm_right (
                .AXI_00_ARADDR ( {'0, AXI_00_ARADDR} ),
                .AXI_00_AWADDR ( {'0, AXI_00_AWADDR} ),
                .AXI_01_ARADDR ( {'0, AXI_01_ARADDR} ),
                .AXI_01_AWADDR ( {'0, AXI_01_AWADDR} ),
                .AXI_02_ARADDR ( {'0, AXI_02_ARADDR} ),
                .AXI_02_AWADDR ( {'0, AXI_02_AWADDR} ),
                .AXI_03_ARADDR ( {'0, AXI_03_ARADDR} ),
                .AXI_03_AWADDR ( {'0, AXI_03_AWADDR} ),
                .AXI_04_ARADDR ( {'0, AXI_04_ARADDR} ),
                .AXI_04_AWADDR ( {'0, AXI_04_AWADDR} ),
                .AXI_05_ARADDR ( {'0, AXI_05_ARADDR} ),
                .AXI_05_AWADDR ( {'0, AXI_05_AWADDR} ),
                .AXI_06_ARADDR ( {'0, AXI_06_ARADDR} ),
                .AXI_06_AWADDR ( {'0, AXI_06_AWADDR} ),
                .AXI_07_ARADDR ( {'0, AXI_07_ARADDR} ),
                .AXI_07_AWADDR ( {'0, AXI_07_AWADDR} ),
                .AXI_08_ARADDR ( {'0, AXI_08_ARADDR} ),
                .AXI_08_AWADDR ( {'0, AXI_08_AWADDR} ),
                .AXI_09_ARADDR ( {'0, AXI_09_ARADDR} ),
                .AXI_09_AWADDR ( {'0, AXI_09_AWADDR} ),
                .AXI_10_ARADDR ( {'0, AXI_10_ARADDR} ),
                .AXI_10_AWADDR ( {'0, AXI_10_AWADDR} ),
                .AXI_11_ARADDR ( {'0, AXI_11_ARADDR} ),
                .AXI_11_AWADDR ( {'0, AXI_11_AWADDR} ),
                .AXI_12_ARADDR ( {'0, AXI_12_ARADDR} ),
                .AXI_12_AWADDR ( {'0, AXI_12_AWADDR} ),
                .AXI_13_ARADDR ( {'0, AXI_13_ARADDR} ),
                .AXI_13_AWADDR ( {'0, AXI_13_AWADDR} ),
                .AXI_14_ARADDR ( {'0, AXI_14_ARADDR} ),
                .AXI_14_AWADDR ( {'0, AXI_14_AWADDR} ),
                .AXI_15_ARADDR ( {'0, AXI_15_ARADDR} ),
                .AXI_15_AWADDR ( {'0, AXI_15_AWADDR} ),
                .*
            );
        end : g__hbm_right
    endgenerate
`endif

endmodule : xilinx_hbm_stack
