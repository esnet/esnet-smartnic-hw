module xilinx_hbm_4g_bfm #(
    parameter bit DEBUG = 1'b0
) (
    input  logic         HBM_REF_CLK_0,        // input wire HBM_REF_CLK_0
    input  logic         AXI_00_ACLK,          // input wire AXI_00_ACLK
    input  logic         AXI_00_ARESET_N,      // input wire AXI_00_ARESET_N
    input  logic [32:0]  AXI_00_ARADDR,        // input wire [32 : 0] AXI_00_ARADDR
    input  logic [1:0]   AXI_00_ARBURST,       // input wire [1 : 0] AXI_00_ARBURST
    input  logic [5:0]   AXI_00_ARID,          // input wire [5 : 0] AXI_00_ARID
    input  logic [3:0]   AXI_00_ARLEN,         // input wire [3 : 0] AXI_00_ARLEN
    input  logic [2:0]   AXI_00_ARSIZE,        // input wire [2 : 0] AXI_00_ARSIZE
    input  logic         AXI_00_ARVALID,       // input wire AXI_00_ARVALID
    input  logic [32:0]  AXI_00_AWADDR,        // input wire [32 : 0] AXI_00_AWADDR
    input  logic [1:0]   AXI_00_AWBURST,       // input wire [1 : 0] AXI_00_AWBURST
    input  logic [5:0]   AXI_00_AWID,          // input wire [5 : 0] AXI_00_AWID
    input  logic [3:0]   AXI_00_AWLEN,         // input wire [3 : 0] AXI_00_AWLEN
    input  logic [2:0]   AXI_00_AWSIZE,        // input wire [2 : 0] AXI_00_AWSIZE
    input  logic         AXI_00_AWVALID,       // input wire AXI_00_AWVALID
    input  logic         AXI_00_RREADY,        // input wire AXI_00_RREADY
    input  logic         AXI_00_BREADY,        // input wire AXI_00_BREADY
    input  logic [255:0] AXI_00_WDATA,         // input wire [255 : 0] AXI_00_WDATA
    input  logic         AXI_00_WLAST,         // input wire AXI_00_WLAST
    input  logic [31:0]  AXI_00_WSTRB,         // input wire [31 : 0] AXI_00_WSTRB
    input  logic [31:0]  AXI_00_WDATA_PARITY,  // input wire [31 : 0] AXI_00_WDATA_PARITY
    input  logic         AXI_00_WVALID,        // input wire AXI_00_WVALID
    input  logic         AXI_01_ACLK,          // input wire AXI_01_ACLK
    input  logic         AXI_01_ARESET_N,      // input wire AXI_01_ARESET_N
    input  logic [32:0]  AXI_01_ARADDR,        // input wire [32 : 0] AXI_01_ARADDR
    input  logic [1:0]   AXI_01_ARBURST,       // input wire [1 : 0] AXI_01_ARBURST
    input  logic [5:0]   AXI_01_ARID,          // input wire [5 : 0] AXI_01_ARID
    input  logic [3:0]   AXI_01_ARLEN,         // input wire [3 : 0] AXI_01_ARLEN
    input  logic [2:0]   AXI_01_ARSIZE,        // input wire [2 : 0] AXI_01_ARSIZE
    input  logic         AXI_01_ARVALID,       // input wire AXI_01_ARVALID
    input  logic [32:0]  AXI_01_AWADDR,        // input wire [32 : 0] AXI_01_AWADDR
    input  logic [1:0]   AXI_01_AWBURST,       // input wire [1 : 0] AXI_01_AWBURST
    input  logic [5:0]   AXI_01_AWID,          // input wire [5 : 0] AXI_01_AWID
    input  logic [3:0]   AXI_01_AWLEN,         // input wire [3 : 0] AXI_01_AWLEN
    input  logic [2:0]   AXI_01_AWSIZE,        // input wire [2 : 0] AXI_01_AWSIZE
    input  logic         AXI_01_AWVALID,       // input wire AXI_01_AWVALID
    input  logic         AXI_01_RREADY,        // input wire AXI_01_RREADY
    input  logic         AXI_01_BREADY,        // input wire AXI_01_BREADY
    input  logic [255:0] AXI_01_WDATA,         // input wire [255 : 0] AXI_01_WDATA
    input  logic         AXI_01_WLAST,         // input wire AXI_01_WLAST
    input  logic [31:0]  AXI_01_WSTRB,         // input wire [31 : 0] AXI_01_WSTRB
    input  logic [31:0]  AXI_01_WDATA_PARITY,  // input wire [31 : 0] AXI_01_WDATA_PARITY
    input  logic         AXI_01_WVALID,        // input wire AXI_01_WVALID
    input  logic         AXI_02_ACLK,          // input wire AXI_02_ACLK
    input  logic         AXI_02_ARESET_N,      // input wire AXI_02_ARESET_N
    input  logic [32:0]  AXI_02_ARADDR,        // input wire [32 : 0] AXI_02_ARADDR
    input  logic [1:0]   AXI_02_ARBURST,       // input wire [1 : 0] AXI_02_ARBURST
    input  logic [5:0]   AXI_02_ARID,          // input wire [5 : 0] AXI_02_ARID
    input  logic [3:0]   AXI_02_ARLEN,         // input wire [3 : 0] AXI_02_ARLEN
    input  logic [2:0]   AXI_02_ARSIZE,        // input wire [2 : 0] AXI_02_ARSIZE
    input  logic         AXI_02_ARVALID,       // input wire AXI_02_ARVALID
    input  logic [32:0]  AXI_02_AWADDR,        // input wire [32 : 0] AXI_02_AWADDR
    input  logic [1:0]   AXI_02_AWBURST,       // input wire [1 : 0] AXI_02_AWBURST
    input  logic [5:0]   AXI_02_AWID,          // input wire [5 : 0] AXI_02_AWID
    input  logic [3:0]   AXI_02_AWLEN,         // input wire [3 : 0] AXI_02_AWLEN
    input  logic [2:0]   AXI_02_AWSIZE,        // input wire [2 : 0] AXI_02_AWSIZE
    input  logic         AXI_02_AWVALID,       // input wire AXI_02_AWVALID
    input  logic         AXI_02_RREADY,        // input wire AXI_02_RREADY
    input  logic         AXI_02_BREADY,        // input wire AXI_02_BREADY
    input  logic [255:0] AXI_02_WDATA,         // input wire [255 : 0] AXI_02_WDATA
    input  logic         AXI_02_WLAST,         // input wire AXI_02_WLAST
    input  logic [31:0]  AXI_02_WSTRB,         // input wire [31 : 0] AXI_02_WSTRB
    input  logic [31:0]  AXI_02_WDATA_PARITY,  // input wire [31 : 0] AXI_02_WDATA_PARITY
    input  logic         AXI_02_WVALID,        // input wire AXI_02_WVALID
    input  logic         AXI_03_ACLK,          // input wire AXI_03_ACLK
    input  logic         AXI_03_ARESET_N,      // input wire AXI_03_ARESET_N
    input  logic [32:0]  AXI_03_ARADDR,        // input wire [32 : 0] AXI_03_ARADDR
    input  logic [1:0]   AXI_03_ARBURST,       // input wire [1 : 0] AXI_03_ARBURST
    input  logic [5:0]   AXI_03_ARID,          // input wire [5 : 0] AXI_03_ARID
    input  logic [3:0]   AXI_03_ARLEN,         // input wire [3 : 0] AXI_03_ARLEN
    input  logic [2:0]   AXI_03_ARSIZE,        // input wire [2 : 0] AXI_03_ARSIZE
    input  logic         AXI_03_ARVALID,       // input wire AXI_03_ARVALID
    input  logic [32:0]  AXI_03_AWADDR,        // input wire [32 : 0] AXI_03_AWADDR
    input  logic [1:0]   AXI_03_AWBURST,       // input wire [1 : 0] AXI_03_AWBURST
    input  logic [5:0]   AXI_03_AWID,          // input wire [5 : 0] AXI_03_AWID
    input  logic [3:0]   AXI_03_AWLEN,         // input wire [3 : 0] AXI_03_AWLEN
    input  logic [2:0]   AXI_03_AWSIZE,        // input wire [2 : 0] AXI_03_AWSIZE
    input  logic         AXI_03_AWVALID,       // input wire AXI_03_AWVALID
    input  logic         AXI_03_RREADY,        // input wire AXI_03_RREADY
    input  logic         AXI_03_BREADY,        // input wire AXI_03_BREADY
    input  logic [255:0] AXI_03_WDATA,         // input wire [255 : 0] AXI_03_WDATA
    input  logic         AXI_03_WLAST,         // input wire AXI_03_WLAST
    input  logic [31:0]  AXI_03_WSTRB,         // input wire [31 : 0] AXI_03_WSTRB
    input  logic [31:0]  AXI_03_WDATA_PARITY,  // input wire [31 : 0] AXI_03_WDATA_PARITY
    input  logic         AXI_03_WVALID,        // input wire AXI_03_WVALID
    input  logic         AXI_04_ACLK,          // input wire AXI_04_ACLK
    input  logic         AXI_04_ARESET_N,      // input wire AXI_04_ARESET_N
    input  logic [32:0]  AXI_04_ARADDR,        // input wire [32 : 0] AXI_04_ARADDR
    input  logic [1:0]   AXI_04_ARBURST,       // input wire [1 : 0] AXI_04_ARBURST
    input  logic [5:0]   AXI_04_ARID,          // input wire [5 : 0] AXI_04_ARID
    input  logic [3:0]   AXI_04_ARLEN,         // input wire [3 : 0] AXI_04_ARLEN
    input  logic [2:0]   AXI_04_ARSIZE,        // input wire [2 : 0] AXI_04_ARSIZE
    input  logic         AXI_04_ARVALID,       // input wire AXI_04_ARVALID
    input  logic [32:0]  AXI_04_AWADDR,        // input wire [32 : 0] AXI_04_AWADDR
    input  logic [1:0]   AXI_04_AWBURST,       // input wire [1 : 0] AXI_04_AWBURST
    input  logic [5:0]   AXI_04_AWID,          // input wire [5 : 0] AXI_04_AWID
    input  logic [3:0]   AXI_04_AWLEN,         // input wire [3 : 0] AXI_04_AWLEN
    input  logic [2:0]   AXI_04_AWSIZE,        // input wire [2 : 0] AXI_04_AWSIZE
    input  logic         AXI_04_AWVALID,       // input wire AXI_04_AWVALID
    input  logic         AXI_04_RREADY,        // input wire AXI_04_RREADY
    input  logic         AXI_04_BREADY,        // input wire AXI_04_BREADY
    input  logic [255:0] AXI_04_WDATA,         // input wire [255 : 0] AXI_04_WDATA
    input  logic         AXI_04_WLAST,         // input wire AXI_04_WLAST
    input  logic [31:0]  AXI_04_WSTRB,         // input wire [31 : 0] AXI_04_WSTRB
    input  logic [31:0]  AXI_04_WDATA_PARITY,  // input wire [31 : 0] AXI_04_WDATA_PARITY
    input  logic         AXI_04_WVALID,        // input wire AXI_04_WVALID
    input  logic         AXI_05_ACLK,          // input wire AXI_05_ACLK
    input  logic         AXI_05_ARESET_N,      // input wire AXI_05_ARESET_N
    input  logic [32:0]  AXI_05_ARADDR,        // input wire [32 : 0] AXI_05_ARADDR
    input  logic [1:0]   AXI_05_ARBURST,       // input wire [1 : 0] AXI_05_ARBURST
    input  logic [5:0]   AXI_05_ARID,          // input wire [5 : 0] AXI_05_ARID
    input  logic [3:0]   AXI_05_ARLEN,         // input wire [3 : 0] AXI_05_ARLEN
    input  logic [2:0]   AXI_05_ARSIZE,        // input wire [2 : 0] AXI_05_ARSIZE
    input  logic         AXI_05_ARVALID,       // input wire AXI_05_ARVALID
    input  logic [32:0]  AXI_05_AWADDR,        // input wire [32 : 0] AXI_05_AWADDR
    input  logic [1:0]   AXI_05_AWBURST,       // input wire [1 : 0] AXI_05_AWBURST
    input  logic [5:0]   AXI_05_AWID,          // input wire [5 : 0] AXI_05_AWID
    input  logic [3:0]   AXI_05_AWLEN,         // input wire [3 : 0] AXI_05_AWLEN
    input  logic [2:0]   AXI_05_AWSIZE,        // input wire [2 : 0] AXI_05_AWSIZE
    input  logic         AXI_05_AWVALID,       // input wire AXI_05_AWVALID
    input  logic         AXI_05_RREADY,        // input wire AXI_05_RREADY
    input  logic         AXI_05_BREADY,        // input wire AXI_05_BREADY
    input  logic [255:0] AXI_05_WDATA,         // input wire [255 : 0] AXI_05_WDATA
    input  logic         AXI_05_WLAST,         // input wire AXI_05_WLAST
    input  logic [31:0]  AXI_05_WSTRB,         // input wire [31 : 0] AXI_05_WSTRB
    input  logic [31:0]  AXI_05_WDATA_PARITY,  // input wire [31 : 0] AXI_05_WDATA_PARITY
    input  logic         AXI_05_WVALID,        // input wire AXI_05_WVALID
    input  logic         AXI_06_ACLK,          // input wire AXI_06_ACLK
    input  logic         AXI_06_ARESET_N,      // input wire AXI_06_ARESET_N
    input  logic [32:0]  AXI_06_ARADDR,        // input wire [32 : 0] AXI_06_ARADDR
    input  logic [1:0]   AXI_06_ARBURST,       // input wire [1 : 0] AXI_06_ARBURST
    input  logic [5:0]   AXI_06_ARID,          // input wire [5 : 0] AXI_06_ARID
    input  logic [3:0]   AXI_06_ARLEN,         // input wire [3 : 0] AXI_06_ARLEN
    input  logic [2:0]   AXI_06_ARSIZE,        // input wire [2 : 0] AXI_06_ARSIZE
    input  logic         AXI_06_ARVALID,       // input wire AXI_06_ARVALID
    input  logic [32:0]  AXI_06_AWADDR,        // input wire [32 : 0] AXI_06_AWADDR
    input  logic [1:0]   AXI_06_AWBURST,       // input wire [1 : 0] AXI_06_AWBURST
    input  logic [5:0]   AXI_06_AWID,          // input wire [5 : 0] AXI_06_AWID
    input  logic [3:0]   AXI_06_AWLEN,         // input wire [3 : 0] AXI_06_AWLEN
    input  logic [2:0]   AXI_06_AWSIZE,        // input wire [2 : 0] AXI_06_AWSIZE
    input  logic         AXI_06_AWVALID,       // input wire AXI_06_AWVALID
    input  logic         AXI_06_RREADY,        // input wire AXI_06_RREADY
    input  logic         AXI_06_BREADY,        // input wire AXI_06_BREADY
    input  logic [255:0] AXI_06_WDATA,         // input wire [255 : 0] AXI_06_WDATA
    input  logic         AXI_06_WLAST,         // input wire AXI_06_WLAST
    input  logic [31:0]  AXI_06_WSTRB,         // input wire [31 : 0] AXI_06_WSTRB
    input  logic [31:0]  AXI_06_WDATA_PARITY,  // input wire [31 : 0] AXI_06_WDATA_PARITY
    input  logic         AXI_06_WVALID,        // input wire AXI_06_WVALID
    input  logic         AXI_07_ACLK,          // input wire AXI_07_ACLK
    input  logic         AXI_07_ARESET_N,      // input wire AXI_07_ARESET_N
    input  logic [32:0]  AXI_07_ARADDR,        // input wire [32 : 0] AXI_07_ARADDR
    input  logic [1:0]   AXI_07_ARBURST,       // input wire [1 : 0] AXI_07_ARBURST
    input  logic [5:0]   AXI_07_ARID,          // input wire [5 : 0] AXI_07_ARID
    input  logic [3:0]   AXI_07_ARLEN,         // input wire [3 : 0] AXI_07_ARLEN
    input  logic [2:0]   AXI_07_ARSIZE,        // input wire [2 : 0] AXI_07_ARSIZE
    input  logic         AXI_07_ARVALID,       // input wire AXI_07_ARVALID
    input  logic [32:0]  AXI_07_AWADDR,        // input wire [32 : 0] AXI_07_AWADDR
    input  logic [1:0]   AXI_07_AWBURST,       // input wire [1 : 0] AXI_07_AWBURST
    input  logic [5:0]   AXI_07_AWID,          // input wire [5 : 0] AXI_07_AWID
    input  logic [3:0]   AXI_07_AWLEN,         // input wire [3 : 0] AXI_07_AWLEN
    input  logic [2:0]   AXI_07_AWSIZE,        // input wire [2 : 0] AXI_07_AWSIZE
    input  logic         AXI_07_AWVALID,       // input wire AXI_07_AWVALID
    input  logic         AXI_07_RREADY,        // input wire AXI_07_RREADY
    input  logic         AXI_07_BREADY,        // input wire AXI_07_BREADY
    input  logic [255:0] AXI_07_WDATA,         // input wire [255 : 0] AXI_07_WDATA
    input  logic         AXI_07_WLAST,         // input wire AXI_07_WLAST
    input  logic [31:0]  AXI_07_WSTRB,         // input wire [31 : 0] AXI_07_WSTRB
    input  logic [31:0]  AXI_07_WDATA_PARITY,  // input wire [31 : 0] AXI_07_WDATA_PARITY
    input  logic         AXI_07_WVALID,        // input wire AXI_07_WVALID
    input  logic         AXI_08_ACLK,          // input wire AXI_08_ACLK
    input  logic         AXI_08_ARESET_N,      // input wire AXI_08_ARESET_N
    input  logic [32:0]  AXI_08_ARADDR,        // input wire [32 : 0] AXI_08_ARADDR
    input  logic [1:0]   AXI_08_ARBURST,       // input wire [1 : 0] AXI_08_ARBURST
    input  logic [5:0]   AXI_08_ARID,          // input wire [5 : 0] AXI_08_ARID
    input  logic [3:0]   AXI_08_ARLEN,         // input wire [3 : 0] AXI_08_ARLEN
    input  logic [2:0]   AXI_08_ARSIZE,        // input wire [2 : 0] AXI_08_ARSIZE
    input  logic         AXI_08_ARVALID,       // input wire AXI_08_ARVALID
    input  logic [32:0]  AXI_08_AWADDR,        // input wire [32 : 0] AXI_08_AWADDR
    input  logic [1:0]   AXI_08_AWBURST,       // input wire [1 : 0] AXI_08_AWBURST
    input  logic [5:0]   AXI_08_AWID,          // input wire [5 : 0] AXI_08_AWID
    input  logic [3:0]   AXI_08_AWLEN,         // input wire [3 : 0] AXI_08_AWLEN
    input  logic [2:0]   AXI_08_AWSIZE,        // input wire [2 : 0] AXI_08_AWSIZE
    input  logic         AXI_08_AWVALID,       // input wire AXI_08_AWVALID
    input  logic         AXI_08_RREADY,        // input wire AXI_08_RREADY
    input  logic         AXI_08_BREADY,        // input wire AXI_08_BREADY
    input  logic [255:0] AXI_08_WDATA,         // input wire [255 : 0] AXI_08_WDATA
    input  logic         AXI_08_WLAST,         // input wire AXI_08_WLAST
    input  logic [31:0]  AXI_08_WSTRB,         // input wire [31 : 0] AXI_08_WSTRB
    input  logic [31:0]  AXI_08_WDATA_PARITY,  // input wire [31 : 0] AXI_08_WDATA_PARITY
    input  logic         AXI_08_WVALID,        // input wire AXI_08_WVALID
    input  logic         AXI_09_ACLK,          // input wire AXI_09_ACLK
    input  logic         AXI_09_ARESET_N,      // input wire AXI_09_ARESET_N
    input  logic [32:0]  AXI_09_ARADDR,        // input wire [32 : 0] AXI_09_ARADDR
    input  logic [1:0]   AXI_09_ARBURST,       // input wire [1 : 0] AXI_09_ARBURST
    input  logic [5:0]   AXI_09_ARID,          // input wire [5 : 0] AXI_09_ARID
    input  logic [3:0]   AXI_09_ARLEN,         // input wire [3 : 0] AXI_09_ARLEN
    input  logic [2:0]   AXI_09_ARSIZE,        // input wire [2 : 0] AXI_09_ARSIZE
    input  logic         AXI_09_ARVALID,       // input wire AXI_09_ARVALID
    input  logic [32:0]  AXI_09_AWADDR,        // input wire [32 : 0] AXI_09_AWADDR
    input  logic [1:0]   AXI_09_AWBURST,       // input wire [1 : 0] AXI_09_AWBURST
    input  logic [5:0]   AXI_09_AWID,          // input wire [5 : 0] AXI_09_AWID
    input  logic [3:0]   AXI_09_AWLEN,         // input wire [3 : 0] AXI_09_AWLEN
    input  logic [2:0]   AXI_09_AWSIZE,        // input wire [2 : 0] AXI_09_AWSIZE
    input  logic         AXI_09_AWVALID,       // input wire AXI_09_AWVALID
    input  logic         AXI_09_RREADY,        // input wire AXI_09_RREADY
    input  logic         AXI_09_BREADY,        // input wire AXI_09_BREADY
    input  logic [255:0] AXI_09_WDATA,         // input wire [255 : 0] AXI_09_WDATA
    input  logic         AXI_09_WLAST,         // input wire AXI_09_WLAST
    input  logic [31:0]  AXI_09_WSTRB,         // input wire [31 : 0] AXI_09_WSTRB
    input  logic [31:0]  AXI_09_WDATA_PARITY,  // input wire [31 : 0] AXI_09_WDATA_PARITY
    input  logic         AXI_09_WVALID,        // input wire AXI_09_WVALID
    input  logic         AXI_10_ACLK,          // input wire AXI_10_ACLK
    input  logic         AXI_10_ARESET_N,      // input wire AXI_10_ARESET_N
    input  logic [32:0]  AXI_10_ARADDR,        // input wire [32 : 0] AXI_10_ARADDR
    input  logic [1:0]   AXI_10_ARBURST,       // input wire [1 : 0] AXI_10_ARBURST
    input  logic [5:0]   AXI_10_ARID,          // input wire [5 : 0] AXI_10_ARID
    input  logic [3:0]   AXI_10_ARLEN,         // input wire [3 : 0] AXI_10_ARLEN
    input  logic [2:0]   AXI_10_ARSIZE,        // input wire [2 : 0] AXI_10_ARSIZE
    input  logic         AXI_10_ARVALID,       // input wire AXI_10_ARVALID
    input  logic [32:0]  AXI_10_AWADDR,        // input wire [32 : 0] AXI_10_AWADDR
    input  logic [1:0]   AXI_10_AWBURST,       // input wire [1 : 0] AXI_10_AWBURST
    input  logic [5:0]   AXI_10_AWID,          // input wire [5 : 0] AXI_10_AWID
    input  logic [3:0]   AXI_10_AWLEN,         // input wire [3 : 0] AXI_10_AWLEN
    input  logic [2:0]   AXI_10_AWSIZE,        // input wire [2 : 0] AXI_10_AWSIZE
    input  logic         AXI_10_AWVALID,       // input wire AXI_10_AWVALID
    input  logic         AXI_10_RREADY,        // input wire AXI_10_RREADY
    input  logic         AXI_10_BREADY,        // input wire AXI_10_BREADY
    input  logic [255:0] AXI_10_WDATA,         // input wire [255 : 0] AXI_10_WDATA
    input  logic         AXI_10_WLAST,         // input wire AXI_10_WLAST
    input  logic [31:0]  AXI_10_WSTRB,         // input wire [31 : 0] AXI_10_WSTRB
    input  logic [31:0]  AXI_10_WDATA_PARITY,  // input wire [31 : 0] AXI_10_WDATA_PARITY
    input  logic         AXI_10_WVALID,        // input wire AXI_10_WVALID
    input  logic         AXI_11_ACLK,          // input wire AXI_11_ACLK
    input  logic         AXI_11_ARESET_N,      // input wire AXI_11_ARESET_N
    input  logic [32:0]  AXI_11_ARADDR,        // input wire [32 : 0] AXI_11_ARADDR
    input  logic [1:0]   AXI_11_ARBURST,       // input wire [1 : 0] AXI_11_ARBURST
    input  logic [5:0]   AXI_11_ARID,          // input wire [5 : 0] AXI_11_ARID
    input  logic [3:0]   AXI_11_ARLEN,         // input wire [3 : 0] AXI_11_ARLEN
    input  logic [2:0]   AXI_11_ARSIZE,        // input wire [2 : 0] AXI_11_ARSIZE
    input  logic         AXI_11_ARVALID,       // input wire AXI_11_ARVALID
    input  logic [32:0]  AXI_11_AWADDR,        // input wire [32 : 0] AXI_11_AWADDR
    input  logic [1:0]   AXI_11_AWBURST,       // input wire [1 : 0] AXI_11_AWBURST
    input  logic [5:0]   AXI_11_AWID,          // input wire [5 : 0] AXI_11_AWID
    input  logic [3:0]   AXI_11_AWLEN,         // input wire [3 : 0] AXI_11_AWLEN
    input  logic [2:0]   AXI_11_AWSIZE,        // input wire [2 : 0] AXI_11_AWSIZE
    input  logic         AXI_11_AWVALID,       // input wire AXI_11_AWVALID
    input  logic         AXI_11_RREADY,        // input wire AXI_11_RREADY
    input  logic         AXI_11_BREADY,        // input wire AXI_11_BREADY
    input  logic [255:0] AXI_11_WDATA,         // input wire [255 : 0] AXI_11_WDATA
    input  logic         AXI_11_WLAST,         // input wire AXI_11_WLAST
    input  logic [31:0]  AXI_11_WSTRB,         // input wire [31 : 0] AXI_11_WSTRB
    input  logic [31:0]  AXI_11_WDATA_PARITY,  // input wire [31 : 0] AXI_11_WDATA_PARITY
    input  logic         AXI_11_WVALID,        // input wire AXI_11_WVALID
    input  logic         AXI_12_ACLK,          // input wire AXI_12_ACLK
    input  logic         AXI_12_ARESET_N,      // input wire AXI_12_ARESET_N
    input  logic [32:0]  AXI_12_ARADDR,        // input wire [32 : 0] AXI_12_ARADDR
    input  logic [1:0]   AXI_12_ARBURST,       // input wire [1 : 0] AXI_12_ARBURST
    input  logic [5:0]   AXI_12_ARID,          // input wire [5 : 0] AXI_12_ARID
    input  logic [3:0]   AXI_12_ARLEN,         // input wire [3 : 0] AXI_12_ARLEN
    input  logic [2:0]   AXI_12_ARSIZE,        // input wire [2 : 0] AXI_12_ARSIZE
    input  logic         AXI_12_ARVALID,       // input wire AXI_12_ARVALID
    input  logic [32:0]  AXI_12_AWADDR,        // input wire [32 : 0] AXI_12_AWADDR
    input  logic [1:0]   AXI_12_AWBURST,       // input wire [1 : 0] AXI_12_AWBURST
    input  logic [5:0]   AXI_12_AWID,          // input wire [5 : 0] AXI_12_AWID
    input  logic [3:0]   AXI_12_AWLEN,         // input wire [3 : 0] AXI_12_AWLEN
    input  logic [2:0]   AXI_12_AWSIZE,        // input wire [2 : 0] AXI_12_AWSIZE
    input  logic         AXI_12_AWVALID,       // input wire AXI_12_AWVALID
    input  logic         AXI_12_RREADY,        // input wire AXI_12_RREADY
    input  logic         AXI_12_BREADY,        // input wire AXI_12_BREADY
    input  logic [255:0] AXI_12_WDATA,         // input wire [255 : 0] AXI_12_WDATA
    input  logic         AXI_12_WLAST,         // input wire AXI_12_WLAST
    input  logic [31:0]  AXI_12_WSTRB,         // input wire [31 : 0] AXI_12_WSTRB
    input  logic [31:0]  AXI_12_WDATA_PARITY,  // input wire [31 : 0] AXI_12_WDATA_PARITY
    input  logic         AXI_12_WVALID,        // input wire AXI_12_WVALID
    input  logic         AXI_13_ACLK,          // input wire AXI_13_ACLK
    input  logic         AXI_13_ARESET_N,      // input wire AXI_13_ARESET_N
    input  logic [32:0]  AXI_13_ARADDR,        // input wire [32 : 0] AXI_13_ARADDR
    input  logic [1:0]   AXI_13_ARBURST,       // input wire [1 : 0] AXI_13_ARBURST
    input  logic [5:0]   AXI_13_ARID,          // input wire [5 : 0] AXI_13_ARID
    input  logic [3:0]   AXI_13_ARLEN,         // input wire [3 : 0] AXI_13_ARLEN
    input  logic [2:0]   AXI_13_ARSIZE,        // input wire [2 : 0] AXI_13_ARSIZE
    input  logic         AXI_13_ARVALID,       // input wire AXI_13_ARVALID
    input  logic [32:0]  AXI_13_AWADDR,        // input wire [32 : 0] AXI_13_AWADDR
    input  logic [1:0]   AXI_13_AWBURST,       // input wire [1 : 0] AXI_13_AWBURST
    input  logic [5:0]   AXI_13_AWID,          // input wire [5 : 0] AXI_13_AWID
    input  logic [3:0]   AXI_13_AWLEN,         // input wire [3 : 0] AXI_13_AWLEN
    input  logic [2:0]   AXI_13_AWSIZE,        // input wire [2 : 0] AXI_13_AWSIZE
    input  logic         AXI_13_AWVALID,       // input wire AXI_13_AWVALID
    input  logic         AXI_13_RREADY,        // input wire AXI_13_RREADY
    input  logic         AXI_13_BREADY,        // input wire AXI_13_BREADY
    input  logic [255:0] AXI_13_WDATA,         // input wire [255 : 0] AXI_13_WDATA
    input  logic         AXI_13_WLAST,         // input wire AXI_13_WLAST
    input  logic [31:0]  AXI_13_WSTRB,         // input wire [31 : 0] AXI_13_WSTRB
    input  logic [31:0]  AXI_13_WDATA_PARITY,  // input wire [31 : 0] AXI_13_WDATA_PARITY
    input  logic         AXI_13_WVALID,        // input wire AXI_13_WVALID
    input  logic         AXI_14_ACLK,          // input wire AXI_14_ACLK
    input  logic         AXI_14_ARESET_N,      // input wire AXI_14_ARESET_N
    input  logic [32:0]  AXI_14_ARADDR,        // input wire [32 : 0] AXI_14_ARADDR
    input  logic [1:0]   AXI_14_ARBURST,       // input wire [1 : 0] AXI_14_ARBURST
    input  logic [5:0]   AXI_14_ARID,          // input wire [5 : 0] AXI_14_ARID
    input  logic [3:0]   AXI_14_ARLEN,         // input wire [3 : 0] AXI_14_ARLEN
    input  logic [2:0]   AXI_14_ARSIZE,        // input wire [2 : 0] AXI_14_ARSIZE
    input  logic         AXI_14_ARVALID,       // input wire AXI_14_ARVALID
    input  logic [32:0]  AXI_14_AWADDR,        // input wire [32 : 0] AXI_14_AWADDR
    input  logic [1:0]   AXI_14_AWBURST,       // input wire [1 : 0] AXI_14_AWBURST
    input  logic [5:0]   AXI_14_AWID,          // input wire [5 : 0] AXI_14_AWID
    input  logic [3:0]   AXI_14_AWLEN,         // input wire [3 : 0] AXI_14_AWLEN
    input  logic [2:0]   AXI_14_AWSIZE,        // input wire [2 : 0] AXI_14_AWSIZE
    input  logic         AXI_14_AWVALID,       // input wire AXI_14_AWVALID
    input  logic         AXI_14_RREADY,        // input wire AXI_14_RREADY
    input  logic         AXI_14_BREADY,        // input wire AXI_14_BREADY
    input  logic [255:0] AXI_14_WDATA,         // input wire [255 : 0] AXI_14_WDATA
    input  logic         AXI_14_WLAST,         // input wire AXI_14_WLAST
    input  logic [31:0]  AXI_14_WSTRB,         // input wire [31 : 0] AXI_14_WSTRB
    input  logic [31:0]  AXI_14_WDATA_PARITY,  // input wire [31 : 0] AXI_14_WDATA_PARITY
    input  logic         AXI_14_WVALID,        // input wire AXI_14_WVALID
    input  logic         AXI_15_ACLK,          // input wire AXI_15_ACLK
    input  logic         AXI_15_ARESET_N,      // input wire AXI_15_ARESET_N
    input  logic [32:0]  AXI_15_ARADDR,        // input wire [32 : 0] AXI_15_ARADDR
    input  logic [1:0]   AXI_15_ARBURST,       // input wire [1 : 0] AXI_15_ARBURST
    input  logic [5:0]   AXI_15_ARID,          // input wire [5 : 0] AXI_15_ARID
    input  logic [3:0]   AXI_15_ARLEN,         // input wire [3 : 0] AXI_15_ARLEN
    input  logic [2:0]   AXI_15_ARSIZE,        // input wire [2 : 0] AXI_15_ARSIZE
    input  logic         AXI_15_ARVALID,       // input wire AXI_15_ARVALID
    input  logic [32:0]  AXI_15_AWADDR,        // input wire [32 : 0] AXI_15_AWADDR
    input  logic [1:0]   AXI_15_AWBURST,       // input wire [1 : 0] AXI_15_AWBURST
    input  logic [5:0]   AXI_15_AWID,          // input wire [5 : 0] AXI_15_AWID
    input  logic [3:0]   AXI_15_AWLEN,         // input wire [3 : 0] AXI_15_AWLEN
    input  logic [2:0]   AXI_15_AWSIZE,        // input wire [2 : 0] AXI_15_AWSIZE
    input  logic         AXI_15_AWVALID,       // input wire AXI_15_AWVALID
    input  logic         AXI_15_RREADY,        // input wire AXI_15_RREADY
    input  logic         AXI_15_BREADY,        // input wire AXI_15_BREADY
    input  logic [255:0] AXI_15_WDATA,         // input wire [255 : 0] AXI_15_WDATA
    input  logic         AXI_15_WLAST,         // input wire AXI_15_WLAST
    input  logic [31:0]  AXI_15_WSTRB,         // input wire [31 : 0] AXI_15_WSTRB
    input  logic [31:0]  AXI_15_WDATA_PARITY,  // input wire [31 : 0] AXI_15_WDATA_PARITY
    input  logic         AXI_15_WVALID,        // input wire AXI_15_WVALID
    input  logic [31:0]  APB_0_PWDATA,         // input wire [31 : 0] APB_0_PWDATA
    input  logic [21:0]  APB_0_PADDR,          // input wire [21 : 0] APB_0_PADDR
    input  logic         APB_0_PCLK,           // input wire APB_0_PCLK
    input  logic         APB_0_PENABLE,        // input wire APB_0_PENABLE
    input  logic         APB_0_PRESET_N,       // input wire APB_0_PRESET_N
    input  logic         APB_0_PSEL,           // input wire APB_0_PSEL
    input  logic         APB_0_PWRITE,         // input wire APB_0_PWRITE
    output logic         AXI_00_ARREADY,       // output wire AXI_00_ARREADY
    output logic         AXI_00_AWREADY,       // output wire AXI_00_AWREADY
    output logic [31:0]  AXI_00_RDATA_PARITY,  // output wire [31 : 0] AXI_00_RDATA_PARITY
    output logic [255:0] AXI_00_RDATA,         // output wire [255 : 0] AXI_00_RDATA
    output logic [5:0]   AXI_00_RID,           // output wire [5 : 0] AXI_00_RID
    output logic         AXI_00_RLAST,         // output wire AXI_00_RLAST
    output logic [1:0]   AXI_00_RRESP,         // output wire [1 : 0] AXI_00_RRESP
    output logic         AXI_00_RVALID,        // output wire AXI_00_RVALID
    output logic         AXI_00_WREADY,        // output wire AXI_00_WREADY
    output logic [5:0]   AXI_00_BID,           // output wire [5 : 0] AXI_00_BID
    output logic [1:0]   AXI_00_BRESP,         // output wire [1 : 0] AXI_00_BRESP
    output logic         AXI_00_BVALID,        // output wire AXI_00_BVALID
    output logic         AXI_01_ARREADY,       // output wire AXI_01_ARREADY
    output logic         AXI_01_AWREADY,       // output wire AXI_01_AWREADY
    output logic [31:0]  AXI_01_RDATA_PARITY,  // output wire [31 : 0] AXI_01_RDATA_PARITY
    output logic [255:0] AXI_01_RDATA,         // output wire [255 : 0] AXI_01_RDATA
    output logic [5:0]   AXI_01_RID,           // output wire [5 : 0] AXI_01_RID
    output logic         AXI_01_RLAST,         // output wire AXI_01_RLAST
    output logic [1:0]   AXI_01_RRESP,         // output wire [1 : 0] AXI_01_RRESP
    output logic         AXI_01_RVALID,        // output wire AXI_01_RVALID
    output logic         AXI_01_WREADY,        // output wire AXI_01_WREADY
    output logic [5:0]   AXI_01_BID,           // output wire [5 : 0] AXI_01_BID
    output logic [1:0]   AXI_01_BRESP,         // output wire [1 : 0] AXI_01_BRESP
    output logic         AXI_01_BVALID,        // output wire AXI_01_BVALID
    output logic         AXI_02_ARREADY,       // output wire AXI_02_ARREADY
    output logic         AXI_02_AWREADY,       // output wire AXI_02_AWREADY
    output logic [31:0]  AXI_02_RDATA_PARITY,  // output wire [31 : 0] AXI_02_RDATA_PARITY
    output logic [255:0] AXI_02_RDATA,         // output wire [255 : 0] AXI_02_RDATA
    output logic [5:0]   AXI_02_RID,           // output wire [5 : 0] AXI_02_RID
    output logic         AXI_02_RLAST,         // output wire AXI_02_RLAST
    output logic [1:0]   AXI_02_RRESP,         // output wire [1 : 0] AXI_02_RRESP
    output logic         AXI_02_RVALID,        // output wire AXI_02_RVALID
    output logic         AXI_02_WREADY,        // output wire AXI_02_WREADY
    output logic [5:0]   AXI_02_BID,           // output wire [5 : 0] AXI_02_BID
    output logic [1:0]   AXI_02_BRESP,         // output wire [1 : 0] AXI_02_BRESP
    output logic         AXI_02_BVALID,        // output wire AXI_02_BVALID
    output logic         AXI_03_ARREADY,       // output wire AXI_03_ARREADY
    output logic         AXI_03_AWREADY,       // output wire AXI_03_AWREADY
    output logic [31:0]  AXI_03_RDATA_PARITY,  // output wire [31 : 0] AXI_03_RDATA_PARITY
    output logic [255:0] AXI_03_RDATA,         // output wire [255 : 0] AXI_03_RDATA
    output logic [5:0]   AXI_03_RID,           // output wire [5 : 0] AXI_03_RID
    output logic         AXI_03_RLAST,         // output wire AXI_03_RLAST
    output logic [1:0]   AXI_03_RRESP,         // output wire [1 : 0] AXI_03_RRESP
    output logic         AXI_03_RVALID,        // output wire AXI_03_RVALID
    output logic         AXI_03_WREADY,        // output wire AXI_03_WREADY
    output logic [5:0]   AXI_03_BID,           // output wire [5 : 0] AXI_03_BID
    output logic [1:0]   AXI_03_BRESP,         // output wire [1 : 0] AXI_03_BRESP
    output logic         AXI_03_BVALID,        // output wire AXI_03_BVALID
    output logic         AXI_04_ARREADY,       // output wire AXI_04_ARREADY
    output logic         AXI_04_AWREADY,       // output wire AXI_04_AWREADY
    output logic [31:0]  AXI_04_RDATA_PARITY,  // output wire [31 : 0] AXI_04_RDATA_PARITY
    output logic [255:0] AXI_04_RDATA,         // output wire [255 : 0] AXI_04_RDATA
    output logic [5:0]   AXI_04_RID,           // output wire [5 : 0] AXI_04_RID
    output logic         AXI_04_RLAST,         // output wire AXI_04_RLAST
    output logic [1:0]   AXI_04_RRESP,         // output wire [1 : 0] AXI_04_RRESP
    output logic         AXI_04_RVALID,        // output wire AXI_04_RVALID
    output logic         AXI_04_WREADY,        // output wire AXI_04_WREADY
    output logic [5:0]   AXI_04_BID,           // output wire [5 : 0] AXI_04_BID
    output logic [1:0]   AXI_04_BRESP,         // output wire [1 : 0] AXI_04_BRESP
    output logic         AXI_04_BVALID,        // output wire AXI_04_BVALID
    output logic         AXI_05_ARREADY,       // output wire AXI_05_ARREADY
    output logic         AXI_05_AWREADY,       // output wire AXI_05_AWREADY
    output logic [31:0]  AXI_05_RDATA_PARITY,  // output wire [31 : 0] AXI_05_RDATA_PARITY
    output logic [255:0] AXI_05_RDATA,         // output wire [255 : 0] AXI_05_RDATA
    output logic [5:0]   AXI_05_RID,           // output wire [5 : 0] AXI_05_RID
    output logic         AXI_05_RLAST,         // output wire AXI_05_RLAST
    output logic [1:0]   AXI_05_RRESP,         // output wire [1 : 0] AXI_05_RRESP
    output logic         AXI_05_RVALID,        // output wire AXI_05_RVALID
    output logic         AXI_05_WREADY,        // output wire AXI_05_WREADY
    output logic [5:0]   AXI_05_BID,           // output wire [5 : 0] AXI_05_BID
    output logic [1:0]   AXI_05_BRESP,         // output wire [1 : 0] AXI_05_BRESP
    output logic         AXI_05_BVALID,        // output wire AXI_05_BVALID
    output logic         AXI_06_ARREADY,       // output wire AXI_06_ARREADY
    output logic         AXI_06_AWREADY,       // output wire AXI_06_AWREADY
    output logic [31:0]  AXI_06_RDATA_PARITY,  // output wire [31 : 0] AXI_06_RDATA_PARITY
    output logic [255:0] AXI_06_RDATA,         // output wire [255 : 0] AXI_06_RDATA
    output logic [5:0]   AXI_06_RID,           // output wire [5 : 0] AXI_06_RID
    output logic         AXI_06_RLAST,         // output wire AXI_06_RLAST
    output logic [1:0]   AXI_06_RRESP,         // output wire [1 : 0] AXI_06_RRESP
    output logic         AXI_06_RVALID,        // output wire AXI_06_RVALID
    output logic         AXI_06_WREADY,        // output wire AXI_06_WREADY
    output logic [5:0]   AXI_06_BID,           // output wire [5 : 0] AXI_06_BID
    output logic [1:0]   AXI_06_BRESP,         // output wire [1 : 0] AXI_06_BRESP
    output logic         AXI_06_BVALID,        // output wire AXI_06_BVALID
    output logic         AXI_07_ARREADY,       // output wire AXI_07_ARREADY
    output logic         AXI_07_AWREADY,       // output wire AXI_07_AWREADY
    output logic [31:0]  AXI_07_RDATA_PARITY,  // output wire [31 : 0] AXI_07_RDATA_PARITY
    output logic [255:0] AXI_07_RDATA,         // output wire [255 : 0] AXI_07_RDATA
    output logic [5:0]   AXI_07_RID,           // output wire [5 : 0] AXI_07_RID
    output logic         AXI_07_RLAST,         // output wire AXI_07_RLAST
    output logic [1:0]   AXI_07_RRESP,         // output wire [1 : 0] AXI_07_RRESP
    output logic         AXI_07_RVALID,        // output wire AXI_07_RVALID
    output logic         AXI_07_WREADY,        // output wire AXI_07_WREADY
    output logic [5:0]   AXI_07_BID,           // output wire [5 : 0] AXI_07_BID
    output logic [1:0]   AXI_07_BRESP,         // output wire [1 : 0] AXI_07_BRESP
    output logic         AXI_07_BVALID,        // output wire AXI_07_BVALID
    output logic         AXI_08_ARREADY,       // output wire AXI_08_ARREADY
    output logic         AXI_08_AWREADY,       // output wire AXI_08_AWREADY
    output logic [31:0]  AXI_08_RDATA_PARITY,  // output wire [31 : 0] AXI_08_RDATA_PARITY
    output logic [255:0] AXI_08_RDATA,         // output wire [255 : 0] AXI_08_RDATA
    output logic [5:0]   AXI_08_RID,           // output wire [5 : 0] AXI_08_RID
    output logic         AXI_08_RLAST,         // output wire AXI_08_RLAST
    output logic [1:0]   AXI_08_RRESP,         // output wire [1 : 0] AXI_08_RRESP
    output logic         AXI_08_RVALID,        // output wire AXI_08_RVALID
    output logic         AXI_08_WREADY,        // output wire AXI_08_WREADY
    output logic [5:0]   AXI_08_BID,           // output wire [5 : 0] AXI_08_BID
    output logic [1:0]   AXI_08_BRESP,         // output wire [1 : 0] AXI_08_BRESP
    output logic         AXI_08_BVALID,        // output wire AXI_08_BVALID
    output logic         AXI_09_ARREADY,       // output wire AXI_09_ARREADY
    output logic         AXI_09_AWREADY,       // output wire AXI_09_AWREADY
    output logic [31:0]  AXI_09_RDATA_PARITY,  // output wire [31 : 0] AXI_09_RDATA_PARITY
    output logic [255:0] AXI_09_RDATA,         // output wire [255 : 0] AXI_09_RDATA
    output logic [5:0]   AXI_09_RID,           // output wire [5 : 0] AXI_09_RID
    output logic         AXI_09_RLAST,         // output wire AXI_09_RLAST
    output logic [1:0]   AXI_09_RRESP,         // output wire [1 : 0] AXI_09_RRESP
    output logic         AXI_09_RVALID,        // output wire AXI_09_RVALID
    output logic         AXI_09_WREADY,        // output wire AXI_09_WREADY
    output logic [5:0]   AXI_09_BID,           // output wire [5 : 0] AXI_09_BID
    output logic [1:0]   AXI_09_BRESP,         // output wire [1 : 0] AXI_09_BRESP
    output logic         AXI_09_BVALID,        // output wire AXI_09_BVALID
    output logic         AXI_10_ARREADY,       // output wire AXI_10_ARREADY
    output logic         AXI_10_AWREADY,       // output wire AXI_10_AWREADY
    output logic [31:0]  AXI_10_RDATA_PARITY,  // output wire [31 : 0] AXI_10_RDATA_PARITY
    output logic [255:0] AXI_10_RDATA,         // output wire [255 : 0] AXI_10_RDATA
    output logic [5:0]   AXI_10_RID,           // output wire [5 : 0] AXI_10_RID
    output logic         AXI_10_RLAST,         // output wire AXI_10_RLAST
    output logic [1:0]   AXI_10_RRESP,         // output wire [1 : 0] AXI_10_RRESP
    output logic         AXI_10_RVALID,        // output wire AXI_10_RVALID
    output logic         AXI_10_WREADY,        // output wire AXI_10_WREADY
    output logic [5:0]   AXI_10_BID,           // output wire [5 : 0] AXI_10_BID
    output logic [1:0]   AXI_10_BRESP,         // output wire [1 : 0] AXI_10_BRESP
    output logic         AXI_10_BVALID,        // output wire AXI_10_BVALID
    output logic         AXI_11_ARREADY,       // output wire AXI_11_ARREADY
    output logic         AXI_11_AWREADY,       // output wire AXI_11_AWREADY
    output logic [31:0]  AXI_11_RDATA_PARITY,  // output wire [31 : 0] AXI_11_RDATA_PARITY
    output logic [255:0] AXI_11_RDATA,         // output wire [255 : 0] AXI_11_RDATA
    output logic [5:0]   AXI_11_RID,           // output wire [5 : 0] AXI_11_RID
    output logic         AXI_11_RLAST,         // output wire AXI_11_RLAST
    output logic [1:0]   AXI_11_RRESP,         // output wire [1 : 0] AXI_11_RRESP
    output logic         AXI_11_RVALID,        // output wire AXI_11_RVALID
    output logic         AXI_11_WREADY,        // output wire AXI_11_WREADY
    output logic [5:0]   AXI_11_BID,           // output wire [5 : 0] AXI_11_BID
    output logic [1:0]   AXI_11_BRESP,         // output wire [1 : 0] AXI_11_BRESP
    output logic         AXI_11_BVALID,        // output wire AXI_11_BVALID
    output logic         AXI_12_ARREADY,       // output wire AXI_12_ARREADY
    output logic         AXI_12_AWREADY,       // output wire AXI_12_AWREADY
    output logic [31:0]  AXI_12_RDATA_PARITY,  // output wire [31 : 0] AXI_12_RDATA_PARITY
    output logic [255:0] AXI_12_RDATA,         // output wire [255 : 0] AXI_12_RDATA
    output logic [5:0]   AXI_12_RID,           // output wire [5 : 0] AXI_12_RID
    output logic         AXI_12_RLAST,         // output wire AXI_12_RLAST
    output logic [1:0]   AXI_12_RRESP,         // output wire [1 : 0] AXI_12_RRESP
    output logic         AXI_12_RVALID,        // output wire AXI_12_RVALID
    output logic         AXI_12_WREADY,        // output wire AXI_12_WREADY
    output logic [5:0]   AXI_12_BID,           // output wire [5 : 0] AXI_12_BID
    output logic [1:0]   AXI_12_BRESP,         // output wire [1 : 0] AXI_12_BRESP
    output logic         AXI_12_BVALID,        // output wire AXI_12_BVALID
    output logic         AXI_13_ARREADY,       // output wire AXI_13_ARREADY
    output logic         AXI_13_AWREADY,       // output wire AXI_13_AWREADY
    output logic [31:0]  AXI_13_RDATA_PARITY,  // output wire [31 : 0] AXI_13_RDATA_PARITY
    output logic [255:0] AXI_13_RDATA,         // output wire [255 : 0] AXI_13_RDATA
    output logic [5:0]   AXI_13_RID,           // output wire [5 : 0] AXI_13_RID
    output logic         AXI_13_RLAST,         // output wire AXI_13_RLAST
    output logic [1:0]   AXI_13_RRESP,         // output wire [1 : 0] AXI_13_RRESP
    output logic         AXI_13_RVALID,        // output wire AXI_13_RVALID
    output logic         AXI_13_WREADY,        // output wire AXI_13_WREADY
    output logic [5:0]   AXI_13_BID,           // output wire [5 : 0] AXI_13_BID
    output logic [1:0]   AXI_13_BRESP,         // output wire [1 : 0] AXI_13_BRESP
    output logic         AXI_13_BVALID,        // output wire AXI_13_BVALID
    output logic         AXI_14_ARREADY,       // output wire AXI_14_ARREADY
    output logic         AXI_14_AWREADY,       // output wire AXI_14_AWREADY
    output logic [31:0]  AXI_14_RDATA_PARITY,  // output wire [31 : 0] AXI_14_RDATA_PARITY
    output logic [255:0] AXI_14_RDATA,         // output wire [255 : 0] AXI_14_RDATA
    output logic [5:0]   AXI_14_RID,           // output wire [5 : 0] AXI_14_RID
    output logic         AXI_14_RLAST,         // output wire AXI_14_RLAST
    output logic [1:0]   AXI_14_RRESP,         // output wire [1 : 0] AXI_14_RRESP
    output logic         AXI_14_RVALID,        // output wire AXI_14_RVALID
    output logic         AXI_14_WREADY,        // output wire AXI_14_WREADY
    output logic [5:0]   AXI_14_BID,           // output wire [5 : 0] AXI_14_BID
    output logic [1:0]   AXI_14_BRESP,         // output wire [1 : 0] AXI_14_BRESP
    output logic         AXI_14_BVALID,        // output wire AXI_14_BVALID
    output logic         AXI_15_ARREADY,       // output wire AXI_15_ARREADY
    output logic         AXI_15_AWREADY,       // output wire AXI_15_AWREADY
    output logic [31:0]  AXI_15_RDATA_PARITY,  // output wire [31 : 0] AXI_15_RDATA_PARITY
    output logic [255:0] AXI_15_RDATA,         // output wire [255 : 0] AXI_15_RDATA
    output logic [5:0]   AXI_15_RID,           // output wire [5 : 0] AXI_15_RID
    output logic         AXI_15_RLAST,         // ouTput wire AXI_15_RLAST
    output logic [1:0]   AXI_15_RRESP,         // output wire [1 : 0] AXI_15_RRESP
    output logic         AXI_15_RVALID,        // output wire AXI_15_RVALID
    output logic         AXI_15_WREADY,        // output wire AXI_15_WREADY
    output logic [5:0]   AXI_15_BID,           // output wire [5 : 0] AXI_15_BID
    output logic [1:0]   AXI_15_BRESP,         // output wire [1 : 0] AXI_15_BRESP
    output logic         AXI_15_BVALID,        // output wire AXI_15_BVALID
    output logic [31:0]  APB_0_PRDATA,         // output wire [31 : 0] APB_0_PRDATA
    output logic         APB_0_PREADY,         // output wire APB_0_PREADY
    output logic         APB_0_PSLVERR,        // output wire APB_0_PSLVERR
    output logic         apb_complete_0,       // output wire apb_complete_0
    output logic         DRAM_0_STAT_CATTRIP,  // output wire DRAM_0_STAT_CATTRIP
    output logic [6:0]   DRAM_0_STAT_TEMP      // output wire [6 : 0] DRAM_0_STAT_TEMP
);

    // Interfaces
    axi3_intf #(.DATA_BYTE_WID(32), .ADDR_WID(33)) axi_if [16] ();

    // Macro to instantiate AXI3 signal -> interface converter
