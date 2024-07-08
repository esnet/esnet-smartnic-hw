// Application core (stub version)
// (used for OOC simulation of shell)
module core #() (
    // Shell interface
    shell_intf.core shell_if
);
    // =========================================================================
    // Logic
    // =========================================================================
    // Terminate control interface
    axi4l_intf_peripheral_term i_axi4l_intf_peripheral_term__core (.axi4l_if (shell_if.axil_if));

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

endmodule : core
