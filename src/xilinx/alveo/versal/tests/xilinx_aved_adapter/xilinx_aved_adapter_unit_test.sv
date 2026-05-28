`include "svunit_defines.svh"

module xilinx_aved_adapter_unit_test;
    import svunit_pkg::svunit_testcase;
    import axi4l_pkg::*;

    string name = "xilinx_aved_adapter_ut";
    svunit_testcase svunit_ut;

    `define SVUNIT_TIMEOUT 1ms

    // =========================================================================
    // Register offsets (core.stub.regio/core.yaml)
    // =========================================================================
    localparam bit [31:0] ADDR_ID         = 32'h0;
    localparam bit [31:0] ADDR_SCRATCHPAD = 32'h4;
    localparam bit [31:0] ID_EXPECTED     = 32'h434F5245;  // 'CORE'

    // =========================================================================
    // Interfaces
    //
    //   axil_if     — testbench drives flat M_AXI_USR_MGMT signals into adapter
    //   axil_app_if — adapter output (controller) wired to shell adapter input
    // =========================================================================
    axi4l_intf axil_if     ();
    axi4l_intf axil_app_if ();
    shell_intf shell_if    ();

    // =========================================================================
    // DUT chain:
    //   axil_if (flat signals) -> xilinx_aved_adapter -> axil_app_if
    //   -> xilinx_aved_shell_adapter -> shell_if -> core (with core_reg_blk)
    // =========================================================================
    xilinx_aved_adapter DUT_adapter (
        .clk_pl                   ( axil_if.aclk   ),
        .resetn_pl_periph         ( axil_if.aresetn ),
        .m_axi_usr_mgmt_awaddr    ( axil_if.awaddr  ),
        .m_axi_usr_mgmt_awprot    ( axil_if.awprot  ),
        .m_axi_usr_mgmt_awvalid   ( axil_if.awvalid ),
        .m_axi_usr_mgmt_awready   ( axil_if.awready ),
        .m_axi_usr_mgmt_wdata     ( axil_if.wdata   ),
        .m_axi_usr_mgmt_wstrb     ( axil_if.wstrb   ),
        .m_axi_usr_mgmt_wvalid    ( axil_if.wvalid  ),
        .m_axi_usr_mgmt_wready    ( axil_if.wready  ),
        .m_axi_usr_mgmt_bresp     ( axil_if.bresp   ),
        .m_axi_usr_mgmt_bvalid    ( axil_if.bvalid  ),
        .m_axi_usr_mgmt_bready    ( axil_if.bready  ),
        .m_axi_usr_mgmt_araddr    ( axil_if.araddr  ),
        .m_axi_usr_mgmt_arprot    ( axil_if.arprot  ),
        .m_axi_usr_mgmt_arvalid   ( axil_if.arvalid ),
        .m_axi_usr_mgmt_arready   ( axil_if.arready ),
        .m_axi_usr_mgmt_rdata     ( axil_if.rdata   ),
        .m_axi_usr_mgmt_rresp     ( axil_if.rresp   ),
        .m_axi_usr_mgmt_rvalid    ( axil_if.rvalid  ),
        .m_axi_usr_mgmt_rready    ( axil_if.rready  ),
        .axil_if                  ( axil_app_if     )
    );

    xilinx_aved_shell_adapter DUT_shell_adapter (
        .axil_if  ( axil_app_if ),
        .shell_if
    );

    core DUT_core (
        .shell_if
    );

    // =========================================================================
    // Clock  (100 MHz)
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
        repeat (8) @(posedge axil_if.aclk);
        axil_if.aresetn = 1'b1;
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

    `SVUNIT_TESTS_END

endmodule
