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
        srst = 1'b1;
        
        idle();

    endtask


    //===================================
    // Here we deconstruct anything we
    // need after running the Unit Tests
    //===================================
    task teardown();
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

        `SVTEST(compile)
        `SVTEST_END

    `SVUNIT_TESTS_END

    task idle();
        qsfp_rxp = '0;
        qsfp_rxn = '1;
        axis_rx.tready = 1'b1;
        axis_tx.tvalid = 1'b0;
    endtask
        

endmodule
