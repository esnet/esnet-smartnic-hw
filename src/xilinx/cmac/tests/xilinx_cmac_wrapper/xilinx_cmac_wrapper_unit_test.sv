`include "svunit_defines.svh"

module xilinx_cmac_wrapper_unit_test;
    import svunit_pkg::svunit_testcase;
    import xilinx_cmac_pkg::*;

    string name = "xilinx_cmac_wrapper_ut";
    svunit_testcase svunit_ut;

    localparam int NUM_CMAC = 2;
    localparam int PORT = 0;

    //===================================
    // DUT
    //===================================
    // Signals
    logic clk;
    logic init_clk = 1'b0;
    logic init_clk_enable;
    logic srst;
    logic qsfp_refclk_p;
    logic qsfp_refclk_n;
    logic [3:0] qsfp_rxp;
    logic [3:0] qsfp_rxn;
    logic [3:0] qsfp_txp;
    logic [3:0] qsfp_txn;

    logic cmac_clk;

    // Interfaces
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_WID(AXIS_TID_WID),
                 .TDEST_WID    (AXIS_TDEST_WID),     .TUSER_WID(AXIS_TUSER_WID)
    ) axis_rx (.aclk(cmac_clk));

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_WID(AXIS_TID_WID),
                 .TDEST_WID    (AXIS_TDEST_WID),     .TUSER_WID(AXIS_TUSER_WID)
    ) axis_tx (.aclk(cmac_clk));

    axi4l_intf #() axil_if ();

    xilinx_cmac_wrapper #(
        .PORT_ID (PORT)
    ) DUT (.*);

    //===================================
    // Testbench
    //===================================
    `SVUNIT_CLK_GEN(qsfp_refclk_p, 3.2ns); // 156.25MHz
    `SVUNIT_CLK_GEN(clk, 1.5ns); // 333.33MHz

    always #4ns begin
        if (init_clk_enable) init_clk = ~init_clk;
        else                 init_clk = 1'b0;
    end

    assign axil_if.aclk = init_clk;
    assign axil_if.aresetn = !srst;

    assign qsfp_refclk_n = ~qsfp_refclk_p;

    //===================================
    // Build
    //===================================
    function void build();
        svunit_ut = new(name);
    endfunction


    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();
        init_clk_enable = 1'b1;
        srst = 1'b1;
        // GT reset can hold the CMAC user clock stopped during startup.
        force DUT.gt_txusrclk2 = 1'b0;
        idle();
        repeat (4) @(posedge init_clk);
        #1ps;
    endtask


    //===================================
    // Here we deconstruct anything we
    // need after running the Unit Tests
    //===================================
    task teardown();
        srst = 1'b1;
        init_clk_enable = 1'b1;
        release DUT.gt_txusrclk2;
        svunit_ut.teardown();

    endtask


    //===================================
    // All tests are defined between the
    // SVUNIT_TESTS_BEGIN/END macros
    //
    // Each individual test must be
    // defined between `SVTEST(_NAME_)
    // `SVTEST_END
    //
    // i.e.
    //   `SVTEST(mytest)
    //     <test code>
    //   `SVTEST_END
    //===================================
    `SVUNIT_TESTS_BEGIN

        `SVTEST(reset_releases_without_cmac_clock)
            release_system_reset();
            `FAIL_UNLESS(DUT.sys_reset === 1'b0)
            `FAIL_UNLESS(cmac_clk === 1'b0)
        `SVTEST_END

        `SVTEST(reset_asserts_without_cmac_clock)
            release_system_reset();
            `FAIL_UNLESS(DUT.sys_reset === 1'b0)
            #1ns;
            srst = 1'b1;
            #1ps;
            `FAIL_UNLESS(DUT.sys_reset === 1'b1)
            `FAIL_UNLESS(cmac_clk === 1'b0)
        `SVTEST_END

        `SVTEST(reset_release_waits_for_init_clock)
            @(negedge init_clk);
            init_clk_enable = 1'b0;
            @(negedge clk);
            srst = 1'b0;
            repeat (12) @(posedge clk);
            #1ps;
            `FAIL_UNLESS(DUT.sys_reset === 1'b1)
            init_clk_enable = 1'b1;
            repeat (8) @(posedge init_clk);
            #1ps;
            `FAIL_UNLESS(DUT.sys_reset === 1'b0)
        `SVTEST_END

    `SVUNIT_TESTS_END

    task idle();
        qsfp_rxp = '0;
        qsfp_rxn = '1;
        axis_rx.tready = 1'b1;
        axis_tx.tvalid = 1'b0;
        axis_tx.tdata = '0;
        axis_tx.tkeep = '0;
        axis_tx.tlast = 1'b0;
        axis_tx.tid = '0;
        axis_tx.tdest = '0;
        axis_tx.tuser = '0;
        axil_if.awvalid = 1'b0;
        axil_if.awaddr = '0;
        axil_if.awprot = '0;
        axil_if.wvalid = 1'b0;
        axil_if.wdata = '0;
        axil_if.wstrb = '0;
        axil_if.bready = 1'b1;
        axil_if.arvalid = 1'b0;
        axil_if.araddr = '0;
        axil_if.arprot = '0;
        axil_if.rready = 1'b1;
    endtask

    task release_system_reset();
        @(negedge clk);
        srst = 1'b0;
        repeat (8) @(posedge init_clk);
        #1ps;
    endtask


endmodule
