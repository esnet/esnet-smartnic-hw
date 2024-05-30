module xilinx_alveo_au250
    import xilinx_alveo_au250_pkg::*;
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0
) (
    // QSFP
    input  wire [NUM_CMAC-1:0]      qsfp_refclk_p,
    input  wire [NUM_CMAC-1:0]      qsfp_refclk_n,
    input  wire [NUM_CMAC-1:0][3:0] qsfp_rxp,
    input  wire [NUM_CMAC-1:0][3:0] qsfp_rxn,
    output wire [NUM_CMAC-1:0][3:0] qsfp_txp,
    output wire [NUM_CMAC-1:0][3:0] qsfp_txn,

    output wire [NUM_CMAC-1:0]      qsfp_resetl,
    input  wire [NUM_CMAC-1:0]      qsfp_modprsl,
    input  wire [NUM_CMAC-1:0]      qsfp_intl,
    output wire [NUM_CMAC-1:0]      qsfp_lpmode,
    output wire [NUM_CMAC-1:0]      qsfp_modsell,

    // PCIe
    input  wire                     pcie_refclk_p,
    input  wire                     pcie_refclk_n,
    input  wire [PCIE_LINK_WID-1:0] pcie_rxp,
    input  wire [PCIE_LINK_WID-1:0] pcie_rxn,
    output wire [PCIE_LINK_WID-1:0] pcie_txp,
    output wire [PCIE_LINK_WID-1:0] pcie_txn,
    input  wire                     pcie_rstn,

    // Satellite controller
    input  wire                     satellite_uart_0_rxd,
    output wire                     satellite_uart_0_txd,
    input  wire [3:0]               satellite_gpio
);

    // =========================================================================
    // Imports
    // =========================================================================
    import xilinx_alveo_pkg::*;

    // =========================================================================
    // Parameters
    // =========================================================================
    localparam bit INCLUDE_CMS = 0;

    // =========================================================================
    // Signals
    // =========================================================================
    (* keep = "true" *) logic ref_clk_100mhz;

    // Clocks (from Alveo shell)
    logic clk_100mhz;
    logic clk_125mhz;
    logic clk_250mhz;
    logic clk_333mhz;

    // Application clock/reset (from Alveo shell)
    logic clk; // 334MHz
    logic srst;

    // =========================================================================
    // Interfaces
    // =========================================================================
    axi4l_intf #() axil_if ();
    axi4l_intf #() axil_cms ();

    axi4s_intf #(.DATA_BYTE_WID(CMAC_DATA_BYTE_WID), .TUSER_T(cmac_axis_tuser_t)) axis_cmac_rx [NUM_CMAC] ();
    axi4s_intf #(.DATA_BYTE_WID(CMAC_DATA_BYTE_WID), .TUSER_T(cmac_axis_tuser_t)) axis_cmac_tx [NUM_CMAC] ();

    axi4s_intf #(.DATA_BYTE_WID(DMA_ST_DATA_BYTE_WID), .TID_T  (dma_st_qid_t), .TUSER_T(dma_st_axis_tuser_t)) axis_h2c [NUM_DMA_ST] ();
    axi4s_intf #(.DATA_BYTE_WID(DMA_ST_DATA_BYTE_WID), .TDEST_T(dma_st_qid_t), .TUSER_T(dma_st_axis_tuser_t)) axis_c2h [NUM_DMA_ST] ();

    // =========================================================================
    // Common Alveo top level
    // =========================================================================
    xilinx_alveo #(
        .NUM_CMAC        ( NUM_CMAC ),
        .PCIE_LINK_WID   ( PCIE_LINK_WID ),
        .INCLUDE_QSPI    ( 0 ),
        .INCLUDE_SYSMON  ( 1 ),
        .BUILD_TIMESTAMP ( BUILD_TIMESTAMP )
    ) i_xilinx_alveo (
        .qsfp_refclk_p,
        .qsfp_refclk_n,
        .qsfp_rxp,
        .qsfp_rxn,
        .qsfp_txp,
        .qsfp_txn,
        .pcie_rstn,
        .pcie_refclk_p,
        .pcie_refclk_n,
        .pcie_rxp,
        .pcie_rxn,
        .pcie_txp,
        .pcie_txn,
        .clk_100mhz,
        .clk_125mhz,
        .clk_250mhz,
        .clk_333mhz,
        .clk,
        .srst,
        .axis_cmac_rx,
        .axis_cmac_tx,
        .axis_h2c,
        .axis_c2h,
        .axil_if,
        .axil_cms
    );

    // =========================================================================
    // Card management subsystem
    // =========================================================================
    generate
        if (INCLUDE_CMS) begin : g__cms
            // TODO: add CMS instance
        end : g__cms
        else begin : g__no_cms
            // Tie off unused CMS AXI-L interface
            axi4l_intf_peripheral_term i_axi4l_intf_peripheral_term (.axi4l_if (axil_cms));

        end : g__no_cms
    endgenerate

    // =========================================================================
    // Application
    // =========================================================================
    // TEMP : tie off unused application interfaces
    axi4l_intf_peripheral_term i_axi4l_intf_peripheral_term__app (.axi4l_if (axil_if));

    generate
        for (genvar g_cmac = 0; g_cmac < NUM_CMAC; g_cmac++) begin : g__cmac
            axi4s_intf_tx_term i_axi4s_intf_tx_term__cmac_tx (
                .aclk     (clk),
                .aresetn  (!srst),
                .axi4s_if (axis_cmac_tx[g_cmac])
            );
            axi4s_intf_rx_sink i_axi4s_intf_rx_sink__cmac_rx (
                .axi4s_if (axis_cmac_rx[g_cmac])
            );
        end : g__cmac
        for (genvar g_dma_st = 0; g_dma_st < NUM_DMA_ST; g_dma_st++) begin : g__dma_st
            axi4s_intf_tx_term i_axi4s_intf_tx_term__c2h (
                .aclk     (clk),
                .aresetn  (!srst),
                .axi4s_if (axis_c2h[g_dma_st])
            );
            axi4s_intf_rx_sink i_axi4s_intf_rx_sink__h2c (
                .axi4s_if (axis_h2c[g_dma_st])
            );

        end : g__dma_st
    endgenerate

endmodule : xilinx_alveo_au250
