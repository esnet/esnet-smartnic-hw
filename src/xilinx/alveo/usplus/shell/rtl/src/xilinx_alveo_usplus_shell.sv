// =========================================================================
// xilinx_alveo_usplus_shell
//
//   Implements ESnet standard shell on UltraScale+ Alveo architecture.
//
//   Supports a variety of hardware implementations (Alveo boards) using
//   the abstract xilinx_alveo_hw_intf connection to the physical layer.
//
//   Supports a variety of 'core' implementations (applications) using
//   the abstract shell_intf connection to user logic.
//
//   Uses the common xilinx_alveo_shell module for JTAG reset control and
//   the top-level hw/core AXI-L decoder.
//
// =========================================================================
module xilinx_alveo_usplus_shell
    import shell_pkg::*;
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0
) (
    // To/from physical layer (hardware)
    xilinx_alveo_hw_intf.alveo alveo_hw_if,
    // To/from core (application)
    shell_intf.shell shell_if
);

    // =========================================================================
    // Interfaces
    // =========================================================================

    axi4l_intf #() axil_top ();
    axi4l_intf #() axil_hw ();
    axi4l_intf #() axil_core ();

    axi4s_intf #(.DATA_BYTE_WID(shell_if.PORT_DATA_BYTE_WID), .TID_WID(PORT_AXIS_TID_WID), .TDEST_WID(PORT_AXIS_TDEST_WID), .TUSER_WID(PORT_AXIS_TUSER_WID)) axis_port_rx [shell_if.NUM_PORTS] (.aclk(shell_if.clk));
    axi4s_intf #(.DATA_BYTE_WID(shell_if.PORT_DATA_BYTE_WID), .TID_WID(PORT_AXIS_TID_WID), .TDEST_WID(PORT_AXIS_TDEST_WID), .TUSER_WID(PORT_AXIS_TUSER_WID)) axis_port_tx [shell_if.NUM_PORTS] (.aclk(shell_if.clk));

    axi4s_intf #(.DATA_BYTE_WID(shell_if.DMA_ST_DATA_BYTE_WID), .TID_WID(DMA_ST_AXIS_TID_WID), .TDEST_WID(DMA_ST_AXIS_TDEST_WID), .TUSER_WID(DMA_ST_AXIS_TUSER_WID)) axis_h2c (.aclk(shell_if.clk));
    axi4s_intf #(.DATA_BYTE_WID(shell_if.DMA_ST_DATA_BYTE_WID), .TID_WID(DMA_ST_AXIS_TID_WID), .TDEST_WID(DMA_ST_AXIS_TDEST_WID), .TUSER_WID(DMA_ST_AXIS_TUSER_WID)) axis_c2h (.aclk(shell_if.clk));

    axi4s_intf #(.DATA_BYTE_WID(xilinx_alveo_pkg::CMAC_DATA_BYTE_WID), .TID_WID(xilinx_alveo_pkg::CMAC_AXIS_TID_WID), .TDEST_WID(xilinx_alveo_pkg::CMAC_AXIS_TDEST_WID), .TUSER_WID(xilinx_alveo_pkg::CMAC_AXIS_TUSER_WID)) __axis_cmac_rx [NUM_CMAC] (.aclk(shell_if.clk));
    axi4s_intf #(.DATA_BYTE_WID(xilinx_alveo_pkg::CMAC_DATA_BYTE_WID), .TID_WID(xilinx_alveo_pkg::CMAC_AXIS_TID_WID), .TDEST_WID(xilinx_alveo_pkg::CMAC_AXIS_TDEST_WID), .TUSER_WID(xilinx_alveo_pkg::CMAC_AXIS_TUSER_WID)) __axis_cmac_tx [NUM_CMAC] (.aclk(shell_if.clk));

    axi4s_intf #(.DATA_BYTE_WID(xilinx_alveo_pkg::DMA_ST_DATA_BYTE_WID), .TID_WID(xilinx_alveo_pkg::DMA_ST_AXIS_TID_WID), .TDEST_WID(xilinx_alveo_pkg::DMA_ST_AXIS_TDEST_WID), .TUSER_WID(xilinx_alveo_pkg::DMA_ST_AXIS_TUSER_WID)) __axis_h2c (.aclk(shell_if.clk));
    axi4s_intf #(.DATA_BYTE_WID(xilinx_alveo_pkg::DMA_ST_DATA_BYTE_WID), .TID_WID(xilinx_alveo_pkg::DMA_ST_AXIS_TID_WID), .TDEST_WID(xilinx_alveo_pkg::DMA_ST_AXIS_TDEST_WID), .TUSER_WID(xilinx_alveo_pkg::DMA_ST_AXIS_TUSER_WID)) __axis_c2h (.aclk(shell_if.clk));

    // =========================================================================
    // Signals
    // =========================================================================
    logic pci_rstn;

    logic clk;
    logic srst;
    logic clk_100mhz;
    logic clk_125mhz;
    logic clk_250mhz;
    logic clk_333mhz;

    // =========================================================================
    // Shell adaptation layer
    // (maps shell_intf signals to/from axi4l_intf / axi4s_intf)
    // axil_core carries the post-decoded core AXI-L (from xilinx_alveo_shell)
    // =========================================================================
    shell_adapter__shell i_shell_adapter__shell (
        .shell_if,
        .clk,
        .srst,
        .mgmt_clk   ( axil_core.aclk    ),
        .mgmt_srst  ( !axil_core.aresetn ),
        .clk_100mhz,
        .port_clk   ( '{default: clk}  ),
        .port_srst  ( '{default: srst} ),
        .axil_if    ( axil_core ),
        .axis_port_rx,
        .axis_port_tx,
        .axis_h2c,
        .axis_c2h
    );

    // =========================================================================
    // Common Alveo shell — JTAG reset control and top-level hw/core decoder
    // =========================================================================
    xilinx_alveo_shell i_xilinx_alveo_shell (
        .sys_clk_100mhz ( alveo_hw_if.sys_clk_100mhz ),
        .pci_rstn_in    ( alveo_hw_if.pcie_rstn ),
        .pci_rstn_out   ( pci_rstn ),
        .axil_top,
        .axil_hw,
        .axil_core
    );

    // =========================================================================
    // UltraScale+ Alveo core — CMAC, QDMA, clocking, hw register decode
    // axil_top drives the PCIe AXI-L into the QDMA; axil_hw receives the
    // decoded hw sub-space from the top-level shell_decoder.
    // =========================================================================
    xilinx_alveo #(
        .BUILD_TIMESTAMP ( BUILD_TIMESTAMP )
    ) i_xilinx_alveo  (
        .alveo_hw_if,
        .pci_rstn,
        .clk,
        .srst,
        .clk_100mhz,
        .clk_125mhz,
        .clk_250mhz,
        .clk_333mhz,
        .axis_cmac_rx ( __axis_cmac_rx ),
        .axis_cmac_tx ( __axis_cmac_tx ),
        .axis_h2c ( __axis_h2c ),
        .axis_c2h ( __axis_c2h ),
        .axil_top,
        .axil_hw
    );

    // =========================================================================
    // Map between shell and Alveo
    // =========================================================================
    generate
        for (genvar g_port = 0; g_port < shell_if.NUM_PORTS; g_port++) begin : g__port
            // Port (Rx)
            shell_pkg::port_axis_tid_t   axis_port_rx_tid;
            shell_pkg::port_axis_tdest_t axis_port_rx_tdest;
            shell_pkg::port_axis_tuser_t axis_port_rx_tuser;

            xilinx_alveo_pkg::cmac_axis_tid_t   __axis_cmac_rx_tid;
            xilinx_alveo_pkg::cmac_axis_tdest_t __axis_cmac_rx_tdest;
            xilinx_alveo_pkg::cmac_axis_tuser_t __axis_cmac_rx_tuser;

            assign __axis_cmac_rx_tid           = __axis_cmac_rx[g_port].tid;
            assign axis_port_rx_tid.unused      = 1'b0;

            assign __axis_cmac_rx_tdest         = __axis_cmac_rx[g_port].tdest;
            assign axis_port_rx_tdest.unused    = 1'b0;

            assign __axis_cmac_rx_tuser         = __axis_cmac_rx[g_port].tuser;
            assign axis_port_rx_tuser.err       = __axis_cmac_rx_tuser.err;

            axi4s_intf_set_meta #(
                .TID_WID    ( shell_pkg::PORT_AXIS_TID_WID ),
                .TDEST_WID  ( shell_pkg::PORT_AXIS_TDEST_WID ),
                .TUSER_WID  ( shell_pkg::PORT_AXIS_TUSER_WID )
            ) i_axi4s_set_meta__port_rx (
                .from_tx ( __axis_cmac_rx[g_port] ),
                .to_rx   ( axis_port_rx[g_port] ),
                .tid     ( axis_port_rx_tid ),
                .tdest   ( axis_port_rx_tdest ),
                .tuser   ( axis_port_rx_tuser )
            );

            // Port (Tx)
            xilinx_alveo_pkg::cmac_axis_tid_t   __axis_cmac_tx_tid;
            xilinx_alveo_pkg::cmac_axis_tdest_t __axis_cmac_tx_tdest;
            xilinx_alveo_pkg::cmac_axis_tuser_t __axis_cmac_tx_tuser;

            shell_pkg::port_axis_tid_t   axis_port_tx_tid;
            shell_pkg::port_axis_tdest_t axis_port_tx_tdest;
            shell_pkg::port_axis_tuser_t axis_port_tx_tuser;

            assign axis_port_tx_tid               = axis_port_tx[g_port].tid;
            assign __axis_cmac_tx_tid.unused      = 1'b0;

            assign axis_port_tx_tdest             = axis_port_tx[g_port].tdest;
            assign __axis_cmac_tx_tdest.unused    = 1'b0;

            assign axis_port_tx_tuser             = axis_port_tx[g_port].tuser;
            assign __axis_cmac_tx_tuser.err       = axis_port_tx_tuser.err;

            axi4s_intf_set_meta #(
                .TID_WID    ( xilinx_alveo_pkg::CMAC_AXIS_TID_WID ),
                .TDEST_WID  ( xilinx_alveo_pkg::CMAC_AXIS_TDEST_WID ),
                .TUSER_WID  ( xilinx_alveo_pkg::CMAC_AXIS_TUSER_WID )
            ) i_axi4s_set_meta__port_tx (
                .from_tx ( axis_port_tx[g_port] ),
                .to_rx   ( __axis_cmac_tx[g_port] ),
                .tid     ( __axis_cmac_tx_tid ),
                .tdest   ( __axis_cmac_tx_tdest ),
                .tuser   ( __axis_cmac_tx_tuser )
            );

        end : g__port
    endgenerate

    // -- DMA (H2C)
    xilinx_alveo_pkg::dma_st_axis_tid_t   __axis_h2c_tid;
    xilinx_alveo_pkg::dma_st_axis_tdest_t __axis_h2c_tdest;
    xilinx_alveo_pkg::dma_st_axis_tuser_t __axis_h2c_tuser;

    shell_pkg::dma_st_axis_tid_t   axis_h2c_tid;
    shell_pkg::dma_st_axis_tdest_t axis_h2c_tdest;
    shell_pkg::dma_st_axis_tuser_t axis_h2c_tuser;

    assign __axis_h2c_tid   = __axis_h2c.tid;
    assign axis_h2c_tid.qid = __axis_h2c_tid.qid;

    assign __axis_h2c_tdest = __axis_h2c.tdest;
    assign axis_h2c_tdest.unused = 1'b0;

    assign __axis_h2c_tuser   = __axis_h2c.tuser;
    assign axis_h2c_tuser.err = __axis_h2c_tuser.err;

    axi4s_intf_set_meta #(
        .TID_WID    ( shell_pkg::DMA_ST_AXIS_TID_WID ),
        .TDEST_WID  ( shell_pkg::DMA_ST_AXIS_TDEST_WID ),
        .TUSER_WID  ( shell_pkg::DMA_ST_AXIS_TUSER_WID )
    ) i_axi4s_intf_set_meta__h2c (
        .from_tx ( __axis_h2c ),
        .to_rx   ( axis_h2c ),
        .tid     ( axis_h2c_tid ),
        .tdest   ( axis_h2c_tdest ),
        .tuser   ( axis_h2c_tuser )
    );

    // -- DMA (C2H)
    shell_pkg::dma_st_axis_tid_t   axis_c2h_tid;
    shell_pkg::dma_st_axis_tdest_t axis_c2h_tdest;
    shell_pkg::dma_st_axis_tuser_t axis_c2h_tuser;

    xilinx_alveo_pkg::dma_st_axis_tid_t   __axis_c2h_tid;
    xilinx_alveo_pkg::dma_st_axis_tdest_t __axis_c2h_tdest;
    xilinx_alveo_pkg::dma_st_axis_tuser_t __axis_c2h_tuser;

    assign axis_c2h_tid       = axis_c2h.tid;
    assign __axis_c2h_tid.qid = axis_c2h_tid.qid;

    assign axis_c2h_tdest     = axis_c2h.tdest;
    assign __axis_c2h_tdest.unused = 1'b0;

    assign axis_c2h_tuser       = axis_c2h.tuser;
    assign __axis_c2h_tuser.err = axis_c2h_tuser.err;

    axi4s_intf_set_meta #(
        .TID_WID    ( xilinx_alveo_pkg::DMA_ST_AXIS_TID_WID ),
        .TDEST_WID  ( xilinx_alveo_pkg::DMA_ST_AXIS_TDEST_WID ),
        .TUSER_WID  ( xilinx_alveo_pkg::DMA_ST_AXIS_TUSER_WID )
    ) i_axi4s_intf_set_meta__c2h (
        .from_tx ( axis_c2h ),
        .to_rx   ( __axis_c2h ),
        .tid     ( __axis_c2h_tid ),
        .tdest   ( __axis_c2h_tdest ),
        .tuser   ( __axis_c2h_tuser )
    );
endmodule : xilinx_alveo_usplus_shell
