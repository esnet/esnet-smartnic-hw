`include "svunit_defines.svh"
`define SVUNIT_TIMEOUT 5ms
module xilinx_alveo_usplus_vpd_unit_test;
    import svunit_pkg::svunit_testcase;
    import xilinx_pci_verif_pkg::*;
    import pci_vpd_verif_pkg::*;
    string name = "xilinx_alveo_usplus_vpd_ut";
    svunit_testcase svunit_ut;
    logic clk, cfg_clk;
    logic vpd_clk;
    `SVUNIT_CLK_GEN(vpd_clk, 5ns);
    logic srst = 1;
    logic cfg_aresetn = 0;
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
    logic        init_done;
    logic        init_error;
    logic        init_timeout;
    logic        init_early_read;
    logic [13:0] init_time_ms;

    logic        card_info_vld;
    logic        card_info_rd;
    logic        card_info_rd_vld;
    logic [8:0]  card_info_len;
    logic [8:0]  card_info_rd_addr;
    logic [7:0]  card_info_rd_data;

    logic        error_fetch_timeout;
    logic        error_boot_timeout;
    logic        error_bad_axil_transaction;
    logic        error_card_info_length;

    logic cms_card_info_vld;
    logic [7:0] cms_card_info_len;
    logic cms_card_info_rd;
    logic [7:0] cms_card_info_rd_addr;
    logic [7:0] cms_card_info_rd_data;
    logic cms_card_info_rd_vld;
    xilinx_cms_cardinfo_fetch_fsm #(.FETCH_TIMEOUT_CYCLES(20000)) i_xilinx_cms_cardinfo_fetch_fsm (
        .cms_clk              ( clk ),
        .cms_srst             ( srst ),
        .axil_from_controller ( cms_axil_from_controller ),
        .axil_to_cms          ( cms_axil_to_peripheral ),
        .card_info_vld(cms_card_info_vld),
        .card_info_len(cms_card_info_len),
        .card_info_rd(cms_card_info_rd),
        .card_info_rd_addr(cms_card_info_rd_addr),
        .card_info_rd_data(cms_card_info_rd_data),
        .card_info_rd_vld(cms_card_info_rd_vld),
        .error_fetch_timeout,
        .error_boot_timeout,
        .error_bad_axil_transaction,
        .error_card_info_length
    );

    xilinx_alveo_usplus_card_info #(
        .FLASH_REG_OFFSET(32'h00220000),
        .CMS_REG_OFFSET(32'h00240000)
    ) i_card_info (
        .clk,
        .srst,
        .source_vld(cms_card_info_vld),
        .source_len(cms_card_info_len),
        .source_rd(cms_card_info_rd),
        .source_rd_addr(cms_card_info_rd_addr),
        .source_rd_data(cms_card_info_rd_data),
        .source_rd_vld(cms_card_info_rd_vld),
        .*
    );
    pci_vpd_card_info_intf card_info_if (.clk(clk));
    pci_vpd_card_info_intf card_info_if__vpd (.clk(vpd_clk));
    axi4l_intf axil_vpd ();
    axi4l_verif_pkg::axi4l_reg_agent #() reg_agent;
    assign axil_vpd.aclk = cfg_clk;
    assign axil_vpd.aresetn = cfg_aresetn;
    assign card_info_if.srst = srst;
    assign init_done = DUT.init_done;
    assign init_error = DUT.init_error;
    assign init_timeout = DUT.init_timeout;
    assign init_early_read = DUT.init_early_read;
    assign init_time_ms = DUT.init_time_ms;

    pci_vpd_card_info_intf_cdc i_card_info_cdc (
        .consumer_srst ( srst ),
        .card_info_if_from_provider ( card_info_if ),
        .card_info_if_to_consumer ( card_info_if__vpd )
    );
    assign card_info_if.vld = card_info_vld;
    assign card_info_if.error = error_fetch_timeout || error_boot_timeout || error_bad_axil_transaction || error_card_info_length;
    assign card_info_if.len = card_info_len;
    assign card_info_rd = card_info_if.rd;
    assign card_info_rd_addr = card_info_if.rd_addr;
    assign card_info_if.rd_data = card_info_rd_data;
    assign card_info_if.rd_vld = card_info_rd_vld;

    xilinx_alveo_vpd #(
        .CLK_FREQ_HZ          ( xilinx_alveo_pkg::VPD_CLK_FREQ_HZ ),
        .CARD_INFO_EN         ( xilinx_alveo_usplus_pkg::CARD_INFO_EN ),
        .NUM_PHYS_FUNC        ( xilinx_alveo_usplus_pkg::NUM_PHYS_FUNC ),
        .APPLICATION_ID       ( "test_shell" )
    ) DUT (
        .cfg_aresetn,
        .cfg_ext_if,
        .clk ( vpd_clk ),
        .srst,
        .ready,
        .axil_if ( axil_vpd ),
        .card_info_if ( card_info_if__vpd )
    );

    assign status = {
        2'b0,
        init_timeout,
        error_boot_timeout,
        error_bad_axil_transaction,
        error_card_info_length,
        cms_card_info_len,
        card_info_vld,
        init_time_ms,
        init_early_read,
        init_error,
        init_done
    };

    xilinx_cms_model i_cms_model (
        .cms_clk(clk), .cms_srst(!cms_axil_to_peripheral.aresetn),
        .axil_if(cms_axil_to_peripheral),
        .error_no_sn_key, .error_no_sn_terminator, .mb_boot_time
    );
    xilinx_pci_cfg_ext_intf_agent cfg_agent;
    xilinx_pci_cfg_ext_vpd_agent vpd_agents[xilinx_alveo_usplus_pkg::NUM_PHYS_FUNC];
    axi4l_verif_pkg::axi4l_reg_agent #() cms_agent;

    function void build();
        svunit_ut = new(name);
        reg_agent = new("reg_agent", 1000, 1000);
        reg_agent.axil_vif = axil_vpd;
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
        error_no_sn_key = 0;
        error_no_sn_terminator = 0;
        mb_boot_time = 50;
        cfg_agent.idle();
        reg_agent.idle();
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
    task automatic check_vpd(input int pf, input bit expect_sn);
        vpd_t image;
        vpd_r_t records;
        byte sn[];
        byte flash_offset[];
        byte cms_offset[];
        string flash_text = "Flash offset  : 0x220000";
        string cms_text = "CMS offset    : 0x240000";
        vpd_agents[pf].read();
        `FAIL_UNLESS(vpd_agents[pf].is_valid());
        image = vpd_agents[pf].get_vpd();
        records = vpd_parse_vpd_r(image);
        `FAIL_UNLESS(records.valid && records.checksum_ok);
        sn = vpd_r_get_record_value(records, "SN");
        flash_offset = vpd_r_get_record_value(records, "VF");
        cms_offset = vpd_r_get_record_value(records, "VC");
        if (expect_sn) begin
            `FAIL_UNLESS_EQUAL(flash_offset.size(), flash_text.len() + 1);
            `FAIL_UNLESS_EQUAL(cms_offset.size(), cms_text.len() + 1);
            if (flash_offset.size() == flash_text.len() + 1) begin
                foreach (flash_offset[i]) begin
                    `FAIL_UNLESS_EQUAL(flash_offset[i], i == flash_text.len() ? 0 : flash_text.getc(i));
                end
            end
            if (cms_offset.size() == cms_text.len() + 1) begin
                foreach (cms_offset[i]) begin
                    `FAIL_UNLESS_EQUAL(cms_offset[i], i == cms_text.len() ? 0 : cms_text.getc(i));
                end
            end
            `FAIL_UNLESS_EQUAL(sn.size(), 13);
        end else begin
            `FAIL_UNLESS_EQUAL(flash_offset.size(), 0);
            `FAIL_UNLESS_EQUAL(cms_offset.size(), 0);
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
            reg_agent.write_reg(0, 1);
            repeat (64) @(negedge clk);
            `FAIL_IF(ready || status[0] || status[1]);
            check_vpd(0, 0);
            reg_agent.write_reg(0, 0);
            repeat (64) @(negedge clk);
            `FAIL_UNLESS(ready && status[0]);
            check_vpd(0, 1);
        `SVTEST_END
    `SVUNIT_TESTS_END
endmodule
