module xilinx_alveo
    import xilinx_alveo_pkg::*;
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0
) (
    // To/from physical layer (hardware)
    xilinx_alveo_hw_intf.alveo  alveo_hw_if,

    // To/from core (application)
    // -- Core clock/reset
    output wire logic     clk,
    output wire logic     srst,
    // -- Auxiliary clocks
    output wire logic     clk_100mhz,
    output wire logic     clk_125mhz,
    output wire logic     clk_250mhz,
    output wire logic     clk_333mhz,
    // -- CMACs
    axi4s_intf.tx         axis_cmac_rx [NUM_CMAC],
    axi4s_intf.rx         axis_cmac_tx [NUM_CMAC],
    // -- DMA (streaming)
    axi4s_intf.tx         axis_h2c,
    axi4s_intf.rx         axis_c2h,
    // -- AXI-L (Controller, to top-level regmap)
    axi4l_intf.controller axil_top,
    // -- AXI-L (Peripheral, from top-level regmap, to h/w layer decoder)
    axi4l_intf.peripheral axil_hw
);

    // =========================================================================
    // Parameters
    // =========================================================================
    localparam bit INCLUDE_QSPI = 0;

    // =========================================================================
    // Parameter checking
    // =========================================================================
    initial begin
        // QSFP interfaces must be matched 1:1 to CMACs
        // (no ability to tie off unused interfaces)
        std_pkg::param_check(alveo_hw_if.NUM_QSFP, NUM_CMAC, "alveo_hw_if.NUM_QSFP");
    end

    // =========================================================================
    // Signals
    // =========================================================================
    logic core_clk;
    logic core_srst;

    logic jtag_reset;

    logic axis_qdma_aclk;
    logic axis_qdma_aresetn;

    // =========================================================================
    // Interfaces
    // =========================================================================
    axi4l_intf #() axil_syscfg ();
    axi4l_intf #() axil_qdma ();
    axi4l_intf #() axil_cmac [NUM_CMAC] ();
    axi4l_intf #() axil_sysmon ();
    axi4l_intf #() axil_qspi ();

    // =========================================================================
    // Host
    // =========================================================================
    // (Local) interfaces
    axi4s_intf #(
        .DATA_BYTE_WID(xilinx_qdma_pkg::AXIS_DATA_BYTE_WID), .TID_WID  (xilinx_qdma_pkg::AXIS_TID_WID),
        .TDEST_WID    (xilinx_qdma_pkg::AXIS_TDEST_WID),     .TUSER_WID(xilinx_qdma_pkg::AXIS_TUSER_WID)
    ) __axis_h2c (.aclk(axis_qdma_aclk));

    axi4s_intf #(
        .DATA_BYTE_WID(xilinx_qdma_pkg::AXIS_DATA_BYTE_WID), .TID_WID  (xilinx_qdma_pkg::AXIS_TID_WID),
        .TDEST_WID    (xilinx_qdma_pkg::AXIS_TDEST_WID),     .TUSER_WID(xilinx_qdma_pkg::AXIS_TUSER_WID)
    ) __axis_h2c__core_clk (.aclk(core_clk));

    axi4s_intf #(
        .DATA_BYTE_WID(xilinx_qdma_pkg::AXIS_DATA_BYTE_WID), .TID_WID  (xilinx_qdma_pkg::AXIS_TID_WID),
        .TDEST_WID    (xilinx_qdma_pkg::AXIS_TDEST_WID),     .TUSER_WID(xilinx_qdma_pkg::AXIS_TUSER_WID)
    ) __axis_c2h__core_clk (.aclk(core_clk));

    axi4s_intf #(
        .DATA_BYTE_WID(xilinx_qdma_pkg::AXIS_DATA_BYTE_WID), .TID_WID  (xilinx_qdma_pkg::AXIS_TID_WID),
        .TDEST_WID    (xilinx_qdma_pkg::AXIS_TDEST_WID),     .TUSER_WID(xilinx_qdma_pkg::AXIS_TUSER_WID)
    ) __axis_c2h (.aclk(axis_qdma_aclk));

    // (Local) signals
    xilinx_qdma_pkg::axis_tid_t   __axis_h2c_tid;
    xilinx_qdma_pkg::axis_tdest_t __axis_h2c_tdest;
    xilinx_qdma_pkg::axis_tuser_t __axis_h2c_tuser;

    dma_st_axis_tid_t   axis_h2c_tid;
    dma_st_axis_tdest_t axis_h2c_tdest;
    dma_st_axis_tuser_t axis_h2c_tuser;

    dma_st_axis_tid_t   axis_c2h_tid;
    dma_st_axis_tdest_t axis_c2h_tdest;
    dma_st_axis_tuser_t axis_c2h_tuser;

    xilinx_qdma_pkg::axis_tid_t   __axis_c2h_tid;
    xilinx_qdma_pkg::axis_tdest_t __axis_c2h_tdest;
    xilinx_qdma_pkg::axis_tuser_t __axis_c2h_tuser;

    // Host instantiation
    xilinx_alveo_host #(
        .PCIE_LINK_WID ( alveo_hw_if.PCIE_LINK_WID )
    ) i_xilinx_alveo_host (
        .pcie_rstn     ( alveo_hw_if.pcie_rstn ),
        .pcie_refclk_p ( alveo_hw_if.pcie_refclk_p ),
        .pcie_refclk_n ( alveo_hw_if.pcie_refclk_n ),
        .pcie_rxp      ( alveo_hw_if.pcie_rxp ),
        .pcie_rxn      ( alveo_hw_if.pcie_rxn ),
        .pcie_txp      ( alveo_hw_if.pcie_txp ),
        .pcie_txn      ( alveo_hw_if.pcie_txn ),
        .clk_125mhz,
        .clk_250mhz,
        .axil_if       ( axil_top ),
        .axil_qdma,
        .axis_aclk     ( axis_qdma_aclk ),
        .axis_aresetn  ( axis_qdma_aresetn ),
        .axis_h2c      ( __axis_h2c ),
        .axis_c2h      ( __axis_c2h )
    );

    // AXI-S CDC
    axi4s_fifo_async #(
        .DEPTH        ( 32 )
    ) i_axi4s_fifo_async__h2c (
        .from_tx      ( __axis_h2c ),
        .from_tx_srst ( !axis_qdma_aresetn ),
        .to_rx        ( __axis_h2c__core_clk ),
        .to_rx_srst   ( core_srst )
    );

    axi4s_fifo_async #(
        .DEPTH        ( 32 )
    ) i_axi4s_fifo_async__c2h (
        .from_tx      ( __axis_c2h__core_clk ),
        .from_tx_srst ( core_srst ),
        .to_rx        ( __axis_c2h ),
        .to_rx_srst   ( !axis_qdma_aresetn )
    );

    // Map between Alveo interfaces and QDMA interfaces
    // -- H2C
    assign axis_h2c.tvalid  = __axis_h2c__core_clk.tvalid;
    assign axis_h2c.tlast   = __axis_h2c__core_clk.tlast;
    assign axis_h2c.tkeep   = __axis_h2c__core_clk.tkeep;
    assign axis_h2c.tdata   = __axis_h2c__core_clk.tdata;

    assign __axis_h2c_tid   = __axis_h2c__core_clk.tid;
    assign axis_h2c_tid.qid = __axis_h2c_tid.qid;
    assign axis_h2c.tid     = axis_h2c_tid;

    assign __axis_h2c_tdest      = __axis_h2c__core_clk.tdest;
    assign axis_h2c_tdest.unused = '0;
    assign axis_h2c.tdest        = axis_h2c_tdest;

    assign __axis_h2c_tuser   = __axis_h2c__core_clk.tuser;
    assign axis_h2c_tuser.err = __axis_h2c_tuser.err;
    assign axis_h2c.tuser     = axis_h2c_tuser;

    assign __axis_h2c__core_clk.tready = axis_h2c.tready;

    // -- C2H
    assign __axis_c2h__core_clk.tvalid = axis_c2h.tvalid;
    assign __axis_c2h__core_clk.tlast  = axis_c2h.tlast;
    assign __axis_c2h__core_clk.tkeep  = axis_c2h.tkeep;
    assign __axis_c2h__core_clk.tdata  = axis_c2h.tdata;

    assign axis_c2h_tid             = axis_c2h.tid;
    assign __axis_c2h_tid.qid       = axis_c2h_tid.qid;
    assign __axis_c2h__core_clk.tid = __axis_c2h_tid;

    assign axis_c2h_tdest             = axis_c2h.tdest;
    assign __axis_c2h_tdest.unused    = 1'b0;
    assign __axis_c2h__core_clk.tdest = __axis_c2h_tdest;

    assign axis_c2h_tuser             = axis_c2h.tuser;
    assign __axis_c2h_tuser.err       = axis_c2h_tuser.err;
    assign __axis_c2h__core_clk.tuser = __axis_c2h_tuser;

    assign axis_c2h.tready = __axis_c2h__core_clk.tready;

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

    // Export derived clocks to physical layer (hardware)
    assign alveo_hw_if.clk_100mhz = clk_100mhz;
    assign alveo_hw_if.clk_125mhz = clk_125mhz;
    assign alveo_hw_if.clk_250mhz = clk_250mhz;
    assign alveo_hw_if.clk_333mhz = clk_333mhz;

    // Export clock/reset to core (application)
    assign clk = core_clk;
    assign srst = core_srst;

    // =========================================================================
    // Alveo (platform-level) decoder
    // =========================================================================
    xilinx_alveo_decoder i_xilinx_alveo_decoder (
        .axil_if        ( axil_hw ),
        .syscfg_axil_if ( axil_syscfg ),
        .qdma_axil_if   ( axil_qdma ),
        .cmac0_axil_if  ( axil_cmac[0] ),
        .cmac1_axil_if  ( axil_cmac[1] ),
        .sysmon_axil_if ( axil_sysmon ),
        .qspi_axil_if   ( axil_qspi ),
        .cms_axil_if    ( alveo_hw_if.axil_cms )
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
            // (Local) signals
            logic cmac_clk;

            // (Local) interfaces
            axi4s_intf #(
                .DATA_BYTE_WID(CMAC_DATA_BYTE_WID),              .TID_WID  (xilinx_cmac_pkg::AXIS_TID_WID),
                .TDEST_WID    (xilinx_cmac_pkg::AXIS_TDEST_WID), .TUSER_WID(xilinx_cmac_pkg::AXIS_TUSER_WID)
            ) __axis_cmac_rx (.aclk(cmac_clk));

            axi4s_intf #(
                .DATA_BYTE_WID(CMAC_DATA_BYTE_WID),              .TID_WID  (xilinx_cmac_pkg::AXIS_TID_WID),
                .TDEST_WID    (xilinx_cmac_pkg::AXIS_TDEST_WID), .TUSER_WID(xilinx_cmac_pkg::AXIS_TUSER_WID)
            ) __axis_cmac_rx__core_clk (.aclk(core_clk));

            axi4s_intf #(
                .DATA_BYTE_WID(CMAC_DATA_BYTE_WID),              .TID_WID  (xilinx_cmac_pkg::AXIS_TID_WID),
                .TDEST_WID    (xilinx_cmac_pkg::AXIS_TDEST_WID), .TUSER_WID(xilinx_cmac_pkg::AXIS_TUSER_WID)
            ) __axis_cmac_tx__core_clk (.aclk(core_clk));

            axi4s_intf #(
                .DATA_BYTE_WID(CMAC_DATA_BYTE_WID),              .TID_WID  (xilinx_cmac_pkg::AXIS_TID_WID),
                .TDEST_WID    (xilinx_cmac_pkg::AXIS_TDEST_WID), .TUSER_WID(xilinx_cmac_pkg::AXIS_TUSER_WID)
            ) __axis_cmac_tx (.aclk(cmac_clk));

            // (Local) signals
            xilinx_cmac_pkg::axis_tid_t   __axis_cmac_rx_tid;
            xilinx_cmac_pkg::axis_tdest_t __axis_cmac_rx_tdest;
            xilinx_cmac_pkg::axis_tuser_t __axis_cmac_rx_tuser;

            cmac_axis_tid_t   axis_cmac_rx_tid;
            cmac_axis_tdest_t axis_cmac_rx_tdest;
            cmac_axis_tuser_t axis_cmac_rx_tuser;

            cmac_axis_tid_t   axis_cmac_tx_tid;
            cmac_axis_tdest_t axis_cmac_tx_tdest;
            cmac_axis_tuser_t axis_cmac_tx_tuser;

            xilinx_cmac_pkg::axis_tid_t   __axis_cmac_tx_tid;
            xilinx_cmac_pkg::axis_tdest_t __axis_cmac_tx_tdest;
            xilinx_cmac_pkg::axis_tuser_t __axis_cmac_tx_tuser;

            // CMAC instantatiation
            xilinx_alveo_cmac #(
                .PORT_ID ( g_cmac )
            ) i_xilinx_alveo_cmac (
                .clk           ( core_clk ),
                .srst          ( core_srst ),
                .qsfp_refclk_p ( alveo_hw_if.qsfp_refclk_p[g_cmac] ),
                .qsfp_refclk_n ( alveo_hw_if.qsfp_refclk_n[g_cmac] ),
                .qsfp_rxp      ( alveo_hw_if.qsfp_rxp     [g_cmac] ),
                .qsfp_rxn      ( alveo_hw_if.qsfp_rxn     [g_cmac] ),
                .qsfp_txp      ( alveo_hw_if.qsfp_txp     [g_cmac] ),
                .qsfp_txn      ( alveo_hw_if.qsfp_txn     [g_cmac] ),
                .axis_rx       ( __axis_cmac_rx ),
                .axis_tx       ( __axis_cmac_tx ),
                .cmac_clk      ( cmac_clk ),
                .axil_if       ( axil_cmac    [g_cmac] )
            );

            // AXI-S CDC
            axi4s_fifo_async #(
                .DEPTH        ( 32 )
            ) i_axi4s_fifo_async__cmac_rx (
                .from_tx      ( __axis_cmac_rx ),
                .from_tx_srst ( 1'b0 ),
                .to_rx        ( __axis_cmac_rx__core_clk ),
                .to_rx_srst   ( core_srst )
            );

            axi4s_fifo_async #(
                .DEPTH        ( 32 )
            ) i_axi4s_fifo_async__cmac_tx (
                .from_tx      ( __axis_cmac_tx__core_clk ),
                .from_tx_srst ( core_srst ),
                .to_rx        ( __axis_cmac_tx ),
                .to_rx_srst   ( 1'b0 )
            );

            // Map between Alveo interfaces and QDMA interfaces
            // -- CMAC Rx
            assign axis_cmac_rx[g_cmac].tvalid  = __axis_cmac_rx__core_clk.tvalid;
            assign axis_cmac_rx[g_cmac].tlast   = __axis_cmac_rx__core_clk.tlast;
            assign axis_cmac_rx[g_cmac].tkeep   = __axis_cmac_rx__core_clk.tkeep;
            assign axis_cmac_rx[g_cmac].tdata   = __axis_cmac_rx__core_clk.tdata;

            assign __axis_cmac_rx_tid       = __axis_cmac_rx__core_clk.tid;
            assign axis_cmac_rx_tid.unused  = 1'b0;
            assign axis_cmac_rx[g_cmac].tid = axis_cmac_rx_tid;

            assign __axis_cmac_rx_tdest       = __axis_cmac_rx__core_clk.tdest;
            assign axis_cmac_rx_tdest.unused  = 1'b0;
            assign axis_cmac_rx[g_cmac].tdest = axis_cmac_rx_tdest;

            assign __axis_cmac_rx_tuser       = __axis_cmac_rx__core_clk.tuser;
            assign axis_cmac_rx_tuser.err     = __axis_cmac_rx_tuser.err;
            assign axis_cmac_rx[g_cmac].tuser = axis_cmac_rx_tuser;

            assign __axis_cmac_rx__core_clk.tready = axis_cmac_rx[g_cmac].tready;

            // -- CMAC Tx
            assign __axis_cmac_tx__core_clk.tvalid = axis_cmac_tx[g_cmac].tvalid;
            assign __axis_cmac_tx__core_clk.tlast  = axis_cmac_tx[g_cmac].tlast;
            assign __axis_cmac_tx__core_clk.tkeep  = axis_cmac_tx[g_cmac].tkeep;
            assign __axis_cmac_tx__core_clk.tdata  = axis_cmac_tx[g_cmac].tdata;

            assign axis_cmac_tx_tid              = axis_cmac_tx[g_cmac].tid;
            assign __axis_cmac_tx_tid.unused     = 1'b0;
            assign __axis_cmac_tx__core_clk.tid  = __axis_cmac_tx_tid;

            assign axis_cmac_tx_tdest             = axis_cmac_tx[g_cmac].tdest;
            assign __axis_cmac_tx_tdest.unused    = 1'b0;
            assign __axis_cmac_tx__core_clk.tdest = __axis_cmac_tx_tdest;

            assign axis_cmac_tx_tuser             = axis_cmac_tx[g_cmac].tuser;
            assign __axis_cmac_tx_tuser.err       = axis_cmac_tx_tuser.err;
            assign __axis_cmac_tx__core_clk.tuser = __axis_cmac_tx_tuser;

            assign axis_cmac_tx[g_cmac].tready = __axis_cmac_tx__core_clk.tready;

        end : g__cmac
    endgenerate

    // =========================================================================
    // System monitor
    // =========================================================================
    xilinx_sysmon_wrapper i_xilinx_sysmon_wrapper (.axil_if (axil_sysmon));

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
        .reset_in  ( axil_top.aresetn ),
        .reset_out ( jtag_reset )
    );

endmodule : xilinx_alveo
