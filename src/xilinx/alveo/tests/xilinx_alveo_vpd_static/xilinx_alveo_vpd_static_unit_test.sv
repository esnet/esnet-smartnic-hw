`include "svunit_defines.svh"
`define SVUNIT_TIMEOUT 5ms
module xilinx_alveo_vpd_static_unit_test;
    import svunit_pkg::svunit_testcase;
    import xilinx_pci_verif_pkg::*;
    import pci_vpd_verif_pkg::*;

    localparam int NUM_FUNCS = `NUM_FUNCS;

    string name = "xilinx_alveo_vpd_static_ut";
    svunit_testcase svunit_ut;

    logic clk;
    logic cfg_clk;
    logic srst = 1;
    logic cfg_aresetn = 0;
    logic ready;
    logic init_done;
    logic init_error;

    `SVUNIT_CLK_GEN(clk, 5ns);
    `SVUNIT_CLK_GEN(cfg_clk, 2ns);

    xilinx_pci_cfg_ext_intf cfg_ext_if (.clk(cfg_clk));
    xilinx_pci_cfg_ext_intf_agent cfg_agent;
    xilinx_pci_cfg_ext_vpd_agent vpd_agents[NUM_FUNCS];

    axi4l_intf axil_vpd ();
    axi4l_verif_pkg::axi4l_reg_agent #() reg_agent;
    pci_vpd_card_info_intf card_info_if (.clk(clk));
    assign axil_vpd.aclk = cfg_clk;
    assign axil_vpd.aresetn = cfg_aresetn;
    assign init_done = DUT.init_done;
    assign init_error = DUT.init_error;
    assign card_info_if.srst = srst;
    assign card_info_if.vld = 1'b0;
    assign card_info_if.error = 1'b0;
    assign card_info_if.len = '0;
    assign card_info_if.rd_data = '0;
    assign card_info_if.rd_vld = 1'b0;

    xilinx_alveo_vpd #(
        .NUM_PHYS_FUNC        ( NUM_FUNCS ),
        .CLK_FREQ_HZ          ( 100_000_000 ),
        .CARD_INFO_EN         ( 1'b0 ),
        .APPLICATION_ID      ( "test_shell" ),
        .BUILD_ID            ( 123 ),
        .BUILD_GIT_REPO      ( "test_repo" ),
        .BUILD_GIT_HASH      ( "12345678" ),
        .BUILD_TIMESTAMP_STR ( "2026-11-26 00:00:00 UTC" )
    ) DUT (
        .cfg_aresetn,
        .cfg_ext_if,
        .clk,
        .srst,
        .ready,
        .axil_if ( axil_vpd ),
        .card_info_if
    );

    function void build();
        svunit_ut = new(name);
        reg_agent = new("reg_agent", 1000, 1000);
        reg_agent.axil_vif = axil_vpd;
        cfg_agent = new();
        cfg_agent.pci_cfg_ext_vif = cfg_ext_if;
        foreach (vpd_agents[i]) begin
            vpd_agents[i] = new($sformatf("pf%0d", i), i);
            vpd_agents[i].pci_cfg_ext_agent = cfg_agent;
        end
    endfunction

    task setup();
        svunit_ut.setup();
        cfg_aresetn = 0;
        srst = 1;
        cfg_agent.idle();
        reg_agent.idle();
        repeat (8) @(negedge clk);
        srst = 0;
    endtask

    task teardown();
        svunit_ut.teardown();
    endtask

    task release_host();
        @(negedge cfg_clk);
        cfg_aresetn = 1;
        repeat (64) @(negedge clk);
    endtask

    task check_field(input vpd_r_t records, input string key, input string expected);
        byte value[];
        value = vpd_r_get_record_value(records, key);
        `FAIL_UNLESS_EQUAL(value.size(), expected.len() + 1);
        if (value.size() == expected.len() + 1) begin
            for (int i = 0; i < expected.len(); i++) begin
                `FAIL_UNLESS_EQUAL(value[i], expected.getc(i));
            end
            `FAIL_UNLESS_EQUAL(value[expected.len()], 0);
        end
    endtask

    task check_vpd(input int pf);
        vpd_t image;
        vpd_r_t records;
        byte serial_number[];
        byte flash_offset[];
        byte cms_offset[];
        vpd_agents[pf].read();
        `FAIL_UNLESS(vpd_agents[pf].is_valid());
        image = vpd_agents[pf].get_vpd();
        records = vpd_parse_vpd_r(image);
        `FAIL_UNLESS(records.valid && records.checksum_ok);
        check_field(records, "VA", "Application   : test_shell");
        check_field(records, "VB", "Build ID      : 123");
        check_field(records, "VR", "Build git repo: test_repo");
        check_field(records, "VH", "Build git hash: 12345678");
        check_field(records, "VT", "Build time    : 2026-11-26 00:00:00 UTC");
        flash_offset = vpd_r_get_record_value(records, "VF");
        cms_offset = vpd_r_get_record_value(records, "VC");
        `FAIL_UNLESS_EQUAL(flash_offset.size(), 0);
        `FAIL_UNLESS_EQUAL(cms_offset.size(), 0);
        serial_number = vpd_r_get_record_value(records, "SN");
        `FAIL_UNLESS_EQUAL(serial_number.size(), 0);
    endtask

    `SVUNIT_TESTS_BEGIN
        `SVTEST(register_controls_and_host_reset)
            logic [31:0] value;
            wait(ready);
            release_host();
            reg_agent.read_reg(4, value);
            `FAIL_UNLESS(value[0]);
            `FAIL_IF(value[1] || value[17]);
            reg_agent.read_reg(8, value);
            `FAIL_UNLESS_EQUAL(value, 0);
            reg_agent.write_reg(0, 1);
            repeat (64) @(negedge clk);
            `FAIL_IF(ready);
            reg_agent.read_reg(0, value);
            `FAIL_UNLESS_EQUAL(value, 1);
            cfg_aresetn = 0;
            repeat (16) @(negedge clk);
            release_host();
            reg_agent.read_reg(0, value);
            `FAIL_UNLESS_EQUAL(value, 0);
            `FAIL_UNLESS(ready && init_done);
            check_vpd(0);
        `SVTEST_END

        `SVTEST(initialization_while_pcie_reset_is_asserted)
            wait(ready);
            `FAIL_UNLESS(init_done);
            `FAIL_IF(cfg_aresetn);
            release_host();
            foreach (vpd_agents[pf]) check_vpd(pf);
        `SVTEST_END

        `SVTEST(identity_survives_pcie_reset)
            wait(ready);
            release_host();
            check_vpd(0);
            @(negedge cfg_clk);
            cfg_aresetn = 0;
            repeat (16) @(negedge clk);
            `FAIL_UNLESS(ready);
            release_host();
            foreach (vpd_agents[pf]) check_vpd(pf);
        `SVTEST_END

        `SVTEST(pcie_reset_with_stopped_configuration_clock)
            bit remained_initialized;
            wait(ready);
            release_host();
            check_vpd(0);
            @(negedge cfg_clk);
            force cfg_clk = 1'b0;
            cfg_aresetn = 0;
            repeat (32) @(negedge clk);
            remained_initialized = ready && init_done;
            release cfg_clk;
            release_host();
            `FAIL_UNLESS(remained_initialized);
            foreach (vpd_agents[pf]) check_vpd(pf);
        `SVTEST_END

        `SVTEST(pf_control_and_data_are_independent)
            bit [31:0] data;
            bit error;
            bit timeout;
            wait(ready);
            release_host();
            if (NUM_FUNCS > 1) begin
                cfg_agent.write('h2d, NUM_FUNCS-1, 32'habcdef01, error, timeout);
                `FAIL_IF(error || timeout);
            end
            cfg_agent.write('h2d, 0, 32'h12345678, error, timeout);
            `FAIL_IF(error || timeout);
            cfg_agent.write('h2d, NUM_FUNCS, 32'hdeadbeef, error, timeout);
            `FAIL_IF(error || timeout);
            if (NUM_FUNCS > 1) begin
                cfg_agent.read('h2d, NUM_FUNCS-1, data, error, timeout);
                `FAIL_IF(error || timeout);
                `FAIL_UNLESS_EQUAL(data, 32'habcdef01);
            end
            cfg_agent.read('h2d, NUM_FUNCS, data, error, timeout);
            `FAIL_IF(error || timeout);
            `FAIL_UNLESS_EQUAL(data, 0);
            cfg_agent.read('h2d, 0, data, error, timeout);
            `FAIL_IF(error || timeout);
            `FAIL_UNLESS_EQUAL(data, 32'h12345678);
            foreach (vpd_agents[pf]) check_vpd(pf);
        `SVTEST_END
    `SVUNIT_TESTS_END
endmodule : xilinx_alveo_vpd_static_unit_test
