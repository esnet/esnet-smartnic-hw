// Application core (stub version)
// (used for OOC simulation of shell)
module core #() (
    // Shell interface
    shell_intf.core shell_if
);

    // =========================================================================
    // Parameters
    // =========================================================================
    localparam int NUM_CMAC = shell_if.NUM_CMAC;
    localparam int NUM_DMA_ST = shell_if.NUM_DMA_ST;

    // =========================================================================
    // Logic
    // =========================================================================
    // Terminate control interface
    axi4l_intf_peripheral_term i_axi4l_intf_peripheral_term__core (.axi4l_if (shell_if.axil_if));

    // Terminate datapath interfaces
    generate
        for (genvar g_cmac = 0; g_cmac < NUM_CMAC; g_cmac++) begin : g__cmac
            axi4s_intf_tx_term i_axi4s_intf_tx_term__cmac_tx (
                .aclk     (shell_if.clk),
                .aresetn  (!shell_if.srst),
                .axi4s_if (shell_if.axis_cmac_tx[g_cmac])
            );
            axi4s_intf_rx_sink i_axi4s_intf_rx_sink__cmac_rx (
                .axi4s_if (shell_if.axis_cmac_rx[g_cmac])
            );
        end : g__cmac
        for (genvar g_dma_st = 0; g_dma_st < NUM_DMA_ST; g_dma_st++) begin : g__dma_st
            axi4s_intf_tx_term i_axi4s_intf_tx_term__c2h (
                .aclk     (shell_if.clk),
                .aresetn  (!shell_if.srst),
                .axi4s_if (shell_if.axis_c2h[g_dma_st])
            );
            axi4s_intf_rx_sink i_axi4s_intf_rx_sink__h2c (
                .axi4s_if (shell_if.axis_h2c[g_dma_st])
            );

        end : g__dma_st
    endgenerate

endmodule : core
