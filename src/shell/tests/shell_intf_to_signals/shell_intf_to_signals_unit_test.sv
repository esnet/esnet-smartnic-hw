`include "svunit_defines.svh"

module shell_intf_to_signals_unit_test;
    import svunit_pkg::svunit_testcase;
    import shell_pkg::*;

    string name = "shell_intf_to_signals_ut";
    svunit_testcase svunit_ut;
    
    //===================================
    // DUT
    //===================================
    shell_intf shell_if__in ();
    shell_intf shell_if__out ();

    shell_intf_to_signals DUT_to_signals (
        .shell_if (shell_if__in),
        .*
    );

    shell_intf_from_signals DUT_from_signals (
        .shell_if (shell_if__out),
        .*
    );

    `include "../../rtl/include/shell_if__signals__flattened.svh"


    //===================================
    // Testbench
    //===================================
    reg __clk;
    `SVUNIT_CLK_GEN(__clk, 5ns);

    assign clk = __clk;

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
