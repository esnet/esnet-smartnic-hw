`include "svunit_defines.svh"

module shell_intf_unit_test;
    import svunit_pkg::svunit_testcase;

    string name = "shell_intf_ut";
    svunit_testcase svunit_ut;
    
    //===================================
    // DUT
    //===================================
    shell_intf DUT ();

    //===================================
    // Testbench
    //===================================
    logic clk;

    `SVUNIT_CLK_GEN(clk, 5ns);

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
        assign DUT.axis_cmac0_rx.tvalid = 1'b1;
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

endmodule
