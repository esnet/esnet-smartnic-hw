module shell_adapter__core
    import shell_pkg::*;
(
    // Clock/reset
    input  wire logic clk,
    input  wire logic srst,

    input  wire logic mgmt_clk,
    input  wire logic mgmt_srst,

    input  wire logic clk_100mhz,

    // Shell-side interface
    // ----------------------------
    input  wire logic [SHELL_TO_CORE_WID-1:0] shell_to_core,
    output wire logic [CORE_TO_SHELL_WID-1:0] core_to_shell,

    // Core-side interface
    // ----------------------------
    // AXI-L
    axi4l_intf.controller axil_if,

    // CMAC
    axi4s_intf.tx axis_cmac_rx [NUM_CMAC],
    axi4s_intf.rx axis_cmac_tx [NUM_CMAC],

    // DMA (streaming)
    axi4s_intf.tx axis_h2c,
    axi4s_intf.rx axis_c2h
);
    // 'Cast' shell interface to structs
    shell_to_core_t __shell_to_core;
    core_to_shell_t __core_to_shell;

    assign __shell_to_core = shell_to_core;
    assign core_to_shell = __core_to_shell;

    // AXI-L control
    axil_fwd_t shell_to_core_axil;
    axil_rev_t core_to_shell_axil;

    assign shell_to_core_axil = __shell_to_core.axil;
    assign __core_to_shell.axil = core_to_shell_axil;

    axi4l_intf_from_signals #(
        .ADDR_WID ( AXIL_ADDR_WID )
    ) i_axi4l_intf_from_signals (
        .aclk    (  mgmt_clk ),
        .aresetn ( !mgmt_srst ),
        .awvalid ( shell_to_core_axil.awvalid ),
        .awready ( core_to_shell_axil.awready ),
        .awaddr  ( shell_to_core_axil.awaddr ),
        .awprot  ( shell_to_core_axil.awprot ),
        .wvalid  ( shell_to_core_axil.wvalid ),
        .wready  ( core_to_shell_axil.wready ),
        .wdata   ( shell_to_core_axil.wdata ),
        .wstrb   ( shell_to_core_axil.wstrb ),
        .bvalid  ( core_to_shell_axil.bvalid ),
        .bready  ( shell_to_core_axil.bready ),
        .bresp   ( core_to_shell_axil.bresp ),
        .arvalid ( shell_to_core_axil.arvalid ),
        .arready ( core_to_shell_axil.arready ),
        .araddr  ( shell_to_core_axil.araddr ),
        .arprot  ( shell_to_core_axil.arprot ),
        .rvalid  ( core_to_shell_axil.rvalid ),
        .rready  ( shell_to_core_axil.rready ),
        .rdata   ( core_to_shell_axil.rdata ),
        .rresp   ( core_to_shell_axil.rresp ),
        .axi4l_if( axil_if )
    );

    // CMAC
    generate
        for (genvar g_cmac = 0; g_cmac < NUM_CMAC; g_cmac++) begin : g__cmac
            // -- Rx
            cmac_axis_fwd_t shell_to_core_cmac_rx;
            cmac_axis_rev_t core_to_shell_cmac_rx;

            assign shell_to_core_cmac_rx = __shell_to_core.cmac_rx[g_cmac];
            assign __core_to_shell.cmac_rx[g_cmac] = core_to_shell_cmac_rx;

            axi4s_intf_from_signals #(
                .DATA_BYTE_WID ( CMAC_DATA_BYTE_WID ),
                .TID_WID       ( CMAC_AXIS_TID_WID ),
                .TDEST_WID     ( CMAC_AXIS_TDEST_WID ),
                .TUSER_WID     ( CMAC_AXIS_TUSER_WID )
            ) i_axi4s_intf_to_signals (
                .tvalid   ( shell_to_core_cmac_rx.tvalid ),
                .tready   ( core_to_shell_cmac_rx.tready ),
                .tdata    ( shell_to_core_cmac_rx.tdata ),
                .tkeep    ( shell_to_core_cmac_rx.tkeep ),
                .tlast    ( shell_to_core_cmac_rx.tlast ),
                .tid      ( shell_to_core_cmac_rx.tid ),
                .tdest    ( shell_to_core_cmac_rx.tdest ),
                .tuser    ( shell_to_core_cmac_rx.tuser ),
                .axi4s_if ( axis_cmac_rx[g_cmac] )
            );
            // -- Tx
            cmac_axis_rev_t shell_to_core_cmac_tx;
            cmac_axis_fwd_t core_to_shell_cmac_tx;

            assign __shell_to_core.cmac_tx[g_cmac] = shell_to_core_cmac_tx;
            assign core_to_shell_cmac_tx = __core_to_shell.cmac_tx[g_cmac];

            axi4s_intf_to_signals #(
                .DATA_BYTE_WID ( CMAC_DATA_BYTE_WID ),
                .TID_WID       ( CMAC_AXIS_TID_WID ),
                .TDEST_WID     ( CMAC_AXIS_TDEST_WID ),
                .TUSER_WID     ( CMAC_AXIS_TUSER_WID )
            ) i_axi4s_intf_from_signals (
                .tvalid   ( core_to_shell_cmac_tx.tvalid ),
                .tready   ( shell_to_core_cmac_tx.tready ),
                .tdata    ( core_to_shell_cmac_tx.tdata ),
                .tkeep    ( core_to_shell_cmac_tx.tkeep ),
                .tlast    ( core_to_shell_cmac_tx.tlast ),
                .tid      ( core_to_shell_cmac_tx.tid ),
                .tdest    ( core_to_shell_cmac_tx.tdest ),
                .tuser    ( core_to_shell_cmac_tx.tuser ),
                .axi4s_if ( axis_cmac_tx[g_cmac] )
            );
        end
    endgenerate

    // H2C
    dma_st_axis_fwd_t shell_to_core_h2c;
    dma_st_axis_rev_t core_to_shell_h2c;

    assign shell_to_core_h2c = __shell_to_core.h2c;
    assign __core_to_shell.h2c = core_to_shell_h2c;

    axi4s_intf_from_signals #(
        .DATA_BYTE_WID ( DMA_ST_DATA_BYTE_WID ),
        .TID_WID       ( DMA_ST_AXIS_TID_WID ),
        .TDEST_WID     ( DMA_ST_AXIS_TDEST_WID ),
        .TUSER_WID     ( DMA_ST_AXIS_TUSER_WID )
    ) i_axi4s_intf_from_signals__h2c (
         .tvalid   ( shell_to_core_h2c.tvalid ),
         .tready   ( core_to_shell_h2c.tready ),
         .tdata    ( shell_to_core_h2c.tdata ),
         .tkeep    ( shell_to_core_h2c.tkeep ),
         .tlast    ( shell_to_core_h2c.tlast ),
         .tid      ( shell_to_core_h2c.tid ),
         .tdest    ( shell_to_core_h2c.tdest ),
         .tuser    ( shell_to_core_h2c.tuser ),
         .axi4s_if ( axis_h2c )
    );

    // C2H
    dma_st_axis_rev_t shell_to_core_c2h;
    dma_st_axis_fwd_t core_to_shell_c2h;

    assign __shell_to_core.c2h = shell_to_core_c2h;
    assign core_to_shell_c2h = __core_to_shell.c2h;

    axi4s_intf_to_signals #(
        .DATA_BYTE_WID ( DMA_ST_DATA_BYTE_WID ),
        .TID_WID       ( DMA_ST_AXIS_TID_WID ),
        .TDEST_WID     ( DMA_ST_AXIS_TDEST_WID ),
        .TUSER_WID     ( DMA_ST_AXIS_TUSER_WID )
    ) i_axi4s_intf_to_signals__c2h (
         .tvalid   ( core_to_shell_c2h.tvalid ),
         .tready   ( shell_to_core_c2h.tready ),
         .tdata    ( core_to_shell_c2h.tdata ),
         .tkeep    ( core_to_shell_c2h.tkeep ),
         .tlast    ( core_to_shell_c2h.tlast ),
         .tid      ( core_to_shell_c2h.tid ),
         .tdest    ( core_to_shell_c2h.tdest ),
         .tuser    ( core_to_shell_c2h.tuser ),
         .axi4s_if ( axis_c2h )
    );

endmodule : shell_adapter__core
