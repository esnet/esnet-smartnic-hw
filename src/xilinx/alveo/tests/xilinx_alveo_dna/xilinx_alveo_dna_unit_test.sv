`include "svunit_defines.svh"

module xilinx_alveo_dna_unit_test;
    import svunit_pkg::svunit_testcase;

    string name = "xilinx_alveo_dna_ut";
    svunit_testcase svunit_ut;
    
    //===================================
    // Parameters
    //===================================
    parameter bit [95:0] SIM_VALUE = 96'hBBAA_9988_7766_5544_3322_1100;

    //===================================
    // DUT
    //===================================
    // Signals
    logic clk;
    logic srst;
    logic valid;
    logic [95:0] dna;

    xilinx_alveo_dna #(
        .SIM_VALUE ( SIM_VALUE )
    ) DUT (.*);

    //===================================
    // Testbench
    //===================================
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
        srst = 1'b1;
        repeat (8) @(posedge clk);
        srst = 1'b0;
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

        `SVTEST(check)
            wait(valid);
            `FAIL_UNLESS_EQUAL(dna, SIM_VALUE);           
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
