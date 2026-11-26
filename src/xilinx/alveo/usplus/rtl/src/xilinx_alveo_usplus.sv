module xilinx_alveo_usplus
    import xilinx_alveo_usplus_pkg::*;
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0,
    parameter PRODUCT_ID = "ESnet SmartNIC",
    parameter APPLICATION_ID = "(empty)",
    parameter logic [31:0] BUILD_ID = 0,
    parameter BUILD_GIT_REPO = "(empty)",
    parameter BUILD_GIT_HASH = "(empty)",
    parameter BUILD_TIMESTAMP_STR = "(empty)"
) (
    // To/from physical layer (hardware)
    xilinx_alveo_usplus_hw_intf.alveo  alveo_hw_if,

    // PCIe reset (post-JTAG-override, from xilinx_alveo_shell)
    input  wire logic     pci_rstn,

    output logic init_ready,

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
    output logic          dma_aclk,
    output logic          dma_aresetn,
    packet_intf.tx        pkt_h2c_dma,
    packet_intf.rx        pkt_c2h_dma,
    axi4l_intf.controller axil_qdma_st,
    // -- AXI-L (Controller, to top-level regmap)
    axi4l_intf.controller axil_top,
    // -- AXI-L (Peripheral, from top-level regmap, to h/w layer decoder)
    axi4l_intf.peripheral axil_hw
);

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

    logic clk_100mhz_freerun;
    logic mgmt_clk_50mhz;
    logic mgmt_srst;
    logic [4:0] mgmt_startup_count = '0;
    logic [31:0] vpd_status;
    logic vpd_init_done_mask;
    xilinx_pci_cfg_ext_intf cfg_ext_if (.clk(dma_aclk));

    // =========================================================================
    // Interfaces
    // =========================================================================
    axi4l_intf #() axil_syscfg ();
    axi4l_intf #() axil_cmac [NUM_CMAC] ();
    axi4l_intf #() axil_sysmon ();
    axi4l_intf #() axil_qspi ();
    axi4l_intf #() axil_cms ();

    // =========================================================================
    // Host
    // =========================================================================
    // Host instantiation
    xilinx_alveo_usplus_host #(
        .PCIE_LINK_WID ( alveo_hw_if.PCIE_LINK_WID )
    ) i_xilinx_alveo_usplus_host (
        .pcie_rstn     ( pci_rstn ),
        .pcie_refclk_p ( alveo_hw_if.pcie_refclk_p ),
        .pcie_refclk_n ( alveo_hw_if.pcie_refclk_n ),
        .pcie_rxp      ( alveo_hw_if.pcie_rxp ),
        .pcie_rxn      ( alveo_hw_if.pcie_rxn ),
        .pcie_txp      ( alveo_hw_if.pcie_txp ),
        .pcie_txn      ( alveo_hw_if.pcie_txn ),
        .clk_125mhz,
        .clk_250mhz,
        .axil_if       ( axil_top ),
        .cfg_ext_if,
        .dma_aclk,
        .dma_aresetn,
        .pkt_h2c_dma,
        .pkt_c2h_dma
    );

    // =========================================================================
    // Clock/reset generators
    // =========================================================================
    // Clock gen (250MHz to 100MHz/333MHz)
    xilinx_alveo_usplus_clk i_xilinx_alveo_usplus_clk (
        .clk_in1  ( clk_250mhz ),
        .clk_out1 ( clk_333mhz )
    );

    // Establish core clock domain
    assign core_clk = clk_333mhz;

    sync_reset i_sync_reset__clk (
        .clk_in  ( axil_top.aclk ),
        .rst_in  ( axil_top.aresetn ),
        .clk_out ( core_clk ),
        .rst_out ( core_srst )
    );

    // Import free-running 100Mhz clock (from hardware layer)
    assign clk_100mhz_freerun = alveo_hw_if.sys_clk_100mhz;

    assign clk_100mhz = clk_100mhz_freerun;

    // Export derived clocks to physical layer (hardware)
    assign alveo_hw_if.clk_125mhz = clk_125mhz;
    assign alveo_hw_if.clk_250mhz = clk_250mhz;
    assign alveo_hw_if.clk_333mhz = clk_333mhz;

    // Export clock/reset to core (application)
    assign clk = core_clk;
    assign srst = core_srst;

    // =========================================================================
    // Alveo (platform-level) decoder
    // =========================================================================
    xilinx_alveo_usplus_decoder i_xilinx_alveo_usplus_decoder (
        .axil_if        ( axil_hw ),
        .syscfg_axil_if ( axil_syscfg ),
        .qdma_axil_if   ( axil_qdma_st ),
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
    xilinx_alveo_usplus_dna i_xilinx_alveo_usplus_dna (
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
            xilinx_alveo_usplus_cmac #(
                .PORT_ID ( g_cmac )
            ) i_xilinx_alveo_usplus_cmac (
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
    axi4l_intf axil_sysmon__100mhz ();

    axi4l_intf_cdc i_axi4l_intf_cdc__sysmon (
        .axi4l_if_from_controller ( axil_sysmon ),
        .clk_to_peripheral        ( clk_100mhz_freerun ),
        .axi4l_if_to_peripheral   ( axil_sysmon__100mhz )
    );

    xilinx_sysmon_wrapper i_xilinx_sysmon_wrapper (.axil_if (axil_sysmon__100mhz));

    // =========================================================================
    // QSPI flash access
    // =========================================================================
    axi4l_intf axil_qspi__50mhz ();

    // Shared free-running 50 MHz peripheral clock; SPI SCK is 25 MHz.
    BUFGCE_DIV #(
        .BUFGCE_DIVIDE ( 2 )
    ) i_bufgce_div__mgmt (
        .I   ( clk_100mhz_freerun ),
        .CE  ( 1'b1 ),
        .CLR ( 1'b0 ),
        .O   ( mgmt_clk_50mhz )
    );

    // Initialization must complete while PCIe reset is held asserted.
    always @(posedge mgmt_clk_50mhz) begin
        if (!(&mgmt_startup_count)) mgmt_startup_count <= mgmt_startup_count + 1'b1;
    end
    assign mgmt_srst = !(&mgmt_startup_count);

    // The CDC also synchronizes the peripheral reset into the QSPI domain.
    axi4l_intf_cdc i_axi4l_intf_cdc__qspi (
        .axi4l_if_from_controller ( axil_qspi ),
        .clk_to_peripheral        ( mgmt_clk_50mhz ),
        .axi4l_if_to_peripheral   ( axil_qspi__50mhz )
    );

    xilinx_qspi i_xilinx_qspi (
        .axil_if ( axil_qspi__50mhz ),
        .irq     ( ) // Register access uses polling.
    );

    // =========================================================================
    // Card management access (board I/O is connected in the hardware layer)
    // =========================================================================
    axi4l_intf axil_cms__50mhz ();
    axi4l_intf_cdc i_axi4l_intf_cdc__cms (
        .axi4l_if_from_controller ( axil_cms ),
        .clk_to_peripheral        ( mgmt_clk_50mhz ),
        .axi4l_if_to_peripheral   ( axil_cms__50mhz )
    );

    xilinx_alveo_usplus_vpd #(
        .PRODUCT_ID(PRODUCT_ID), .APPLICATION_ID(APPLICATION_ID),
        .BUILD_ID(BUILD_ID), .BUILD_GIT_REPO(BUILD_GIT_REPO),
        .BUILD_GIT_HASH(BUILD_GIT_HASH), .BUILD_TIMESTAMP_STR(BUILD_TIMESTAMP_STR)
    ) i_xilinx_alveo_usplus_vpd (
        .clk(mgmt_clk_50mhz), .srst(mgmt_srst),
        .cfg_aresetn(dma_aresetn), .cfg_ext_if,
        .cms_axil_from_controller(axil_cms__50mhz),
        .cms_axil_to_peripheral(alveo_hw_if.axil_cms),
        .init_done_mask(vpd_init_done_mask), .ready(init_ready), .status(vpd_status)
    );

    sync_level #(.RST_VALUE(1'b0)) i_sync_level__vpd_mask (
        .clk_in(axil_syscfg.aclk), .rst_in(!axil_syscfg.aresetn), .rdy_in(),
        .lvl_in(reg_if.vpd_control.init_done_mask),
        .clk_out(mgmt_clk_50mhz), .rst_out(mgmt_srst), .lvl_out(vpd_init_done_mask)
    );
    assign reg_if.vpd_status_nxt_v = 1'b1;
    sync_bus_sampled #(.DATA_WID(32), .RST_VALUE(0)) i_sync_bus_sampled__vpd_status (
        .clk_in(mgmt_clk_50mhz), .rst_in(mgmt_srst), .data_in(vpd_status),
        .clk_out(axil_syscfg.aclk), .rst_out(!axil_syscfg.aresetn),
        .data_out(reg_if.vpd_status_nxt)
    );

endmodule : xilinx_alveo_usplus
