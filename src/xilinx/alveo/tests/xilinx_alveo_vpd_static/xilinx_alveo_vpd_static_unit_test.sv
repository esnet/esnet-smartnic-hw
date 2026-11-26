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
    assign ready = init_done || init_error;

    `SVUNIT_CLK_GEN(clk, 5ns);
    `SVUNIT_CLK_GEN(cfg_clk, 2ns);

    xilinx_pci_cfg_ext_intf cfg_ext_if (.clk(cfg_clk));
    xilinx_pci_cfg_ext_intf_agent cfg_agent;
    xilinx_pci_cfg_ext_vpd_agent vpd_agents[NUM_FUNCS];

    pci_vpd_ctrl_intf vpd_ctrl_if ();
    pci_vpd_card_info_intf card_info_if (.clk(clk));
    assign vpd_ctrl_if.clk = clk;
    assign vpd_ctrl_if.srst = srst;
    assign vpd_ctrl_if.init_done_mask = 1'b0;
    assign init_done = vpd_ctrl_if.init_done;
    assign init_error = vpd_ctrl_if.init_error;
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
        .vpd_ctrl_if,
        .card_info_if
    );

    function void build();
        svunit_ut = new(name);
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
        `SVTEST(initialization_while_pcie_reset_is_asserted)
            wait(ready);
            `FAIL_UNLESS(vpd_ctrl_if.init_done);
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