`define axi3_intf_from_signals_inst(AXI_IF_NUM,AXI_IF_NAME)\
    axi3_intf_from_signals #(\
        .DATA_BYTE_WID (32),\
        .ADDR_WID (33),\
        .ID_T (logic[5:0])\
    ) i_axi3_intf_from_signals_``AXI_IF_NAME`` (\
        .aclk     ( AXI_``AXI_IF_NAME``_ACLK ),\
        .aresetn  ( AXI_``AXI_IF_NAME``_ARESET_N ),\
        .awid     ( AXI_``AXI_IF_NAME``_AWID ),\
        .awaddr   ( AXI_``AXI_IF_NAME``_AWADDR ),\
        .awlen    ( AXI_``AXI_IF_NAME``_AWLEN ),\
        .awsize   ( AXI_``AXI_IF_NAME``_AWSIZE ),\
        .awburst  ( AXI_``AXI_IF_NAME``_AWBURST ),\
        .awlock   ( '0 ),\
        .awcache  ( '0 ),\
        .awprot   ( '0 ),\
        .awqos    ( '0 ),\
        .awregion ( '0 ),\
        .awuser   ( '0 ),\
        .awvalid  ( AXI_``AXI_IF_NAME``_AWVALID ),\
        .awready  ( AXI_``AXI_IF_NAME``_AWREADY ),\
        .wid      ( '0 ),\
        .wdata    ( AXI_``AXI_IF_NAME``_WDATA ),\
        .wstrb    ( AXI_``AXI_IF_NAME``_WSTRB ),\
        .wlast    ( AXI_``AXI_IF_NAME``_WLAST ),\
        .wuser    ( '0 ),\
        .wvalid   ( AXI_``AXI_IF_NAME``_WVALID ),\
        .wready   ( AXI_``AXI_IF_NAME``_WREADY ),\
        .bid      ( AXI_``AXI_IF_NAME``_BID ),\
        .bresp    ( AXI_``AXI_IF_NAME``_BRESP ),\
        .buser    ( ),\
        .bvalid   ( AXI_``AXI_IF_NAME``_BVALID ),\
        .bready   ( AXI_``AXI_IF_NAME``_BREADY ),\
        .arid     ( AXI_``AXI_IF_NAME``_ARID ),\
        .araddr   ( AXI_``AXI_IF_NAME``_ARADDR ),\
        .arlen    ( AXI_``AXI_IF_NAME``_ARLEN ),\
        .arsize   ( AXI_``AXI_IF_NAME``_ARSIZE ),\
        .arburst  ( AXI_``AXI_IF_NAME``_ARBURST ),\
        .arlock   ( '0 ),\
        .arcache  ( '0 ),\
        .arprot   ( '0 ),\
        .arqos    ( '0 ),\
        .arregion ( '0 ),\
        .aruser   ( '0 ),\
        .arvalid  ( AXI_``AXI_IF_NAME``_ARVALID ),\
        .arready  ( AXI_``AXI_IF_NAME``_ARREADY ),\
        .rid      ( AXI_``AXI_IF_NAME``_RID ),\
        .rdata    ( AXI_``AXI_IF_NAME``_RDATA ),\
        .rresp    ( AXI_``AXI_IF_NAME``_RRESP ),\
        .rlast    ( AXI_``AXI_IF_NAME``_RLAST ),\
        .ruser    ( ),\
        .rvalid   ( AXI_``AXI_IF_NAME``_RVALID ),\
        .rready   ( AXI_``AXI_IF_NAME``_RREADY ),\
        .axi3_if  ( axi_if[``AXI_IF_NUM``] )\
    );

    // Convert from signals (AXI_NN_*) to interface (axi_if[N])
    `axi3_intf_from_signals_inst(0,00);
    `axi3_intf_from_signals_inst(1,01);
    `axi3_intf_from_signals_inst(2,02);
    `axi3_intf_from_signals_inst(3,03);
    `axi3_intf_from_signals_inst(4,04);
    `axi3_intf_from_signals_inst(5,05);
    `axi3_intf_from_signals_inst(6,06);
    `axi3_intf_from_signals_inst(7,07);
    `axi3_intf_from_signals_inst(8,08);
    `axi3_intf_from_signals_inst(9,09);
    `axi3_intf_from_signals_inst(10,10);
    `axi3_intf_from_signals_inst(11,11);
    `axi3_intf_from_signals_inst(12,12);
    `axi3_intf_from_signals_inst(13,13);
    `axi3_intf_from_signals_inst(14,14);
    `axi3_intf_from_signals_inst(15,15);

    // HBM model
    mem_axi3_bfm #(
        .CHANNELS ( 16 ),
        .DEBUG    ( DEBUG )
    ) i_mem_axi3_bfm  (
        .axi3_if  ( axi_if )
    );

    // Report status
    assign apb_complete_0 = 1'b1;
    assign DRAM_0_STAT_CATTRIP = 1'b0;
    assign DRAM_0_STAT_TEMP = 7'd30;

endmodule : xilinx_hbm_4g_bfm
