// =========================================================================
// Xilinx Alveo shell
//
//   Implements ESnet standard shell on Xilinx Alveo architecture.
//
//   Supports a variety of hardware implementations (Alveo boards) using
//   abstract xilinx_alveo_hw_intf connection to physical layer.
//
//   Supports a variety of 'core' implementations (applications) using
//   abstract shell_intf connection to user logic.
//
// =========================================================================
module xilinx_alveo_shell
    import shell_pkg::*;
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0
) (
    // To/from physical layer (hardware)
    xilinx_alveo_hw_intf.alveo alveo_hw_if,
    // To/from core (application)
    // -- Clock/reset
    output wire logic clk,
    output wire logic srst,
    output wire logic mgmt_clk,
    output wire logic mgmt_srst,
    output wire logic clk_100mhz,
    // -- Signals/interfaces
    output wire logic [SHELL_TO_CORE_WID-1:0] shell_to_core,
    input  wire logic [CORE_TO_SHELL_WID-1:0] core_to_shell
);

    // =========================================================================
    // Interfaces
    // =========================================================================
    axi4l_intf #() axil_if ();

    axi4l_intf #() axil_top ();
    axi4l_intf #() axil_hw ();

    axi4s_intf #(.DATA_BYTE_WID(CMAC_DATA_BYTE_WID), .TID_WID(CMAC_AXIS_TID_WID), .TDEST_WID(CMAC_AXIS_TDEST_WID), .TUSER_WID(CMAC_AXIS_TUSER_WID)) axis_cmac_rx [NUM_CMAC] (.aclk(clk), .aresetn(!srst));
    axi4s_intf #(.DATA_BYTE_WID(CMAC_DATA_BYTE_WID), .TID_WID(CMAC_AXIS_TID_WID), .TDEST_WID(CMAC_AXIS_TDEST_WID), .TUSER_WID(CMAC_AXIS_TUSER_WID)) axis_cmac_tx [NUM_CMAC] (.aclk(clk), .aresetn(!srst));

    axi4s_intf #(.DATA_BYTE_WID(DMA_ST_DATA_BYTE_WID), .TID_WID(DMA_ST_AXIS_TID_WID), .TDEST_WID(DMA_ST_AXIS_TDEST_WID), .TUSER_WID(DMA_ST_AXIS_TUSER_WID)) axis_h2c (.aclk(clk), .aresetn(!srst));
    axi4s_intf #(.DATA_BYTE_WID(DMA_ST_DATA_BYTE_WID), .TID_WID(DMA_ST_AXIS_TID_WID), .TDEST_WID(DMA_ST_AXIS_TDEST_WID), .TUSER_WID(DMA_ST_AXIS_TUSER_WID)) axis_c2h (.aclk(clk), .aresetn(!srst));

    axi4s_intf #(.DATA_BYTE_WID(xilinx_alveo_pkg::CMAC_DATA_BYTE_WID), .TID_WID(xilinx_alveo_pkg::CMAC_AXIS_TID_WID), .TDEST_WID(xilinx_alveo_pkg::CMAC_AXIS_TDEST_WID), .TUSER_WID(xilinx_alveo_pkg::CMAC_AXIS_TUSER_WID)) __axis_cmac_rx [NUM_CMAC] (.aclk(clk), .aresetn(!srst));
    axi4s_intf #(.DATA_BYTE_WID(xilinx_alveo_pkg::CMAC_DATA_BYTE_WID), .TID_WID(xilinx_alveo_pkg::CMAC_AXIS_TID_WID), .TDEST_WID(xilinx_alveo_pkg::CMAC_AXIS_TDEST_WID), .TUSER_WID(xilinx_alveo_pkg::CMAC_AXIS_TUSER_WID)) __axis_cmac_tx [NUM_CMAC] (.aclk(clk), .aresetn(!srst));

    axi4s_intf #(.DATA_BYTE_WID(xilinx_alveo_pkg::DMA_ST_DATA_BYTE_WID), .TID_WID(xilinx_alveo_pkg::DMA_ST_AXIS_TID_WID), .TDEST_WID(xilinx_alveo_pkg::DMA_ST_AXIS_TDEST_WID), .TUSER_WID(xilinx_alveo_pkg::DMA_ST_AXIS_TUSER_WID)) __axis_h2c (.aclk(clk), .aresetn(!srst));
    axi4s_intf #(.DATA_BYTE_WID(xilinx_alveo_pkg::DMA_ST_DATA_BYTE_WID), .TID_WID(xilinx_alveo_pkg::DMA_ST_AXIS_TID_WID), .TDEST_WID(xilinx_alveo_pkg::DMA_ST_AXIS_TDEST_WID), .TUSER_WID(xilinx_alveo_pkg::DMA_ST_AXIS_TUSER_WID)) __axis_c2h (.aclk(clk), .aresetn(!srst));

    // =========================================================================
    // Signals
    // =========================================================================
    logic clk_125mhz;
    logic clk_250mhz;
    logic clk_333mhz;

    // =========================================================================
    // Shell adaptation layer
    // (maps shell interface signals in flattened struct representation
    //  to/from interface representation)
    // =========================================================================
    shell_adapter__shell i_shell_adapter__shell (.*);

    assign mgmt_clk = axil_if.aclk;
    assign mgmt_srst = !axil_if.aresetn;

    // =========================================================================
    // Common Alveo core
    // =========================================================================
    xilinx_alveo #(
        .BUILD_TIMESTAMP ( BUILD_TIMESTAMP )
    ) i_xilinx_alveo  (
        .alveo_hw_if,
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
    // Shell top-level decoder
    // =========================================================================
    shell_decoder i_shell_decoder (
        .axil_if      ( axil_top ),
        .hw_axil_if   ( axil_hw ),
        .core_axil_if ( axil_if )
    );

    // =========================================================================
    // Map between shell and Alveo
    // =========================================================================
    generate
        for (genvar g_cmac = 0; g_cmac < NUM_CMAC; g_cmac++) begin : g__cmac
            // CMAC (Rx)
            shell_pkg::cmac_axis_tid_t   axis_cmac_rx_tid;
            shell_pkg::cmac_axis_tdest_t axis_cmac_rx_tdest;
            shell_pkg::cmac_axis_tuser_t axis_cmac_rx_tuser;

            xilinx_alveo_pkg::cmac_axis_tid_t   __axis_cmac_rx_tid;
            xilinx_alveo_pkg::cmac_axis_tdest_t __axis_cmac_rx_tdest;
            xilinx_alveo_pkg::cmac_axis_tuser_t __axis_cmac_rx_tuser;

            assign __axis_cmac_rx_tid           = __axis_cmac_rx[g_cmac].tid;
            assign axis_cmac_rx_tid.unused      = 1'b0;

            assign __axis_cmac_rx_tdest         = __axis_cmac_rx[g_cmac].tdest;
            assign axis_cmac_rx_tdest.unused    = 1'b0;

            assign __axis_cmac_rx_tuser         = __axis_cmac_rx[g_cmac].tuser;
            assign axis_cmac_rx_tuser.err       = __axis_cmac_rx_tuser.err;

            axi4s_set_meta #(
                .TID_WID    ( shell_pkg::CMAC_AXIS_TID_WID ),
                .TDEST_WID  ( shell_pkg::CMAC_AXIS_TDEST_WID ),
                .TUSER_WID  ( shell_pkg::CMAC_AXIS_TUSER_WID )
            ) i_axi4s_set_meta__cmac_rx (
                .from_tx ( __axis_cmac_rx[g_cmac] ),
                .to_rx   ( axis_cmac_rx[g_cmac] ),
                .tid     ( axis_cmac_rx_tid ),
                .tdest   ( axis_cmac_rx_tdest ),
                .tuser   ( axis_cmac_rx_tuser )
            );

            // CMAC (Tx)
            xilinx_alveo_pkg::cmac_axis_tid_t   __axis_cmac_tx_tid;
            xilinx_alveo_pkg::cmac_axis_tdest_t __axis_cmac_tx_tdest;
            xilinx_alveo_pkg::cmac_axis_tuser_t __axis_cmac_tx_tuser;

            shell_pkg::cmac_axis_tid_t   axis_cmac_tx_tid;
            shell_pkg::cmac_axis_tdest_t axis_cmac_tx_tdest;
            shell_pkg::cmac_axis_tuser_t axis_cmac_tx_tuser;

            assign axis_cmac_tx_tid               = axis_cmac_tx[g_cmac].tid;
            assign __axis_cmac_tx_tid.unused      = 1'b0;

            assign axis_cmac_tx_tdest             = axis_cmac_tx[g_cmac].tdest;
            assign __axis_cmac_tx_tdest.unused    = 1'b0;

            assign axis_cmac_tx_tuser             = axis_cmac_tx[g_cmac].tuser;
            assign __axis_cmac_tx_tuser.err       = axis_cmac_tx_tuser.err;

            axi4s_set_meta #(
                .TID_WID    ( xilinx_alveo_pkg::CMAC_AXIS_TID_WID ),
                .TDEST_WID  ( xilinx_alveo_pkg::CMAC_AXIS_TDEST_WID ),
                .TUSER_WID  ( xilinx_alveo_pkg::CMAC_AXIS_TUSER_WID )
            ) i_axi4s_set_meta__cmac_tx (
                .from_tx ( axis_cmac_tx[g_cmac] ),
                .to_rx   ( __axis_cmac_tx[g_cmac] ),
                .tid     ( __axis_cmac_tx_tid ),
                .tdest   ( __axis_cmac_tx_tdest ),
                .tuser   ( __axis_cmac_tx_tuser )
            );

        end : g__cmac
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

    axi4s_set_meta #(
        .TID_WID    ( shell_pkg::DMA_ST_AXIS_TID_WID ),
        .TDEST_WID  ( shell_pkg::DMA_ST_AXIS_TDEST_WID ),
        .TUSER_WID  ( shell_pkg::DMA_ST_AXIS_TUSER_WID )
    ) i_axi4s_set_meta__h2c (
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

    axi4s_set_meta #(
        .TID_WID    ( xilinx_alveo_pkg::DMA_ST_AXIS_TID_WID ),
        .TDEST_WID  ( xilinx_alveo_pkg::DMA_ST_AXIS_TDEST_WID ),
        .TUSER_WID  ( xilinx_alveo_pkg::DMA_ST_AXIS_TUSER_WID )
    ) i_axi4s_set_meta__c2h (
        .from_tx ( axis_c2h ),
        .to_rx   ( __axis_c2h ),
        .tid     ( __axis_c2h_tid ),
        .tdest   ( __axis_c2h_tdest ),
        .tuser   ( __axis_c2h_tuser )
    );
endmodule : xilinx_alveo_shell

