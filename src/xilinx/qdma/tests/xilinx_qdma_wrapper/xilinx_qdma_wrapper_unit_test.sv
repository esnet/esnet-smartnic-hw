`include "svunit_defines.svh"

module xilinx_qdma_wrapper_unit_test;
    import svunit_pkg::svunit_testcase;
    import xilinx_qdma_pkg::*;

    string name = "xilinx_qdma_wrapper_ut";
    svunit_testcase svunit_ut;

    localparam int PCIE_LINK_WID = 16;

    //===================================
    // DUT
    //===================================
    // Signals
    logic board_rstn;
    logic pcie_rstn;
    logic pcie_refclk_p;
    logic pcie_refclk_n;
    logic [PCIE_LINK_WID-1:0] pcie_rxp;
    logic [PCIE_LINK_WID-1:0] pcie_rxn;
    logic [PCIE_LINK_WID-1:0] pcie_txp;
    logic [PCIE_LINK_WID-1:0] pcie_txn;

    // Interfaces
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TUSER_T(axis_h2c_tuser_t)) axis_h2c ();
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TUSER_T(axis_c2h_tuser_t)) axis_c2h ();
    axi4l_intf #() axil_if ();

    xilinx_qdma_wrapper #(
        .PCIE_LINK_WID   ( PCIE_LINK_WID )
    ) DUT (.*);

    //===================================
    // Testbench
    //===================================
    `SVUNIT_CLK_GEN(pcie_refclk_p, 5ns);

    assign pcie_refclk_n = ~pcie_refclk_p;

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
        board_rstn = 1'b0;
        pcie_rstn = 1'b0;
        
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
        pcie_rxp = '0;
        pcie_rxn = '1;
        axis_h2c.tready = 1'b1;
        axis_c2h.tvalid = 1'b0;
    endtask
        

endmodule
