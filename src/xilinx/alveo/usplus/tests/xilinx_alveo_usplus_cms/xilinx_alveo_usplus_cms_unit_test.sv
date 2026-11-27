`include "svunit_defines.svh"

module xilinx_alveo_usplus_cms_unit_test;
    import svunit_pkg::svunit_testcase;
    import axi4l_pkg::*;
    string name = "xilinx_alveo_usplus_cms_ut";
    svunit_testcase svunit_ut;
    `define SVUNIT_TIMEOUT 500us

    localparam int MB_RESETN = 'h20000;
    localparam int MUTEX = 'h21000;
    localparam int SCRATCH = 'h29ff0;

    logic host_clk = 0;
    logic cms_clk = 0;
    logic reset_n = 0;
    logic satellite_uart_txd, irq;
    logic [1:0] qsfp_resetl, qsfp_lpmode, qsfp_modsell;
    always #4ns host_clk = ~host_clk;
    always #10ns cms_clk = ~cms_clk;

    axi4l_intf axil_host ();
    axi4l_intf axil_cms ();
    assign axil_host.aclk = host_clk;
    assign axil_host.aresetn = reset_n;
    axi4l_intf_cdc i_cdc (
        .axi4l_if_from_controller(axil_host),
        .clk_to_peripheral(cms_clk),
        .axi4l_if_to_peripheral(axil_cms)
    );
    xilinx_alveo_usplus_cms DUT (
        .axil_if(axil_cms),
        .satellite_uart_rxd(1'b1), .satellite_uart_txd,
        .satellite_gpio(4'b0),
        .hbm_temp_1(7'b0), .hbm_temp_2(7'b0), .hbm_cattrip(1'b0),
        .qsfp_modprsl(2'b11), .qsfp_intl(2'b11),
        .qsfp_resetl, .qsfp_lpmode, .qsfp_modsell, .irq
    );

    axi4l_verif_pkg::axi4l_reg_agent #() reg_agent;

    function void build();
        svunit_ut = new(name);
        reg_agent = new("reg_agent", 1024, 1024);
        reg_agent.axil_vif = axil_host;
        reg_agent.set_random_aw_w_alignment(1);
    endfunction
    task reset_dut();
        reset_n = 0;
        repeat (32) @(posedge cms_clk);
        @(negedge host_clk) reset_n = 1;
        repeat (32) @(posedge cms_clk);
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
        `FAIL_IF_LOG(timeout, "CMS read timed out")
        `FAIL_IF_LOG(error, msg)
    endtask
    task automatic reg_write(input int addr, input bit [31:0] data);
        bit error;
        string msg;
        bit timeout;
        reg_agent.lock();
        reg_agent._write(addr, data, error, timeout, msg);
        reg_agent.unlock();
        `FAIL_IF_LOG(timeout, "CMS write timed out")
        `FAIL_IF_LOG(error, msg)
    endtask

    `SVUNIT_TESTS_BEGIN
        `SVTEST(reset_defaults)
            bit [31:0] data;
            reg_read(MB_RESETN, data);
            `FAIL_UNLESS_EQUAL(data, 32'h0)
            `FAIL_UNLESS(satellite_uart_txd === 1'b1)
            `FAIL_UNLESS(irq === 1'b0)
            `FAIL_UNLESS_EQUAL(qsfp_resetl, 2'b11)
            `FAIL_UNLESS_EQUAL(qsfp_lpmode, 2'b00)
`ifdef XILINX_USPLUS_CMS_QSFP_IO
            `FAIL_UNLESS_EQUAL(qsfp_modsell, 2'b00)
`else
            `FAIL_UNLESS_EQUAL(qsfp_modsell, 2'b11)
`endif
        `SVTEST_END
        `SVTEST(host_register_access)
            bit [31:0] data;
            reg_write(MUTEX, 32'h1);
            reg_read(MUTEX, data);
            `FAIL_UNLESS_EQUAL(data, 32'h1)
            reg_write(MUTEX, 32'h0);
            reg_read(MUTEX, data);
            `FAIL_UNLESS_EQUAL(data, 32'h0)
        `SVTEST_END
        `SVTEST(firmware_image_present)
            bit [31:0] data;
            bit [31:0] image_bits = 0;
            for (int offset = 0; offset < 'h40; offset += 4) begin
                reg_read(offset, data);
                image_bits |= data;
            end
            `FAIL_UNLESS(image_bits != 0)
        `SVTEST_END
        `SVTEST(shared_memory_access)
            bit [31:0] data;
            reg_write(SCRATCH, 32'h1234_abcd);
            reg_read(SCRATCH, data);
            `FAIL_UNLESS_EQUAL(data, 32'h1234_abcd)
            reg_write(SCRATCH + 4, 32'h5aa5_6699);
            reg_read(SCRATCH + 4, data);
            `FAIL_UNLESS_EQUAL(data, 32'h5aa5_6699)
        `SVTEST_END
        `SVTEST(reset_stops_processor_and_clears_host_control)
            bit [31:0] data;
            reg_write(MB_RESETN, 32'h1);
            reg_read(MB_RESETN, data);
            `FAIL_UNLESS_EQUAL(data, 32'h1)
            reg_write(MUTEX, 32'h1);
            reset_dut();
            reg_read(MB_RESETN, data);
            `FAIL_UNLESS_EQUAL(data, 32'h0)
            reg_read(MUTEX, data);
            `FAIL_UNLESS_EQUAL(data, 32'h0)
        `SVTEST_END
    `SVUNIT_TESTS_END
endmodule : xilinx_alveo_usplus_cms_unit_test
