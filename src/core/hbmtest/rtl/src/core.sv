// =========================================================================
// Application core (HBM test core)
// =========================================================================
module core #() (
    // Shell interface
    shell_intf.core shell_if
);
    // =========================================================================
    // Imports
    // =========================================================================
    import xilinx_hbm_pkg::*;

    // =========================================================================
    // Parameters
    // =========================================================================
    localparam int NUM_CMAC = 2;

    // =========================================================================
    // Interfaces
    // =========================================================================
    axi4l_intf axil_app ();

    // Instantiate HBM
    xilinx_hbm_stack #(
        .STACK   ( STACK_LEFT ),
        .DENSITY ( DENSITY_4G )
    ) i_xilinx_hbm_stack (
        .clk         ( shell_if.clk ),
        .rstn        ( !shell_if.srst ),
        .hbm_ref_clk ( shell_if.clk_100mhz ),
        .clk_100mhz  ( shell_if.clk_100mhz ),
        .axil_if     ( axil_app )
        //.axi_if      ( axi_if ) TEMP: disable external AXI-3 interfaces (drive memory accesses from register proxy only)
    );

    // Terminate datapath interfaces
    // -- CMAC0
    axi4s_intf_tx_term i_axi4s_intf_tx_term__cmac0_tx (
        .aclk     (shell_if.clk),
        .aresetn  (!shell_if.srst),
        .axi4s_if (shell_if.axis_cmac0_tx)
    );
    axi4s_intf_rx_sink i_axi4s_intf_rx_sink__cmac0_rx (
        .axi4s_if (shell_if.axis_cmac0_rx)
    );
    // -- CMAC1
    axi4s_intf_tx_term i_axi4s_intf_tx_term__cmac1_tx (
        .aclk     (shell_if.clk),
        .aresetn  (!shell_if.srst),
        .axi4s_if (shell_if.axis_cmac1_tx)
    );
    axi4s_intf_rx_sink i_axi4s_intf_rx_sink__cmac1_rx (
        .axi4s_if (shell_if.axis_cmac1_rx)
    );
    // -- DMA (C2H)
    axi4s_intf_tx_term i_axi4s_intf_tx_term__c2h (
        .aclk     (shell_if.clk),
        .aresetn  (!shell_if.srst),
        .axi4s_if (shell_if.axis_c2h)
    );
    // -- DMA (H2C)
    axi4s_intf_rx_sink i_axi4s_intf_rx_sink__h2c (
        .axi4s_if (shell_if.axis_h2c)
    );

    // =========================================================================
    // SmartNIC decoder shim
    // (replicates address decoding of SmartNIC to maintain FW support)
    // =========================================================================
    axi4l_intf axil_to_regs ();
    axi4l_intf axil_to_regs__clk ();
    axi4l_intf axil_to_endian_check ();
    axi4l_intf axil_to_probe_from_cmac [NUM_CMAC] ();
    axi4l_intf axil_to_ovfl_from_cmac  [NUM_CMAC] ();
    axi4l_intf axil_to_err_from_cmac   [NUM_CMAC] ();
    axi4l_intf axil_to_probe_from_host [NUM_CMAC] ();
    axi4l_intf axil_to_ovfl_from_host  [NUM_CMAC] ();
    axi4l_intf axil_to_probe_to_cmac   [NUM_CMAC] ();
    axi4l_intf axil_to_ovfl_to_cmac    [NUM_CMAC] ();
    axi4l_intf axil_to_probe_to_host   [NUM_CMAC] ();
    axi4l_intf axil_to_ovfl_to_host    [NUM_CMAC] ();
    axi4l_intf axil_to_fifo_to_cmac    [NUM_CMAC] ();
    axi4l_intf axil_to_fifo_from_cmac  [NUM_CMAC] ();
    axi4l_intf axil_to_fifo_to_host    [NUM_CMAC] ();
    axi4l_intf axil_to_fifo_from_host  [NUM_CMAC] ();
    axi4l_intf axil_to_core_to_app     [NUM_CMAC] ();
    axi4l_intf axil_to_app_to_core     [NUM_CMAC] ();
    axi4l_intf axil_to_probe_to_bypass            ();
    axi4l_intf axil_to_drops_from_igr_sw          ();
    axi4l_intf axil_to_drops_from_bypass          ();
    axi4l_intf axil_to_app_decoder                ();
    axi4l_intf axil_to_p4                         ();

    smartnic_reg_intf   smartnic_regs ();

    // SmartNIC decoder
    smartnic_decoder i_smartnic_decoder  (
        .axil_if                         ( shell_if.axil_if ),
        .smartnic_regs_axil_if           ( axil_to_regs ),
        .endian_check_axil_if            ( axil_to_endian_check ),
        .probe_from_cmac_0_axil_if       ( axil_to_probe_from_cmac[0] ),
        .drops_ovfl_from_cmac_0_axil_if  ( axil_to_ovfl_from_cmac[0] ),
        .drops_err_from_cmac_0_axil_if   ( axil_to_err_from_cmac[0] ),
        .probe_from_cmac_1_axil_if       ( axil_to_probe_from_cmac[1] ),
        .drops_ovfl_from_cmac_1_axil_if  ( axil_to_ovfl_from_cmac[1] ),
        .drops_err_from_cmac_1_axil_if   ( axil_to_err_from_cmac[1] ),
        .probe_from_host_0_axil_if       ( axil_to_probe_from_host[0] ),
        .probe_from_host_1_axil_if       ( axil_to_probe_from_host[1] ),
        .probe_core_to_app0_axil_if      ( axil_to_core_to_app[0] ),
        .probe_core_to_app1_axil_if      ( axil_to_core_to_app[1] ),
        .probe_app0_to_core_axil_if      ( axil_to_app_to_core[0] ),
        .probe_app1_to_core_axil_if      ( axil_to_app_to_core[1] ),
        .probe_to_cmac_0_axil_if         ( axil_to_probe_to_cmac[0] ),
        .drops_ovfl_to_cmac_0_axil_if    ( axil_to_ovfl_to_cmac[0] ),
        .probe_to_cmac_1_axil_if         ( axil_to_probe_to_cmac[1] ),
        .drops_ovfl_to_cmac_1_axil_if    ( axil_to_ovfl_to_cmac[1] ),
        .probe_to_host_0_axil_if         ( axil_to_probe_to_host[0] ),
        .drops_ovfl_to_host_0_axil_if    ( axil_to_ovfl_to_host[0] ),
        .probe_to_host_1_axil_if         ( axil_to_probe_to_host[1] ),
        .drops_ovfl_to_host_1_axil_if    ( axil_to_ovfl_to_host[1] ),
        .probe_to_bypass_axil_if         ( axil_to_probe_to_bypass ),
        .drops_from_igr_sw_axil_if       ( axil_to_drops_from_igr_sw ),
        .drops_from_bypass_axil_if       ( axil_to_drops_from_bypass ),
        .fifo_to_host_0_axil_if          ( axil_to_fifo_to_host[0] ),
        .smartnic_to_app_axil_if         ( axil_to_app_decoder )
    );

    // AXI-L interface synchronizer

    axi4l_intf_cdc i_axi4l_intf_cdc__to_regs (
        .axi4l_if_from_controller  ( axil_to_regs ),
        .clk_to_peripheral         ( shell_if.clk ),
        .axi4l_if_to_peripheral    ( axil_to_regs__clk )
    );

    // smartnic register block
    smartnic_reg_blk i_smartnic_reg_blk
    (
        .axil_if    ( axil_to_regs__clk),
        .reg_blk_if ( smartnic_regs )
    );

    // Endian check reg block
    reg_endian_check i_reg_endian_check (
        .axil_if ( axil_to_endian_check )
    );

    // Provide dedicated AXI-L interfaces for app and p4 control
    smartnic_to_app_decoder i_smartnic_to_app_decoder (
        .axil_if              ( axil_to_app_decoder ),
        .smartnic_app_axil_if ( axil_app ),
        .smartnic_p4_axil_if  ( axil_to_p4 )
    );

    // Tie off all unused AXI-L interfaces
    generate
        for (genvar g_cmac = 0; g_cmac < NUM_CMAC; g_cmac++) begin : g__smartnic_cmac
            axi4l_intf_peripheral_term i_axi4l_peripheral_term__probe_from_cmac (.axi4l_if(axil_to_probe_from_cmac [g_cmac]));
            axi4l_intf_peripheral_term i_axi4l_peripheral_term__ovfl_from_cmac  (.axi4l_if(axil_to_ovfl_from_cmac  [g_cmac]));
            axi4l_intf_peripheral_term i_axi4l_peripheral_term__err_from_cmac   (.axi4l_if(axil_to_err_from_cmac   [g_cmac]));
            axi4l_intf_peripheral_term i_axi4l_peripheral_term__probe_from_host (.axi4l_if(axil_to_probe_from_host [g_cmac]));
            axi4l_intf_peripheral_term i_axi4l_peripheral_term__ovfl_from_host  (.axi4l_if(axil_to_ovfl_from_host  [g_cmac]));
            axi4l_intf_peripheral_term i_axi4l_peripheral_term__probe_to_cmac   (.axi4l_if(axil_to_probe_to_cmac   [g_cmac]));
            axi4l_intf_peripheral_term i_axi4l_peripheral_term__ovfl_to_cmac    (.axi4l_if(axil_to_ovfl_to_cmac    [g_cmac]));
            axi4l_intf_peripheral_term i_axi4l_peripheral_term__probe_to_host   (.axi4l_if(axil_to_probe_to_host   [g_cmac]));
            axi4l_intf_peripheral_term i_axi4l_peripheral_term__ovfl_to_host    (.axi4l_if(axil_to_ovfl_to_host    [g_cmac]));
            axi4l_intf_peripheral_term i_axi4l_peripheral_term__fifo_to_cmac    (.axi4l_if(axil_to_fifo_to_cmac    [g_cmac]));
            axi4l_intf_peripheral_term i_axi4l_peripheral_term__fifo_from_cmac  (.axi4l_if(axil_to_fifo_from_cmac  [g_cmac]));
            axi4l_intf_peripheral_term i_axi4l_peripheral_term__fifo_to_host    (.axi4l_if(axil_to_fifo_to_host    [g_cmac]));
            axi4l_intf_peripheral_term i_axi4l_peripheral_term__fifo_from_host  (.axi4l_if(axil_to_fifo_from_host  [g_cmac]));
            axi4l_intf_peripheral_term i_axi4l_peripheral_term__core_to_app     (.axi4l_if(axil_to_core_to_app     [g_cmac]));
            axi4l_intf_peripheral_term i_axi4l_peripheral_term__app_to_core     (.axi4l_if(axil_to_app_to_core     [g_cmac]));
        end : g__smartnic_cmac
    endgenerate
    axi4l_intf_peripheral_term i_axi4l_peripheral_term__probe_to_bypass   (.axi4l_if(axil_to_probe_to_bypass));
    axi4l_intf_peripheral_term i_axi4l_peripheral_term__drops_from_igr_sw (.axi4l_if(axil_to_drops_from_igr_sw));
    axi4l_intf_peripheral_term i_axi4l_peripheral_term__drops_from_bypass (.axi4l_if(axil_to_drops_from_bypass));
    axi4l_intf_peripheral_term i_axi4l_peripheral_term__to_p4             (.axi4l_if(axil_to_p4));

endmodule : core
