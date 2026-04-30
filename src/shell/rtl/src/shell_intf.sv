// =========================================================================
// Shell interface
//
//   Parameterized flat SV interface for the shell-core boundary.
//   All signals are plain logic — no embedded interface instances.
//
//   Parameters are set at instantiation time by the platform top-level,
//   allowing different port counts and data widths per platform without
//   requiring per-platform shell_pkg variants.
//
//   The 'shell' modport is used by shell adapter modules (xilinx_alveo_shell,
//   xilinx_aved_shell_adapter). The 'core' modport is the mirror used by
//   the core module.
//
// =========================================================================
interface shell_intf
    import shell_pkg::*;
#(
    parameter int NUM_PORTS            = 2,
    parameter int PORT_DATA_BYTE_WID   = 64,
    parameter int DMA_ST_DATA_BYTE_WID = 64,
    parameter int DMA_ST_QUEUES        = shell_pkg::DMA_ST_QUEUES,
    parameter int AXIL_ADDR_WID        = 32
) ();
    // -------------------------------------------------------------------------
    // Derived constants (accessible from both sides via shell_if.PORT_DATA_WID etc.)
    // -------------------------------------------------------------------------
    localparam int PORT_DATA_WID      = PORT_DATA_BYTE_WID * 8;
    localparam int DMA_ST_DATA_WID    = DMA_ST_DATA_BYTE_WID * 8;
    localparam int DMA_ST_QID_WID     = DMA_ST_QUEUES > 1 ? $clog2(DMA_ST_QUEUES) : 1;
    localparam int AXIL_DATA_BYTE_WID = 4;
    localparam int AXIL_DATA_WID      = AXIL_DATA_BYTE_WID * 8;

    // -------------------------------------------------------------------------
    // Clock / reset  (driven by shell, consumed by core)
    // -------------------------------------------------------------------------
    logic clk;
    logic srst;
    logic mgmt_clk;
    logic mgmt_srst;
    logic clk_100mhz;

    // -------------------------------------------------------------------------
    // AXI-Lite management
    //   Shell drives controller-originated signals (AW/W/AR channels + bready/rready).
    //   Core drives peripheral response signals (B/R channels + awready/wready/arready).
    // -------------------------------------------------------------------------
    logic                          axil_awvalid;
    logic                          axil_awready;
    logic [AXIL_ADDR_WID-1:0]      axil_awaddr;
    logic [2:0]                    axil_awprot;
    logic                          axil_wvalid;
    logic                          axil_wready;
    logic [AXIL_DATA_WID-1:0]      axil_wdata;
    logic [AXIL_DATA_BYTE_WID-1:0] axil_wstrb;
    logic                          axil_bvalid;
    logic                          axil_bready;
    logic [1:0]                    axil_bresp;
    logic                          axil_arvalid;
    logic                          axil_arready;
    logic [AXIL_ADDR_WID-1:0]      axil_araddr;
    logic [2:0]                    axil_arprot;
    logic                          axil_rvalid;
    logic                          axil_rready;
    logic [AXIL_DATA_WID-1:0]      axil_rdata;
    logic [1:0]                    axil_rresp;

    // -------------------------------------------------------------------------
    // Network ports  (indexed 0..NUM_PORTS-1)
    //   port_rx: ingress — shell drives data toward core
    //   port_tx: egress  — core drives data toward shell
    // -------------------------------------------------------------------------
    logic [NUM_PORTS-1:0]                          port_rx_tvalid;
    logic [NUM_PORTS-1:0]                          port_rx_tready;
    logic [NUM_PORTS-1:0][PORT_DATA_WID-1:0]       port_rx_tdata;
    logic [NUM_PORTS-1:0][PORT_DATA_BYTE_WID-1:0]  port_rx_tkeep;
    logic [NUM_PORTS-1:0]                          port_rx_tlast;
    logic [NUM_PORTS-1:0][PORT_AXIS_TID_WID-1:0]   port_rx_tid;
    logic [NUM_PORTS-1:0][PORT_AXIS_TDEST_WID-1:0] port_rx_tdest;
    logic [NUM_PORTS-1:0][PORT_AXIS_TUSER_WID-1:0] port_rx_tuser;

    logic [NUM_PORTS-1:0]                          port_tx_tvalid;
    logic [NUM_PORTS-1:0]                          port_tx_tready;
    logic [NUM_PORTS-1:0][PORT_DATA_WID-1:0]       port_tx_tdata;
    logic [NUM_PORTS-1:0][PORT_DATA_BYTE_WID-1:0]  port_tx_tkeep;
    logic [NUM_PORTS-1:0]                          port_tx_tlast;
    logic [NUM_PORTS-1:0][PORT_AXIS_TID_WID-1:0]   port_tx_tid;
    logic [NUM_PORTS-1:0][PORT_AXIS_TDEST_WID-1:0] port_tx_tdest;
    logic [NUM_PORTS-1:0][PORT_AXIS_TUSER_WID-1:0] port_tx_tuser;

    // -------------------------------------------------------------------------
    // DMA streaming
    //   h2c (host-to-core): shell drives toward core
    //   c2h (core-to-host): core drives toward shell
    // -------------------------------------------------------------------------
    logic                             h2c_tvalid;
    logic                             h2c_tready;
    logic [DMA_ST_DATA_WID-1:0]       h2c_tdata;
    logic [DMA_ST_DATA_BYTE_WID-1:0]  h2c_tkeep;
    logic                             h2c_tlast;
    logic [DMA_ST_AXIS_TID_WID-1:0]   h2c_tid;
    logic [DMA_ST_AXIS_TDEST_WID-1:0] h2c_tdest;
    logic [DMA_ST_AXIS_TUSER_WID-1:0] h2c_tuser;

    logic                             c2h_tvalid;
    logic                             c2h_tready;
    logic [DMA_ST_DATA_WID-1:0]       c2h_tdata;
    logic [DMA_ST_DATA_BYTE_WID-1:0]  c2h_tkeep;
    logic                             c2h_tlast;
    logic [DMA_ST_AXIS_TID_WID-1:0]   c2h_tid;
    logic [DMA_ST_AXIS_TDEST_WID-1:0] c2h_tdest;
    logic [DMA_ST_AXIS_TUSER_WID-1:0] c2h_tuser;

    // -------------------------------------------------------------------------
    // Modports
    // -------------------------------------------------------------------------
    modport shell (
        // Clock/reset: shell drives
        output clk, srst, mgmt_clk, mgmt_srst, clk_100mhz,
        // AXI-L: shell drives controller-to-peripheral signals
        output axil_awvalid, axil_awaddr, axil_awprot,
               axil_wvalid, axil_wdata, axil_wstrb,
               axil_bready,
               axil_arvalid, axil_araddr, axil_arprot,
               axil_rready,
        // AXI-L: core drives peripheral-to-controller responses
        input  axil_awready, axil_wready,
               axil_bvalid, axil_bresp,
               axil_arready,
               axil_rvalid, axil_rdata, axil_rresp,
        // Port Rx: shell drives ingress data toward core
        output port_rx_tvalid, port_rx_tdata, port_rx_tkeep, port_rx_tlast,
               port_rx_tid, port_rx_tdest, port_rx_tuser,
        input  port_rx_tready,
        // Port Tx: core drives egress data toward shell
        input  port_tx_tvalid, port_tx_tdata, port_tx_tkeep, port_tx_tlast,
               port_tx_tid, port_tx_tdest, port_tx_tuser,
        output port_tx_tready,
        // H2C: shell drives toward core
        output h2c_tvalid, h2c_tdata, h2c_tkeep, h2c_tlast,
               h2c_tid, h2c_tdest, h2c_tuser,
        input  h2c_tready,
        // C2H: core drives toward shell
        input  c2h_tvalid, c2h_tdata, c2h_tkeep, c2h_tlast,
               c2h_tid, c2h_tdest, c2h_tuser,
        output c2h_tready
    );

    modport core (
        // Clock/reset: core receives
        input  clk, srst, mgmt_clk, mgmt_srst, clk_100mhz,
        // AXI-L: core receives controller-to-peripheral signals
        input  axil_awvalid, axil_awaddr, axil_awprot,
               axil_wvalid, axil_wdata, axil_wstrb,
               axil_bready,
               axil_arvalid, axil_araddr, axil_arprot,
               axil_rready,
        // AXI-L: core drives peripheral-to-controller responses
        output axil_awready, axil_wready,
               axil_bvalid, axil_bresp,
               axil_arready,
               axil_rvalid, axil_rdata, axil_rresp,
        // Port Rx: core receives ingress data from shell
        input  port_rx_tvalid, port_rx_tdata, port_rx_tkeep, port_rx_tlast,
               port_rx_tid, port_rx_tdest, port_rx_tuser,
        output port_rx_tready,
        // Port Tx: core drives egress data toward shell
        output port_tx_tvalid, port_tx_tdata, port_tx_tkeep, port_tx_tlast,
               port_tx_tid, port_tx_tdest, port_tx_tuser,
        input  port_tx_tready,
        // H2C: core receives from shell
        input  h2c_tvalid, h2c_tdata, h2c_tkeep, h2c_tlast,
               h2c_tid, h2c_tdest, h2c_tuser,
        output h2c_tready,
        // C2H: core drives toward shell
        output c2h_tvalid, c2h_tdata, c2h_tkeep, c2h_tlast,
               c2h_tid, c2h_tdest, c2h_tuser,
        input  c2h_tready
    );

endinterface : shell_intf
