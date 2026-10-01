// Platform constants for Alveo Versal cards (V80 / av80).
//
// The DMA queue count is a property of the platform's QDMA implementation:
// CPM5 carries a 12-bit queue ID (4096 queues), whereas the UltraScale+ soft
// QDMA IP carries 11 bits (2048). Each platform top-level passes its own value
// to shell_intf so the shell-core boundary is sized to what the hardware can
// actually address.
package xilinx_alveo_versal_pkg;

    // --------------------------------------------------------------
    // Parameters
    // --------------------------------------------------------------
    localparam int DMA_ST_DATA_BYTE_WID = 64;
    localparam int DMA_ST_QUEUES = 4096;
    localparam int DMA_ST_QID_WID = DMA_ST_QUEUES > 1 ? $clog2(DMA_ST_QUEUES) : 1;

endpackage : xilinx_alveo_versal_pkg
