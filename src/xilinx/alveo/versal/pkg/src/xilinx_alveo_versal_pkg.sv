// Platform constants for Alveo Versal cards (V80 / av80).
//
// CPM5 has a native 12-bit queue ID and capacity for 4096 queues. The
// application-facing queue space is defined separately in shell_pkg.
package xilinx_alveo_versal_pkg;

    // --------------------------------------------------------------
    // Parameters
    // --------------------------------------------------------------
    localparam int NUM_PHYS_FUNC = 2;
    localparam int VPD_CLK_FREQ_HZ = 100_000_000;
    localparam bit CARD_INFO_EN = 1'b0;

    localparam int DMA_ST_DATA_BYTE_WID = 64;
    localparam int DMA_ST_QID_WID = 12;

endpackage : xilinx_alveo_versal_pkg
