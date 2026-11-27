`include "svunit_defines.svh"

module xilinx_qspi_test #(
    parameter bit USE_CDC = 0
);
    import svunit_pkg::svunit_testcase;
    import axi4l_pkg::*;

    string name = USE_CDC ? "xilinx_qspi_cdc_ut" : "xilinx_qspi_ut";
    svunit_testcase svunit_ut;
    `define SVUNIT_TIMEOUT 500us

    localparam int DGIER = 'h1c;
    localparam int IPISR = 'h20;
    localparam int IPIER = 'h28;
    localparam int SRR   = 'h40;
    localparam int SPICR = 'h60;
    localparam int SPISR = 'h64;
    localparam int DTR   = 'h68;
    localparam int SSR   = 'h70;

    logic clk = 1'b0;
    logic reset_n = 1'b0;
    logic irq;
    logic controller_clk = 1'b0;
    logic sys_clk = 1'b0;
    always #10ns clk = ~clk; // 50 MHz reference, 25 MHz SPI SCK.
    always #4ns controller_clk = ~controller_clk; // 125 MHz shell bus.
    always #5ns sys_clk = ~sys_clk; // Free-running 100 MHz system clock.

    axi4l_intf #(.ADDR_WID(12)) axil_if ();
    assign axil_if.aclk = USE_CDC ? controller_clk : clk;
    assign axil_if.aresetn = reset_n;

    if (USE_CDC) begin : g_cdc
        logic qspi_clk;
        axi4l_intf axil_qspi ();
        BUFGCE_DIV #(.BUFGCE_DIVIDE(2)) i_bufgce_div (
            .I(sys_clk), .CE(1'b1), .CLR(1'b0), .O(qspi_clk)
        );
        axi4l_intf_cdc i_axi4l_intf_cdc (
            .axi4l_if_from_controller(axil_if),
            .clk_to_peripheral(qspi_clk),
            .axi4l_if_to_peripheral(axil_qspi)
        );
        xilinx_qspi DUT (.axil_if(axil_qspi), .irq);
    end else begin : g_direct
        xilinx_qspi DUT (.axil_if, .irq);
    end

    axi4l_verif_pkg::axi4l_reg_agent #(.ADDR_WID(12)) reg_agent;

    function void build();
        svunit_ut = new(name);
        reg_agent = new("reg_agent", 256, 256);
        reg_agent.axil_vif = axil_if;
        reg_agent.set_random_aw_w_alignment(1);
    endfunction

    task reset_dut();
        reset_n = 1'b0;
        repeat (16) @(posedge clk);
        @(negedge axil_if.aclk) reset_n = 1'b1;
        repeat (32) @(posedge clk);
    endtask

    task setup();
        svunit_ut.setup();
        reg_agent.idle();
        reset_dut();
    endtask

    task teardown();
        svunit_ut.teardown();
        reg_agent.idle();
    endtask

    task automatic reg_read(input int addr, output bit [31:0] data);
        bit error;
        string msg;
        bit timeout;
        reg_agent.lock();
        reg_agent._read(addr, data, error, timeout, msg);
        reg_agent.unlock();
        `FAIL_IF_LOG(timeout, "QSPI AXI-Lite read timed out")
        `FAIL_IF_LOG(error, msg)
    endtask

    task automatic reg_write(input int addr, input bit [31:0] data);
        bit error;
        string msg;
        bit timeout;
        reg_agent.lock();
        reg_agent._write(addr, data, error, timeout, msg);
        reg_agent.unlock();
        `FAIL_IF_LOG(timeout, "QSPI AXI-Lite write timed out")
        `FAIL_IF_LOG(error, msg)
    endtask

    task check_reset_registers();
        bit [31:0] data;
        reg_read(DGIER, data);
        `FAIL_UNLESS_EQUAL(data, 32'h0)
        reg_read(IPIER, data);
        `FAIL_UNLESS_EQUAL(data, 32'h0)
        reg_read(SPICR, data);
        `FAIL_UNLESS_EQUAL(data, 32'h180)
        reg_read(SPISR, data);
        `FAIL_UNLESS_EQUAL(data & 32'h5, 32'h5) // Both FIFOs empty.
        reg_read(SSR, data);
        `FAIL_UNLESS_EQUAL(data[0], 1'b1)
        `FAIL_UNLESS(irq === 1'b0)
    endtask

    `SVUNIT_TESTS_BEGIN

        `SVTEST(reset_registers)
            check_reset_registers();
        `SVTEST_END

        `SVTEST(register_read_write)
            bit [31:0] data;
            reg_write(DGIER, 32'h8000_0000);
            reg_read(DGIER, data);
            `FAIL_UNLESS_EQUAL(data, 32'h8000_0000)
            reg_write(IPIER, 32'h4);
            reg_read(IPIER, data);
            `FAIL_UNLESS_EQUAL(data, 32'h4)
            reg_write(DGIER, 32'h0);
            reg_read(DGIER, data);
            `FAIL_UNLESS_EQUAL(data, 32'h0)
        `SVTEST_END

        `SVTEST(software_reset_clears_configuration_and_fifo)
            bit [31:0] data;
            reg_write(SPICR, 32'h186); // Enabled master, transfer inhibited.
            reg_write(DGIER, 32'h8000_0000);
            reg_write(DTR, 32'h06);
            reg_write(DTR, 32'h00);
            reg_write(DTR, 32'h00);
            reg_read(SPISR, data);
            `FAIL_UNLESS_EQUAL(data[2], 1'b0)
            reg_write(SRR, 32'ha);
            repeat (32) @(posedge clk);
            check_reset_registers();
        `SVTEST_END

        `SVTEST(hardware_reset_clears_configuration)
            reg_write(DGIER, 32'h8000_0000);
            reg_write(IPIER, 32'h4);
            reg_write(SPICR, 32'h186);
            reset_dut();
            check_reset_registers();
        `SVTEST_END

        `SVTEST(transmit_empty_interrupt)
            bit [31:0] data;
            bit interrupted = 1'b0;
            reg_write(SPICR, 32'h186);
            reg_write(DTR, 32'h06); // Micron write-enable command; no receive data required.
            reg_read(IPISR, data);
            reg_write(IPISR, data); // Clear pending toggle-on-write status bits.
            reg_write(IPIER, 32'h4);
            reg_write(DGIER, 32'h8000_0000);
            reg_write(SSR, 32'h0);
            reg_write(SPICR, 32'h86); // Release transfer inhibit.
            repeat (256) begin
                @(posedge clk);
                if (irq === 1'b1) interrupted = 1'b1;
            end
            `FAIL_UNLESS(interrupted)
            reg_read(IPISR, data);
            `FAIL_UNLESS_EQUAL(data[2], 1'b1)
            `FAIL_UNLESS_EQUAL(data[13], 1'b0) // Command decoded without error.
            reg_read(SPISR, data);
            `FAIL_UNLESS_EQUAL(data[2], 1'b1) // Command left the transmit FIFO.
            reg_write(DGIER, 32'h0);
            repeat (4) @(posedge clk);
            `FAIL_UNLESS(irq === 1'b0)
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule : xilinx_qspi_test

module xilinx_qspi_unit_test;
    xilinx_qspi_test #(.USE_CDC(0)) test_instance ();
    svunit_pkg::svunit_testcase svunit_ut;
    function void build();
        test_instance.build();
        svunit_ut = test_instance.svunit_ut;
    endfunction
    function void __register_tests();
        test_instance.__register_tests();
    endfunction
    task run();
        test_instance.run();
    endtask
endmodule : xilinx_qspi_unit_test

module xilinx_qspi_cdc_unit_test;
    xilinx_qspi_test #(.USE_CDC(1)) test_instance ();
    svunit_pkg::svunit_testcase svunit_ut;
    function void build();
        test_instance.build();
        svunit_ut = test_instance.svunit_ut;
    endfunction
    function void __register_tests();
        test_instance.__register_tests();
    endfunction
    task run();
        test_instance.run();
    endtask
endmodule : xilinx_qspi_cdc_unit_test
