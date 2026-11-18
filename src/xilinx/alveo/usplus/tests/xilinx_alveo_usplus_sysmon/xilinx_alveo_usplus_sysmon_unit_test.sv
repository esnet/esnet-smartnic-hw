`include "svunit_defines.svh"

module xilinx_alveo_usplus_sysmon_unit_test;
    import svunit_pkg::svunit_testcase;
    import axi4l_pkg::*;
    import axi4l_verif_pkg::*;

    string name = "xilinx_alveo_usplus_sysmon_ut";
    svunit_testcase svunit_ut;
    `define SVUNIT_TIMEOUT 2ms

    localparam int BASE = 'h10000;
    localparam int BAD_ADDRS [3] = '{'h12000, 'h12508, 'h13ffc};
    logic host_clk = 0;
    logic sysmon_clk = 0;
    logic reset_n = 0;
    axi4l_reg_agent #() reg_agent;
    resp_t read_response, write_response;
    int sysmon_reads = 0;
    int sysmon_writes = 0;
    always #4ns host_clk = ~host_clk;
    always #5ns sysmon_clk = ~sysmon_clk;

    axi4l_intf axil_host ();
    axi4l_intf axil_sysmon ();
    axi4l_intf axil_sysmon__100mhz ();
    axi4l_intf axil_unused [6] ();
    assign axil_host.aclk = host_clk;
    assign axil_host.aresetn = reset_n;

    xilinx_alveo_usplus_decoder i_decoder (
        .axil_if(axil_host),
        .syscfg_axil_if(axil_unused[0]), .qdma_axil_if(axil_unused[1]),
        .cmac0_axil_if(axil_unused[2]), .cmac1_axil_if(axil_unused[3]),
        .sysmon_axil_if(axil_sysmon),
        .qspi_axil_if(axil_unused[4]), .cms_axil_if(axil_unused[5])
    );
    for (genvar i = 0; i < 6; i++) begin : g_term
        axi4l_intf_peripheral_term i_term (.axi4l_if(axil_unused[i]));
    end
    axi4l_intf_cdc i_cdc (
        .axi4l_if_from_controller(axil_sysmon),
        .clk_to_peripheral(sysmon_clk),
        .axi4l_if_to_peripheral(axil_sysmon__100mhz)
    );
    xilinx_sysmon_wrapper DUT (.axil_if(axil_sysmon__100mhz));

    always @(posedge host_clk) begin
        if (axil_host.rvalid && axil_host.rready) read_response = axil_host.rresp;
        if (axil_host.bvalid && axil_host.bready) write_response = axil_host.bresp;
    end

    always @(posedge sysmon_clk) begin
        if (axil_sysmon__100mhz.aresetn) begin
            if (axil_sysmon__100mhz.arvalid && axil_sysmon__100mhz.arready) sysmon_reads++;
            if (axil_sysmon__100mhz.awvalid && axil_sysmon__100mhz.awready) sysmon_writes++;
        end
    end

    function void build();
        svunit_ut = new(name);
        reg_agent = new("sysmon_reg_agent", 1024, 1024);
        reg_agent.axil_vif = axil_host;
        reg_agent.set_random_aw_w_alignment(1);
    endfunction
    task reset_bus();
        @(negedge host_clk) reset_n = 0;
        repeat (32) @(posedge sysmon_clk);
        @(negedge host_clk) reset_n = 1;
        repeat (32) @(posedge sysmon_clk);
    endtask
    task setup();
        svunit_ut.setup();
        reg_agent.idle();
        reset_bus();
    endtask
    task teardown();
        svunit_ut.teardown();
        reg_agent.idle();
    endtask
    task automatic reg_read(input int address, output bit [31:0] value,
                            input resp_encoding_t expected = RESP_OKAY);
        bit error;
        string msg;
        if (expected == RESP_OKAY) reg_agent.read_reg(address, value);
        else begin
            reg_agent.read_bad_addr(address, error, msg);
            `FAIL_IF_LOG(error, msg)
            value = '0;
        end
        `FAIL_IF_LOG(read_response.raw != expected,
                     $sformatf("Read address %h: response %h, expected %h", address, read_response.raw, expected))
    endtask
    task automatic reg_write(input int address, input bit [31:0] value,
                             input resp_encoding_t expected = RESP_OKAY);
        bit error;
        string msg;
        if (expected == RESP_OKAY) reg_agent.write_reg(address, value);
        else begin
            reg_agent.write_bad_addr(address, error, msg);
            `FAIL_IF_LOG(error, msg)
        end
        `FAIL_IF_LOG(write_response.raw != expected,
                     $sformatf("Write address %h: response %h, expected %h", address, write_response.raw, expected))
    endtask

    `SVUNIT_TESTS_BEGIN
        `SVTEST(clock_and_adc_divider)
            bit [31:0] value;
            realtime first_edge;
            @(posedge axil_sysmon__100mhz.aclk) first_edge = $realtime;
            @(posedge axil_sysmon__100mhz.aclk);
            `FAIL_UNLESS(($realtime - first_edge) == 10ns)
            `FAIL_UNLESS(axil_sysmon__100mhz.aresetn === 1'b1)
            for (int bank = 0; bank < 3; bank++) begin
                reg_read(BASE + bank * 'h800 + 'h508, value);
                `FAIL_UNLESS_EQUAL(value[15:8], 8'd20) // 100 MHz / 20 = 5 MHz ADC clock.
            end
        `SVTEST_END
        `SVTEST(register_banks_are_independent)
            bit [31:0] value, original [3];
            for (int bank = 0; bank < 3; bank++) begin
                reg_read(BASE + bank * 'h800 + 'h540, original[bank]);
                reg_write(BASE + bank * 'h800 + 'h540, 'h6000 + bank * 'h100);
            end
            for (int bank = 0; bank < 3; bank++) begin
                reg_read(BASE + bank * 'h800 + 'h540, value);
                `FAIL_UNLESS_EQUAL(value[15:0], 16'h6000 + bank * 'h100)
                reg_write(BASE + bank * 'h800 + 'h540, original[bank]);
            end
        `SVTEST_END
        `SVTEST(unmapped_reads_do_not_reach_sysmon)
            bit [31:0] value;
            int before_reads;
            before_reads = sysmon_reads;
            foreach (BAD_ADDRS[i]) reg_read(BAD_ADDRS[i], value, RESP_DECERR);
            `FAIL_UNLESS_EQUAL(sysmon_reads, before_reads)
        `SVTEST_END
        `SVTEST(unmapped_writes_do_not_reach_sysmon)
            bit [31:0] value;
            int before_writes;
            before_writes = sysmon_writes;
            foreach (BAD_ADDRS[i]) reg_write(BAD_ADDRS[i], 'h1f00, RESP_DECERR);
            `FAIL_UNLESS_EQUAL(sysmon_writes, before_writes)
            reg_read(BASE + 'h508, value);
            `FAIL_UNLESS_EQUAL(value[15:8], 8'd20)
        `SVTEST_END
        `SVTEST(reset_crosses_into_sysmon_domain)
            bit [31:0] value;
            reg_write(BASE + 'h5c, 'h8000_0000);
            reg_read(BASE + 'h5c, value);
            `FAIL_UNLESS_EQUAL(value, 32'h8000_0000)
            reset_bus();
            reg_read(BASE + 'h5c, value);
            `FAIL_UNLESS_EQUAL(value, 32'h0)
        `SVTEST_END
        `SVTEST(selected_sensor_conversions)
            bit [31:0] value;
            real degrees, volts;
            #1ms;
            for (int bank = 0; bank < 3; bank++) begin
                reg_read(BASE + bank * 'h800 + 'h400, value);
                degrees = real'(value[15:0]) * 509.3140064 / 65536.0 - 280.23087870;
                `FAIL_UNLESS(degrees > 65.0 && degrees < 69.0)
                if (bank == 0) reg_read(BASE + 'h404, value);
                else reg_read(BASE + bank * 'h800 + 'h600, value);
                volts = real'(value[15:0]) * 3.0 / 65536.0;
                if (bank == 0) `FAIL_UNLESS(volts > 0.89 && volts < 0.93)
                else `FAIL_UNLESS(volts > 0.92 && volts < 0.96)
            end
        `SVTEST_END
    `SVUNIT_TESTS_END
endmodule : xilinx_alveo_usplus_sysmon_unit_test
