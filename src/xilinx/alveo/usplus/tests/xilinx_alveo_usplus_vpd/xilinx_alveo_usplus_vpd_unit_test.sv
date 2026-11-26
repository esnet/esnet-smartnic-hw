`include "svunit_defines.svh"
`define SVUNIT_TIMEOUT 5ms
module xilinx_alveo_usplus_vpd_unit_test;
    import svunit_pkg::svunit_testcase;
    import xilinx_pci_verif_pkg::*;
    import pci_vpd_verif_pkg::*;
    string name = "xilinx_alveo_usplus_vpd_ut";
    svunit_testcase svunit_ut;
    logic clk, cfg_clk;
    logic srst = 1;
    logic cfg_aresetn = 0;
    logic init_done_mask;
    logic ready;
    logic [31:0] status;
    logic error_no_sn_key, error_no_sn_terminator;
    int mb_boot_time;
    `SVUNIT_CLK_GEN(clk, 10ns);
    `SVUNIT_CLK_GEN(cfg_clk, 2ns);
    xilinx_pci_cfg_ext_intf cfg_ext_if (.clk(cfg_clk));
    axi4l_intf cms_axil_host ();
    axi4l_intf cms_axil_from_controller ();
    axi4l_intf cms_axil_to_peripheral ();
    assign cms_axil_host.aclk = cfg_clk;
    assign cms_axil_host.aresetn = cfg_aresetn;
    axi4l_intf_cdc i_cms_cdc (
        .axi4l_if_from_controller(cms_axil_host), .clk_to_peripheral(clk),
        .axi4l_if_to_peripheral(cms_axil_from_controller)
    );
    xilinx_alveo_usplus_vpd #(.APPLICATION_ID("test_shell")) DUT (.*);
    xilinx_cms_model i_cms_model (
        .cms_clk(clk), .cms_srst(!cms_axil_to_peripheral.aresetn),
        .axil_if(cms_axil_to_peripheral),
        .error_no_sn_key, .error_no_sn_terminator, .mb_boot_time
    );
    xilinx_pci_cfg_ext_intf_agent cfg_agent;
    xilinx_pci_cfg_ext_vpd_agent vpd_agents[2];
    axi4l_verif_pkg::axi4l_reg_agent #() cms_agent;

    function void build();
        svunit_ut = new(name);
        cfg_agent = new();
        cfg_agent.pci_cfg_ext_vif = cfg_ext_if;
        cms_agent = new("cms_agent", 1000, 1000);
        cms_agent.axil_vif = cms_axil_host;
        foreach (vpd_agents[i]) begin
            vpd_agents[i] = new($sformatf("pf%0d", i), i);
            vpd_agents[i].pci_cfg_ext_agent = cfg_agent;
        end
    endfunction
    task setup();
        svunit_ut.setup();
        cfg_aresetn = 0;
        srst = 1;
        init_done_mask = 0;
        error_no_sn_key = 0;
        error_no_sn_terminator = 0;
        mb_boot_time = 50;
        cfg_agent.idle();
        cms_agent.idle();
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
    task check_vpd(input int pf, input bit expect_sn);
        vpd_t image;
        vpd_r_t records;
        byte sn[];
        vpd_agents[pf].read();
        `FAIL_UNLESS(vpd_agents[pf].is_valid());
        image = vpd_agents[pf].get_vpd();
        records = vpd_parse_vpd_r(image);
        `FAIL_UNLESS(records.valid && records.checksum_ok);
        sn = vpd_r_get_record_value(records, "SN");
        if (expect_sn) begin
            `FAIL_UNLESS_EQUAL(sn.size(), 13);
        end else begin
            `FAIL_UNLESS_EQUAL(sn.size(), 0);
        end
    endtask

    `SVUNIT_TESTS_BEGIN
        `SVTEST(initialization_while_pcie_reset_is_asserted)
            wait(ready);
            `FAIL_UNLESS(status[0]);
            `FAIL_IF(status[1] || cfg_aresetn);
            release_host();
            check_vpd(0, 1);
            check_vpd(1, 1);
        `SVTEST_END

        `SVTEST(identity_survives_pcie_reset)
            wait(ready);
            release_host();
            check_vpd(0, 1);
            @(negedge cfg_clk);
            cfg_aresetn = 0;
            repeat (64) @(negedge clk);
            `FAIL_UNLESS(ready && status[0] && status[17]);
            `FAIL_IF(status[1]);
            release_host();
            check_vpd(1, 1);
        `SVTEST_END

        `SVTEST(fetch_failure_exports_static_vpd)
            mb_boot_time = 10000;
            wait(ready);
            `FAIL_UNLESS(status[1] && status[28]);
            `FAIL_IF(status[0] || status[29]);
            release_host();
            check_vpd(0, 0);
            check_vpd(1, 0);
        `SVTEST_END

        `SVTEST(host_access_after_fetch)
            logic [31:0] value;
            wait(ready);
            release_host();
            cms_agent.write_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, 1);
            cms_agent.read_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, value);
            `FAIL_UNLESS_EQUAL(value, 1);
            cms_agent.write_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, 0);
            cms_agent.read_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, value);
            `FAIL_UNLESS_EQUAL(value, 0);
            `FAIL_UNLESS(ready && status[0]);
        `SVTEST_END

        `SVTEST(diagnostic_mask_exports_static_vpd)
            wait(ready);
            release_host();
            init_done_mask = 1;
            repeat (4) @(negedge clk);
            `FAIL_IF(ready || status[0] || status[1]);
            check_vpd(0, 0);
            init_done_mask = 0;
            repeat (4) @(negedge clk);
            `FAIL_UNLESS(ready && status[0]);
            check_vpd(0, 1);
        `SVTEST_END
    `SVUNIT_TESTS_END
endmodule
