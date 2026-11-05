// OOC synthesis wrapper for xilinx_alveo_qdma_st.
//
// Flattens the DUT's interfaces (axi4l_intf, packet_intf x2, axi4s_intf x2)
// to scalar ports so the module can be the top of an out-of-context build.
// Used to reproduce and fix the C2H timing closure issue between
// axi4s_to_packet_adapter and the CRC generator at 350MHz core_clk /
// 250MHz aclk.
module xilinx_alveo_qdma_st_wrapper
    import xilinx_qdma_pkg::*;
#(
    parameter int QID_WID     = 12,
    parameter int MAX_PKT_LEN = 9100
)(
    input  wire aclk,
    input  wire aresetn,
    input  wire core_clk,
    input  wire core_srst,

    // -----------------------------------------------------------------
    // axil_if (axi4l_intf.peripheral) — management clock domain
    // -----------------------------------------------------------------
    input  wire        axil_aclk,
    input  wire        axil_aresetn,
    input  wire         axil_awvalid,
    output wire         axil_awready,
    input  wire [31:0]  axil_awaddr,
    input  wire [2:0]   axil_awprot,
    input  wire         axil_wvalid,
    output wire         axil_wready,
    input  wire [31:0]  axil_wdata,
    input  wire [3:0]   axil_wstrb,
    output wire         axil_bvalid,
    input  wire         axil_bready,
    output wire [1:0]   axil_bresp,
    input  wire         axil_arvalid,
    output wire         axil_arready,
    input  wire [31:0]  axil_araddr,
    input  wire [2:0]   axil_arprot,
    output wire         axil_rvalid,
    input  wire         axil_rready,
    output wire [31:0]  axil_rdata,
    output wire [1:0]   axil_rresp,

    // -----------------------------------------------------------------
    // pkt_h2c_dma (packet_intf.rx) — aclk domain, META_WID = PKT_H2C_META_WID
    // -----------------------------------------------------------------
    input  wire                          pkt_h2c_dma_vld,
    output wire                          pkt_h2c_dma_rdy,
    input  wire [AXIS_DATA_WIDTH-1:0]    pkt_h2c_dma_data,
    input  wire                          pkt_h2c_dma_eop,
    input  wire [MTY_WID-1:0]            pkt_h2c_dma_mty,
    input  wire                          pkt_h2c_dma_err,
    input  wire [PKT_H2C_META_WID-1:0]   pkt_h2c_dma_meta,

    // -----------------------------------------------------------------
    // pkt_c2h_dma (packet_intf.tx) — aclk domain, META_WID = PKT_C2H_META_WID
    // -----------------------------------------------------------------
    output wire                          pkt_c2h_dma_vld,
    input  wire                          pkt_c2h_dma_rdy,
    output wire [AXIS_DATA_WIDTH-1:0]    pkt_c2h_dma_data,
    output wire                          pkt_c2h_dma_eop,
    output wire [MTY_WID-1:0]            pkt_c2h_dma_mty,
    output wire                          pkt_c2h_dma_err,
    output wire [PKT_C2H_META_WID-1:0]   pkt_c2h_dma_meta,

    // -----------------------------------------------------------------
    // axis_h2c (axi4s_intf.tx) — core_clk domain
    // -----------------------------------------------------------------
    output wire                          axis_h2c_tvalid,
    input  wire                          axis_h2c_tready,
    output wire [AXIS_DATA_BYTE_WID-1:0][7:0] axis_h2c_tdata,
    output wire [AXIS_DATA_BYTE_WID-1:0] axis_h2c_tkeep,
    output wire                          axis_h2c_tlast,
    output wire [QID_WID-1:0]            axis_h2c_tid,
    output wire [AXIS_TDEST_WID-1:0]     axis_h2c_tdest,
    output wire [AXIS_TUSER_WID-1:0]     axis_h2c_tuser,

    // -----------------------------------------------------------------
    // axis_c2h (axi4s_intf.rx) — core_clk domain
    // -----------------------------------------------------------------
    input  wire                          axis_c2h_tvalid,
    output wire                          axis_c2h_tready,
    input  wire [AXIS_DATA_BYTE_WID-1:0][7:0] axis_c2h_tdata,
    input  wire [AXIS_DATA_BYTE_WID-1:0] axis_c2h_tkeep,
    input  wire                          axis_c2h_tlast,
    input  wire [QID_WID-1:0]            axis_c2h_tid,
    input  wire [AXIS_TDEST_WID-1:0]     axis_c2h_tdest,
    input  wire [AXIS_TUSER_WID-1:0]     axis_c2h_tuser
);

    axi4l_intf axil_if ();
    assign axil_if.aclk     = axil_aclk;
    assign axil_if.aresetn  = axil_aresetn;
    assign axil_if.awvalid  = axil_awvalid;
    assign axil_awready     = axil_if.awready;
    assign axil_if.awaddr   = axil_awaddr;
    assign axil_if.awprot   = axil_awprot;
    assign axil_if.wvalid   = axil_wvalid;
    assign axil_wready      = axil_if.wready;
    assign axil_if.wdata    = axil_wdata;
    assign axil_if.wstrb    = axil_wstrb;
    assign axil_bvalid      = axil_if.bvalid;
    assign axil_if.bready   = axil_bready;
    assign axil_bresp       = axil_if.bresp;
    assign axil_if.arvalid  = axil_arvalid;
    assign axil_arready     = axil_if.arready;
    assign axil_if.araddr   = axil_araddr;
    assign axil_if.arprot   = axil_arprot;
    assign axil_rvalid      = axil_if.rvalid;
    assign axil_if.rready   = axil_rready;
    assign axil_rdata       = axil_if.rdata;
    assign axil_rresp       = axil_if.rresp;

    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( PKT_H2C_META_WID   )
    ) pkt_h2c_dma (.clk(aclk));

    assign pkt_h2c_dma.vld  = pkt_h2c_dma_vld;
    assign pkt_h2c_dma_rdy  = pkt_h2c_dma.rdy;
    assign pkt_h2c_dma.data = pkt_h2c_dma_data;
    assign pkt_h2c_dma.eop  = pkt_h2c_dma_eop;
    assign pkt_h2c_dma.mty  = pkt_h2c_dma_mty;
    assign pkt_h2c_dma.err  = pkt_h2c_dma_err;
    assign pkt_h2c_dma.meta = pkt_h2c_dma_meta;

    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( PKT_C2H_META_WID   )
    ) pkt_c2h_dma (.clk(aclk));

    assign pkt_c2h_dma_vld  = pkt_c2h_dma.vld;
    assign pkt_c2h_dma.rdy  = pkt_c2h_dma_rdy;
    assign pkt_c2h_dma_data = pkt_c2h_dma.data;
    assign pkt_c2h_dma_eop  = pkt_c2h_dma.eop;
    assign pkt_c2h_dma_mty  = pkt_c2h_dma.mty;
    assign pkt_c2h_dma_err  = pkt_c2h_dma.err;
    assign pkt_c2h_dma_meta = pkt_c2h_dma.meta;

    axi4s_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .TID_WID       ( QID_WID            ),
        .TDEST_WID     ( AXIS_TDEST_WID     ),
        .TUSER_WID     ( AXIS_TUSER_WID     )
    ) axis_h2c (.aclk(core_clk));

    assign axis_h2c_tvalid = axis_h2c.tvalid;
    assign axis_h2c.tready = axis_h2c_tready;
    assign axis_h2c_tdata  = axis_h2c.tdata;
    assign axis_h2c_tkeep  = axis_h2c.tkeep;
    assign axis_h2c_tlast  = axis_h2c.tlast;
    assign axis_h2c_tid    = axis_h2c.tid;
    assign axis_h2c_tdest  = axis_h2c.tdest;
    assign axis_h2c_tuser  = axis_h2c.tuser;

    axi4s_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .TID_WID       ( QID_WID            ),
        .TDEST_WID     ( AXIS_TDEST_WID     ),
        .TUSER_WID     ( AXIS_TUSER_WID     )
    ) axis_c2h (.aclk(core_clk));

    assign axis_c2h.tvalid = axis_c2h_tvalid;
    assign axis_c2h_tready = axis_c2h.tready;
    assign axis_c2h.tdata  = axis_c2h_tdata;
    assign axis_c2h.tkeep  = axis_c2h_tkeep;
    assign axis_c2h.tlast  = axis_c2h_tlast;
    assign axis_c2h.tid    = axis_c2h_tid;
    assign axis_c2h.tdest  = axis_c2h_tdest;
    assign axis_c2h.tuser  = axis_c2h_tuser;

    xilinx_alveo_qdma_st #(
        .QID_WID     ( QID_WID     ),
        .MAX_PKT_LEN ( MAX_PKT_LEN )
    ) i_xilinx_alveo_qdma_st (
        .aclk,
        .aresetn,
        .core_clk,
        .core_srst,
        .axil_if,
        .pkt_h2c_dma,
        .pkt_c2h_dma,
        .axis_h2c,
        .axis_c2h
    );

endmodule : xilinx_alveo_qdma_st_wrapper
