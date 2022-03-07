// =============================================================================
//  NOTICE: This computer software was prepared by The Regents of the
//  University of California through Lawrence Berkeley National Laboratory
//  and Peter Bengough hereinafter the Contractor, under Contract No.
//  DE-AC02-05CH11231 with the Department of Energy (DOE). All rights in the
//  computer software are reserved by DOE on behalf of the United States
//  Government and the Contractor as provided in the Contract. You are
//  authorized to use this computer software for Governmental purposes but it
//  is not to be released or distributed to the public.
//
//  NEITHER THE GOVERNMENT NOR THE CONTRACTOR MAKES ANY WARRANTY, EXPRESS OR
//  IMPLIED, OR ASSUMES ANY LIABILITY FOR THE USE OF THIS SOFTWARE.
//
//  This notice including this sentence must appear on any copies of this
//  computer software.
// =============================================================================

module smartnic_322mhz_app #(
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
    // -- Write response axil_
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
    input  logic         axis_from_switch_tvalid,
    output logic         axis_from_switch_tready,
    input  logic [511:0] axis_from_switch_tdata,
    input  logic [63:0]  axis_from_switch_tkeep,
    input  logic         axis_from_switch_tlast,
    input  logic [1:0]   axis_from_switch_tid,
    input  logic [1:0]   axis_from_switch_tdest,
    input  logic         axis_from_switch_tuser,

    // AXI-S data interface (to switch)
    // (synchronous to core_clk domain)
    output logic         axis_to_switch_tvalid,
    input  logic         axis_to_switch_tready,
    output logic [511:0] axis_to_switch_tdata,
    output logic [63:0]  axis_to_switch_tkeep,
    output logic         axis_to_switch_tlast,
    output logic [1:0]   axis_to_switch_tid,
    output logic [1:0]   axis_to_switch_tdest,
    output logic         axis_to_switch_tuser,

    // AXI-S data interface (from host)
    // (synchronous to core_clk domain)
    input  logic         axis_from_host_tvalid,
    output logic         axis_from_host_tready,
    input  logic [511:0] axis_from_host_tdata,
    input  logic [63:0]  axis_from_host_tkeep,
    input  logic         axis_from_host_tlast,
    input  logic [1:0]   axis_from_host_tid,
    input  logic [1:0]   axis_from_host_tdest,
    input  logic         axis_from_host_tuser,

    // AXI-S data interface (to host)
    // (synchronous to core_clk domain)
    output logic         axis_to_host_tvalid,
    input  logic         axis_to_host_tready,
    output logic [511:0] axis_to_host_tdata,
    output logic [63:0]  axis_to_host_tkeep,
    output logic         axis_to_host_tlast,
    output logic [1:0]   axis_to_host_tid,
    output logic [1:0]   axis_to_host_tdest,
    output logic         axis_to_host_tuser
);
    // Parameters
    localparam int AXIS_DATA_BYTE_WID = 64;

    // Typedefs
    typedef logic[1:0] port_t;

    // Interfaces
    axi4l_intf #() axil_if       ();
    axi4l_intf #() axil_sdnet_if ();
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_to_switch   ();
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_from_switch ();
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_to_host     ();
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_from_host   ();

    // Map signals to interfaces
    // -- AXI-L interface
    axi4l_intf_from_signals i_axi4l_intf_from_signals (
        .aclk     ( axil_aclk ),
        .aresetn  ( axil_aresetn ),
        .awvalid  ( axil_awvalid ),
        .awready  ( axil_awready ),
        .awaddr   ( axil_awaddr ),
        .awprot   ( axil_awprot ),
        .wvalid   ( axil_wvalid ),
        .wready   ( axil_wready ),
        .wdata    ( axil_wdata ),
        .wstrb    ( axil_wstrb ),
        .bvalid   ( axil_bvalid ),
        .bready   ( axil_bready ),
        .bresp    ( axil_bresp ),
        .arvalid  ( axil_arvalid ),
        .arready  ( axil_arready ),
        .araddr   ( axil_araddr ),
        .arprot   ( axil_arprot ),
        .rvalid   ( axil_rvalid ),
        .rready   ( axil_rready ),
        .rdata    ( axil_rdata ),
        .rresp    ( axil_rresp ),
        .axi4l_if ( axil_if )
    );
    // -- AXI-L interface to SDNet
    axi4l_intf_from_signals i_axi4l_intf_from_signals_sdnet (
        .aclk     ( axil_aclk ),
        .aresetn  ( axil_sdnet_aresetn ),
        .awvalid  ( axil_sdnet_awvalid ),
        .awready  ( axil_sdnet_awready ),
        .awaddr   ( axil_sdnet_awaddr ),
        .awprot   ( axil_sdnet_awprot ),
        .wvalid   ( axil_sdnet_wvalid ),
        .wready   ( axil_sdnet_wready ),
        .wdata    ( axil_sdnet_wdata ),
        .wstrb    ( axil_sdnet_wstrb ),
        .bvalid   ( axil_sdnet_bvalid ),
        .bready   ( axil_sdnet_bready ),
        .bresp    ( axil_sdnet_bresp ),
        .arvalid  ( axil_sdnet_arvalid ),
        .arready  ( axil_sdnet_arready ),
        .araddr   ( axil_sdnet_araddr ),
        .arprot   ( axil_sdnet_arprot ),
        .rvalid   ( axil_sdnet_rvalid ),
        .rready   ( axil_sdnet_rready ),
        .rdata    ( axil_sdnet_rdata ),
        .rresp    ( axil_sdnet_rresp ),
        .axi4l_if ( axil_sdnet_if )
    );
    // -- AXI-S interface from switch
    axi4s_intf_from_signals #(
        .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)
    ) i_axi4s_intf_from_signals_from_switch (
        .aclk    ( core_clk ),
        .aresetn ( core_rstn ),
        .tvalid  ( axis_from_switch_tvalid ),
        .tready  ( axis_from_switch_tready ),
        .tdata   ( axis_from_switch_tdata ),
        .tkeep   ( axis_from_switch_tkeep ),
        .tlast   ( axis_from_switch_tlast ),
        .tid     ( axis_from_switch_tid ),
        .tdest   ( axis_from_switch_tdest ),
        .tuser   ( axis_from_switch_tuser ),
        .axi4s_if( axis_from_switch )
    );
    // -- AXI-S interface to switch
    axi4s_intf_to_signals #(
        .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)
    ) i_axi4s_to_signals_to_switch (
        .aclk    ( ), // Output
        .aresetn ( ), // Output
        .tvalid  ( axis_to_switch_tvalid ),
        .tready  ( axis_to_switch_tready ),
        .tdata   ( axis_to_switch_tdata ),
        .tkeep   ( axis_to_switch_tkeep ),
        .tlast   ( axis_to_switch_tlast ),
        .tid     ( axis_to_switch_tid ),
        .tdest   ( axis_to_switch_tdest ),
        .tuser   ( axis_to_switch_tuser ),
        .axi4s_if( axis_to_switch )
    );
    // -- AXI-S interface from host
    axi4s_intf_from_signals #(
        .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)
    ) i_axi4s_from_signals_from_host (
        .aclk    ( core_clk ),
        .aresetn ( core_rstn ),
        .tvalid  ( axis_from_host_tvalid ),
        .tready  ( axis_from_host_tready ),
        .tdata   ( axis_from_host_tdata ),
        .tkeep   ( axis_from_host_tkeep ),
        .tlast   ( axis_from_host_tlast ),
        .tid     ( axis_from_host_tid ),
        .tdest   ( axis_from_host_tdest ),
        .tuser   ( axis_from_host_tuser ),
        .axi4s_if( axis_from_host )
    );
    // -- AXI-S interface to host
    axi4s_intf_to_signals #(
        .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)
    ) i_axi4s_to_signals_to_host (
        .aclk    ( ), // Output
        .aresetn ( ), // Output
        .tvalid  ( axis_to_host_tvalid ),
        .tready  ( axis_to_host_tready ),
        .tdata   ( axis_to_host_tdata ),
        .tkeep   ( axis_to_host_tkeep ),
        .tlast   ( axis_to_host_tlast ),
        .tid     ( axis_to_host_tid ),
        .tdest   ( axis_to_host_tdest ),
        .tuser   ( axis_to_host_tuser ),
        .axi4s_if( axis_to_host )
    );

    p4_app p4_app_0
    (
        .core_clk      ( core_clk ),
        .core_rstn     ( core_rstn ),
        .timestamp     ( timestamp ),

        .axil_if       ( axil_if ),
        .axil_to_sdnet ( axil_sdnet_if ),

        .axis_core_to_switch  ( axis_to_switch),
        .axis_switch_to_core  ( axis_from_switch ),
        .axis_to_host_0       ( axis_to_host ),
        .axis_from_host_0     ( axis_from_host )
    );

endmodule: smartnic_322mhz_app
