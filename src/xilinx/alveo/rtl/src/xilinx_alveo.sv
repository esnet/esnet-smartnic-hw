module xilinx_alveo
    import xilinx_alveo_pkg::*;
#(
    parameter int NUM_CMAC = 2,
    parameter int PCIE_LINK_WID = 16,
    parameter bit INCLUDE_QSPI = 1,
    parameter bit INCLUDE_SYSMON = 1,
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0
) (
    // From/to pins
    // -- QSFPs
    input  wire [NUM_CMAC-1:0]       qsfp_refclk_p,
    input  wire [NUM_CMAC-1:0]       qsfp_refclk_n,
    input  wire [NUM_CMAC-1:0][3:0]  qsfp_rxp,
    input  wire [NUM_CMAC-1:0][3:0]  qsfp_rxn,
    output wire [NUM_CMAC-1:0][3:0]  qsfp_txp,
    output wire [NUM_CMAC-1:0][3:0]  qsfp_txn,
    // -- PCIe
    input  wire                      pcie_rstn,
    input  wire                      pcie_refclk_p,
    input  wire                      pcie_refclk_n,
    input  wire [PCIE_LINK_WID-1:0]  pcie_rxp,
    input  wire [PCIE_LINK_WID-1:0]  pcie_rxn,
    output wire [PCIE_LINK_WID-1:0]  pcie_txp,
    output wire [PCIE_LINK_WID-1:0]  pcie_txn,

    // Clocks (output)
    output wire                      clk_100mhz,
    output wire                      clk_125mhz,
    output wire                      clk_250mhz,
    output wire                      clk_333mhz,

    // To/from core
    // -- (Input) clock/reset
    output wire                      clk,
    output wire                      srst,
    // -- CMACs
    axi4s_intf.tx                    axis_cmac_rx [NUM_CMAC],
    axi4s_intf.rx                    axis_cmac_tx [NUM_CMAC],
    // -- DMA (streaming)
    axi4s_intf.tx                    axis_h2c [NUM_DMA_ST],
    axi4s_intf.rx                    axis_c2h [NUM_DMA_ST],
    // -- AXI-L (Controller)
    axi4l_intf.controller            axil_if,

    // To board-specific CMS (card management subsystem) component
    axi4l_intf.controller            axil_cms
);
    // =========================================================================
    // Signals
    // =========================================================================
    logic core_clk;
    logic core_srst;

    logic jtag_reset;

    // =========================================================================
    // Interfaces
    // =========================================================================
    axi4l_intf #() axil_top ();
    axi4l_intf #() axil_alveo ();
    axi4l_intf #() axil_syscfg ();
    axi4l_intf #() axil_qdma ();
    axi4l_intf #() axil_cmac [NUM_CMAC_REGMAP] ();
    axi4l_intf #() axil_sysmon ();
    axi4l_intf #() axil_qspi ();

    axi4s_intf #(.DATA_BYTE_WID(DMA_ST_DATA_BYTE_WID), .TID_T(dma_st_qid_t), .TUSER_T(dma_st_axis_tuser_t)) __axis_h2c [NUM_CMAC] ();
    axi4s_intf #(.DATA_BYTE_WID(DMA_ST_DATA_BYTE_WID), .TID_T(dma_st_qid_t), .TUSER_T(dma_st_axis_tuser_t)) __axis_c2h [NUM_CMAC] ();

    // =========================================================================
    // Host
    // =========================================================================
    xilinx_alveo_host #(
        .PCIE_LINK_WID ( PCIE_LINK_WID )
    ) i_xilinx_alveo_host (
        .pcie_rstn,
        .pcie_refclk_p,
        .pcie_refclk_n,
        .pcie_rxp,
        .pcie_rxn,
        .pcie_txp,
        .pcie_txn,
        .clk_125mhz,
        .clk_250mhz,
        .axil_if (axil_top),
        .axil_qdma,
        .axis_h2c (__axis_h2c),
        .axis_c2h (__axis_c2h)
    );

    generate
        for (genvar g_dma_st = 0; g_dma_st < NUM_DMA_ST; g_dma_st++) begin : g__dma_st
            // (Local) interfaces
            axi4s_intf #(.DATA_BYTE_WID(DMA_ST_DATA_BYTE_WID), .TID_T(dma_st_qid_t), .TUSER_T(dma_st_axis_tuser_t)) __axis_h2c__async ();

            // AXI-S CDC
            axi4s_fifo_async #(
                .DEPTH        ( 32 )
            ) i_axi4s_fifo_async__h2c (
                .axi4s_in     ( __axis_h2c[g_dma_st] ),
                .axi4s_out    ( __axis_h2c__async )
            );
            assign __axis_h2c__async.aclk = core_clk;
            assign __axis_h2c__async.aresetn = !core_srst;

            assign axis_h2c[g_dma_st].aclk    = __axis_h2c__async.aclk;
            assign axis_h2c[g_dma_st].aresetn = __axis_h2c__async.aresetn;
            assign axis_h2c[g_dma_st].tvalid  = __axis_h2c__async.tvalid;
            assign axis_h2c[g_dma_st].tlast   = __axis_h2c__async.tlast;
            assign axis_h2c[g_dma_st].tkeep   = __axis_h2c__async.tkeep;
            assign axis_h2c[g_dma_st].tdata   = __axis_h2c__async.tdata;
            assign axis_h2c[g_dma_st].tid     = __axis_h2c__async.tid;
            assign axis_h2c[g_dma_st].tdest   = __axis_h2c__async.tdest;
            assign axis_h2c[g_dma_st].tuser   = __axis_h2c__async.tuser;

            axi4s_fifo_async #(
                .DEPTH        ( 32 )
            ) i_axi4s_fifo_async__c2h (
                .axi4s_in     ( axis_c2h  [g_dma_st] ),
                .axi4s_out    ( __axis_c2h[g_dma_st] )
            );

        end : g__dma_st
    endgenerate

    // =========================================================================
    // Clock/reset generators
    // =========================================================================
    // Clock gen (250MHz to 100MHz/333MHz)
    xilinx_alveo_clk i_xilinx_alveo_clk (
        .clk_in1  ( clk_250mhz ),
        .clk_out1 ( clk_100mhz ),
        .clk_out2 ( clk_333mhz )
    );

    // Establish core clock domain
    assign core_clk = clk_333mhz;
    
    sync_reset i_sync_reset__clk (
        .clk_in  ( axil_top.aclk ),
        .rst_in  ( axil_top.aresetn ),
        .clk_out ( core_clk ),
        .rst_out ( core_srst )
    );
    
    // Drive output ports
    assign clk = core_clk;
    assign srst = core_srst;
    
    // =========================================================================
    // BAR2 (top-level) decoder
    // =========================================================================
    bar2_decoder i_bar2_decoder (
        .axil_if     ( axil_top ),
        .hw_axil_if  ( axil_alveo ),
        .app_axil_if ( axil_if )
    );

    // =========================================================================
    // Alveo (platform-level) decoder
    // =========================================================================
    xilinx_alveo_decoder i_xilinx_alveo_decoder (
        .axil_if        ( axil_alveo ),
        .syscfg_axil_if ( axil_syscfg ),
        .qdma_axil_if   ( axil_qdma ),
        .cmac0_axil_if  ( axil_cmac[0] ),
        .cmac1_axil_if  ( axil_cmac[1] ),
        .sysmon_axil_if ( axil_sysmon ),
        .qspi_axil_if   ( axil_qspi ),
        .cms_axil_if    ( axil_cms )
    );

    // =========================================================================
    // System config registers
    // =========================================================================
    // (Local) signals
    logic [95:0] dna;
    logic        dna_valid;

    // (Local) interfaces
    syscfg_reg_intf reg_if ();

    // System config register block
    syscfg_reg_blk i_syscfg_reg_blk (
        .axil_if (axil_syscfg),
        .reg_blk_if (reg_if)
    );

    // Resets
    // TEMP: report system reset done
    assign reg_if.system_status_nxt_v = 1'b1;
    assign reg_if.system_status_nxt = 1'b1;

    // TEMP: report shell reset done
    assign reg_if.shell_status_nxt_v = 1'b1;
    assign reg_if.shell_status_nxt = '1;

    // TEMP: report user reset done
    assign reg_if.user_status_nxt_v = 1'b1;
    assign reg_if.user_status_nxt = '1;

    // Build timestamp
    assign reg_if.build_status_nxt_v = 1'b1;
    assign reg_if.build_status_nxt = BUILD_TIMESTAMP;

    // USR access port
    USR_ACCESSE2 USR_ACCESSE2_0 (
        .CFGCLK    ( ),                        // 1-bit output: Configuration Clock
        .DATA      ( reg_if.usr_access_nxt),   // 32-bit output: Configuration Data reflecting the contents of the AXSS register
        .DATAVALID ( )                         // 1-bit output: Active-High Data Valid
    );
    assign reg_if.usr_access_nxt_v = 1'b1;

    // DNA access port
    xilinx_alveo_dna i_xilinx_alveo_dna (
        .clk   ( axil_syscfg.aclk ),
        .srst  ( !axil_syscfg.aresetn ),
        .valid ( dna_valid ),
        .dna   ( dna )
    );

    assign reg_if.dna_nxt[0] = dna[95:64];
    assign reg_if.dna_nxt[1] = dna[63:32];
    assign reg_if.dna_nxt[2] = dna[31:0];
    assign reg_if.dna_nxt_v = '{3{dna_valid}};

    // =========================================================================
    // CMACs
    // =========================================================================
    generate
        for (genvar g_cmac = 0; g_cmac < NUM_CMAC; g_cmac++) begin : g__cmac
            axi4s_intf #(.DATA_BYTE_WID(CMAC_DATA_BYTE_WID), .TID_T(xilinx_cmac_pkg::axis_tid_t), .TUSER_T(xilinx_cmac_pkg::axis_tuser_t)) __axis_cmac_rx ();
            axi4s_intf #(.DATA_BYTE_WID(CMAC_DATA_BYTE_WID), .TID_T(xilinx_cmac_pkg::axis_tid_t), .TUSER_T(xilinx_cmac_pkg::axis_tuser_t)) __axis_cmac_rx__async ();
            axi4s_intf #(.DATA_BYTE_WID(CMAC_DATA_BYTE_WID), .TID_T(xilinx_cmac_pkg::axis_tid_t), .TUSER_T(xilinx_cmac_pkg::axis_tuser_t)) __axis_cmac_tx ();

            xilinx_alveo_cmac #(
                .PORT_ID ( g_cmac )
            ) i_xilinx_alveo_cmac (
                .clk           ( axil_if.aclk    ),
                .srstn         ( axil_if.aresetn ),
                .qsfp_refclk_p ( qsfp_refclk_p[g_cmac] ),
                .qsfp_refclk_n ( qsfp_refclk_n[g_cmac] ),
                .qsfp_rxp      ( qsfp_rxp     [g_cmac] ),
                .qsfp_rxn      ( qsfp_rxn     [g_cmac] ),
                .qsfp_txp      ( qsfp_txp     [g_cmac] ),
                .qsfp_txn      ( qsfp_txn     [g_cmac] ),
                .axis_rx       ( __axis_cmac_rx ),
                .axis_tx       ( __axis_cmac_tx ),
                .axil_if       ( axil_cmac    [g_cmac] )
            );

            // AXI-S CDC
            axi4s_fifo_async #(
                .DEPTH        ( 32 )
            ) i_axi4s_fifo_async__cmac_rx (
                .axi4s_in     ( __axis_cmac_rx ),
                .axi4s_out    ( __axis_cmac_rx__async )
            );
            assign __axis_cmac_rx__async.aclk = core_clk;
            assign __axis_cmac_rx__async.aresetn = !core_srst;

            assign axis_cmac_rx[g_cmac].aclk    = __axis_cmac_rx__async.aclk;
            assign axis_cmac_rx[g_cmac].aresetn = __axis_cmac_rx__async.aresetn;
            assign axis_cmac_rx[g_cmac].tvalid  = __axis_cmac_rx__async.tvalid;
            assign axis_cmac_rx[g_cmac].tlast   = __axis_cmac_rx__async.tlast;
            assign axis_cmac_rx[g_cmac].tkeep   = __axis_cmac_rx__async.tkeep;
            assign axis_cmac_rx[g_cmac].tdata   = __axis_cmac_rx__async.tdata;
            assign axis_cmac_rx[g_cmac].tid     = __axis_cmac_rx__async.tid;
            assign axis_cmac_rx[g_cmac].tdest   = __axis_cmac_rx__async.tdest;
            assign axis_cmac_rx[g_cmac].tuser   = __axis_cmac_rx__async.tuser;

            axi4s_fifo_async #(
                .DEPTH        ( 32 )
            ) i_axi4s_fifo_async__cmac_tx (
                .axi4s_in     ( axis_cmac_tx[g_cmac] ),
                .axi4s_out    ( __axis_cmac_tx )
            );
        end : g__cmac
        for (genvar g_cmac = NUM_CMAC; g_cmac < NUM_CMAC_REGMAP; g_cmac++) begin : g__cmac_reg_tieoff
            axi4l_intf_peripheral_term (.axi4l_if (axil_cmac[g_cmac]));
        end : g__cmac_reg_tieoff
    endgenerate

    // =========================================================================
    // System monitor
    // =========================================================================
    generate
        if (INCLUDE_SYSMON) begin : g__sysmon
            xilinx_sysmon_wrapper i_xilinx_sysmon_wrapper (.axil_if (axil_sysmon));
        end : g__sysmon
        else begin : g__no_sysmon
            axi4l_intf_peripheral_term (.axi4l_if (axil_sysmon));
        end : g__no_sysmon
    endgenerate

    // =========================================================================
    // QSPI flash access
    // =========================================================================
    generate
        if (INCLUDE_QSPI) begin : g__qspi
            // TODO: Add QSPI instance
        end : g__qspi
        else begin : g__no_qspi
            axi4l_intf_peripheral_term (.axi4l_if (axil_qspi));
        end : g__no_qspi
    endgenerate

    // =========================================================================
    // JTAG debug (VIO)
    // =========================================================================
    xilinx_alveo_debug i_xilinx_alveo_debug (
        .clk       ( clk_100mhz ),
        .reset_in  ( axil_if.aresetn ),
        .reset_out ( jtag_reset )
    );

endmodule : xilinx_alveo
