`include "svunit_defines.svh"

module xilinx_alveo_versal_shell_unit_test;
    import svunit_pkg::svunit_testcase;
    import axi4l_pkg::*;
    import xilinx_qdma_pkg::*;

    string name = "xilinx_alveo_versal_shell_ut";
    svunit_testcase svunit_ut;

    `define SVUNIT_TIMEOUT 1ms

    // =========================================================================
    // Register offsets
    //
    // The shell splits its management space per shell_decoder_core.yaml into
    // shell_cfg at 0x000000, hw at 0x200000 and core at 0x400000.  These reach
    // core.stub's own registers (core.stub.regio/core.yaml).
    // =========================================================================
    localparam bit [31:0] CORE_BASE       = 32'h400000;
    localparam bit [31:0] ADDR_ID         = CORE_BASE + 32'h0;
    localparam bit [31:0] ADDR_SCRATCHPAD = CORE_BASE + 32'h4;
    localparam bit [31:0] ID_EXPECTED     = 32'h434F5245;  // 'CORE'

    // =========================================================================
    // Interfaces
    //
    //   axil_if  — testbench drives management AXI4-L directly into the shell
    //   shell_if — shell output wired to core.stub
    // =========================================================================
    axi4l_intf axil_if  ();

    // C2H packet length, published by the shell's C2H FIFO for the adapter.
    packet_pkg::size_t pkt_c2h_dma_size;

    // DMA streams. The QDMA adapter is above the shell in the real design,
    // so these are terminated rather than driven.
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( QID_WID            )
    ) pkt_h2c_dma (.clk(axil_if.aclk));

    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( QID_WID            )
    ) pkt_c2h_dma (.clk(axil_if.aclk));

    shell_intf #(
        .DMA_ST_QUEUES ( xilinx_alveo_versal_pkg::DMA_ST_QUEUES )
    ) shell_if ();

    // =========================================================================
    // PCIe reset signals — shell needs these to synthesise pci_rstn.
    // Driven in lockstep with the management reset since no real PCIe link
    // is present in simulation.
    // =========================================================================
    logic pci_rstn_in = 1'b0;
    wire  pci_rstn;

    // =========================================================================
    // DUT: xilinx_alveo_versal_shell
    //   axil_if drives the peripheral management port directly.
    //   core.stub is connected via shell_if.
    // =========================================================================
    xilinx_alveo_versal_shell DUT (
        .sys_clk_100mhz ( axil_if.aclk ),
        .pci_rstn_in ( pci_rstn_in  ),
        .pci_rstn    ( pci_rstn     ),
        .axil_top         ( axil_if          ),
        .dma_aclk         ( axil_if.aclk     ),
        .dma_aresetn      ( axil_if.aresetn  ),
        .pkt_h2c_dma      ( pkt_h2c_dma      ),
        .pkt_c2h_dma      ( pkt_c2h_dma      ),
        .pkt_c2h_dma_size ( pkt_c2h_dma_size ),
        .shell_if
    );

    packet_intf_tx_term i_packet_intf_tx_term__h2c (.to_rx   (pkt_h2c_dma));
    packet_intf_rx_sink i_packet_intf_rx_sink__c2h (.from_tx (pkt_c2h_dma));

    core DUT_core (
        .shell_if
    );

    // =========================================================================
    // Clock (100 MHz)
    // =========================================================================
    `SVUNIT_CLK_GEN(axil_if.aclk, 5ns);

    // =========================================================================
    // Build
    // =========================================================================
    function void build();
        svunit_ut = new(name);
    endfunction

    // =========================================================================
    // Setup / teardown
    // =========================================================================
    task setup();
        svunit_ut.setup();
        axil_if.idle_controller();
        axil_if.aresetn = 1'b0;
        pci_rstn_in     = 1'b0;
        repeat (8) @(posedge axil_if.aclk);
        axil_if.aresetn = 1'b1;
        pci_rstn_in     = 1'b1;
        repeat (4) @(posedge axil_if.aclk);
    endtask

    task teardown();
        svunit_ut.teardown();
    endtask

    // =========================================================================
    // Helpers
    // =========================================================================
    task automatic axil_write(input bit [31:0] addr, input bit [31:0] data);
        axi4l_pkg::resp_t resp;
        bit timeout;
        axil_if.write(addr, data, resp, timeout);
        `FAIL_UNLESS_EQUAL(timeout, 1'b0);
        `FAIL_UNLESS_EQUAL(resp.encoded, axi4l_pkg::RESP_OKAY);
    endtask

    task automatic axil_read(input bit [31:0] addr, output bit [31:0] data);
        axi4l_pkg::resp_t resp;
        bit timeout;
        axil_if.read(addr, data, resp, timeout);
        `FAIL_UNLESS_EQUAL(timeout, 1'b0);
        `FAIL_UNLESS_EQUAL(resp.encoded, axi4l_pkg::RESP_OKAY);
    endtask

    // =========================================================================
    // Tests
    // =========================================================================
    `SVUNIT_TESTS_BEGIN

        // Verify the id register returns the 'CORE' sentinel value.
        `SVTEST(id_read)
            bit [31:0] rdata;
            axil_read(ADDR_ID, rdata);
            `FAIL_UNLESS_EQUAL(rdata, ID_EXPECTED);
        `SVTEST_END

        // Verify the scratchpad register round-trips a written value.
        `SVTEST(scratchpad_write_read)
            bit [31:0] rdata;
            axil_write(ADDR_SCRATCHPAD, 32'hDEAD_BEEF);
            axil_read(ADDR_SCRATCHPAD, rdata);
            `FAIL_UNLESS_EQUAL(rdata, 32'hDEAD_BEEF);
        `SVTEST_END

        // Back-to-back reads through the shell management path.
        `SVTEST(back_to_back_reads)
            bit [31:0] rdata;
            axil_write(ADDR_SCRATCHPAD, 32'hA5A5_A5A5);
            repeat (4) begin
                axil_read(ADDR_ID, rdata);
                `FAIL_UNLESS_EQUAL(rdata, ID_EXPECTED);
                axil_read(ADDR_SCRATCHPAD, rdata);
                `FAIL_UNLESS_EQUAL(rdata, 32'hA5A5_A5A5);
            end
        `SVTEST_END

        // The shell generates core_clk itself now, so confirm the MMCM
        // actually locks and the core domain comes out of reset -- the
        // register tests above run on mgmt_clk and would pass regardless.
        `SVTEST(core_clk_runs)
            int unsigned edges = 0;
            logic prev;
            // Wait for lock (bounded), then count core_clk edges.
            fork
                begin
                    wait (DUT.core_clk_locked === 1'b1);
                end
                begin
                    #50us;
                    `FAIL_IF_LOG(1'b1, "core clock MMCM never locked")
                end
            join_any
            disable fork;
            `FAIL_UNLESS_LOG(DUT.core_clk_locked === 1'b1, "MMCM not locked")

            // core_srst must release once locked and the management reset is up
            repeat (64) @(posedge DUT.core_clk);
            `FAIL_IF_LOG(DUT.core_srst, "core_srst still asserted after lock")

            // and the clock must genuinely be toggling
            prev = DUT.core_clk;
            repeat (20) begin
                #1ns;
                if (DUT.core_clk !== prev) edges++;
                prev = DUT.core_clk;
            end
            `FAIL_UNLESS_LOG(edges > 0, "core_clk is not toggling")
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
