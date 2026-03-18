`include "svunit_defines.svh"
//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 10ms

module xilinx_pci_vpd_unit_test;
    import svunit_pkg::svunit_testcase;
    import axi4l_verif_pkg::*;
    import pci_vpd_verif_pkg::*;

    string name = "xilinx_pci_vpd_ut";
    svunit_testcase svunit_ut;

    //===================================
    // Parameters
    //===================================
    localparam logic[31:0] BUILD_ID         = 92999;
    localparam logic[31:0] FLASH_REG_OFFSET = 32'habcdef01;
    localparam logic[31:0] CMS_REG_OFFSET   = 32'h56782345;

    //===================================
    // DUT
    //===================================
    logic cms_clk;
    logic cms_srst;
    axi4l_intf axil_from_controller ();
    axi4l_intf axil_to_cms ();

    logic             init_done;
    logic             init_error;

    logic             card_info_vld;
    logic [7:0]       card_info_len;
    logic             card_info_rd;
    logic [7:0]       card_info_rd_addr;
    logic [7:0]       card_info_rd_data;
    logic             card_info_rd_vld;

    logic             vpd_req;
    logic             vpd_wr_rd_n;
    logic [14:0]      vpd_addr;
    logic [7:0]       vpd_wr_data;
    logic [7:0]       vpd_rd_data;
    logic             vpd_rd_vld;

    logic             error_boot_timeout;
    logic             error_bad_axil_transaction;
    logic             error_card_info_length;

    xilinx_cms_cardinfo_fetch_fsm DUT0(.*);
    system_config_vpd    #(
        .BUILD_ID         (BUILD_ID),
        .FLASH_REG_OFFSET (FLASH_REG_OFFSET),
        .CMS_REG_OFFSET   (CMS_REG_OFFSET)
    ) DUT1 (
        .clk ( cms_clk ),
        .srst (cms_srst),
        .*
    );

    //===================================
    // Testbench
    //===================================
    logic mb_timer_done;
    int mb_timer;

    xilinx_cms_model i_xilinx_cms_model (
        .cms_clk,
        .cms_srst,
        .axil_if ( axil_to_cms ),
        .*
    );

    std_reset_intf reset_if (.clk(cms_clk));
    pci_vpd_intf vpd_if (.clk(cms_clk));

    assign vpd_req = vpd_if.req;
    assign vpd_wr_rd_n = vpd_if.wr_rd_n;
    assign vpd_addr = vpd_if.addr;
    assign vpd_wr_data = vpd_if.wr_data;
    assign vpd_if.rd_vld = vpd_rd_vld;
    assign vpd_if.rd_data = vpd_rd_data;

    // Connect reset interface
    assign axil_from_controller.aclk = cms_clk;
    assign axil_from_controller.aresetn = !reset_if.reset;
    assign cms_srst = reset_if.reset;
    assign reset_if.ready = !reset_if.reset;

    // Agents
    axi4l_reg_agent #() axil_reg_agent;

    pci_vpd_intf_agent vpd_agent;

    clocking cb @(posedge cms_clk);
        output vpd_req, vpd_wr_rd_n, vpd_addr, vpd_wr_data;
        input  vpd_rd_vld, vpd_rd_data;
    endclocking

    // Assign AXI-L clock (50MHz)
    `SVUNIT_CLK_GEN(cms_clk, 10ns);

    // Reset
    task reset();
        reset_if.pulse(8);
    endtask

    //===================================
    // Build
    //===================================
    function void build();
        svunit_ut = new(name);

        // Build and connect reg agent
        axil_reg_agent = new();
        axil_reg_agent.axil_vif = axil_from_controller;
        axil_reg_agent.set_random_aw_w_alignment(1);

        // Build and connect VPD agent
        vpd_agent = new();
        vpd_agent.vpd_vif = vpd_if;
    endfunction


    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();
        /* Place Setup Code Here */
        vpd_agent.idle();
        reset();
    endtask


    //===================================
    // Here we deconstruct anything we
    // need after running the Unit Tests
    //===================================
    task teardown();
        svunit_ut.teardown();
        /* Place Teardown Code Here */

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
    logic [31:0] rd_data;

    `SVUNIT_TESTS_BEGIN

        `SVTEST(hard_reset)
        `SVTEST_END

        `SVTEST(vpd_init)
            wait (init_done || init_error);
            `FAIL_UNLESS(init_done);
            `FAIL_IF(init_error);
            // Test write/read of regmap from controller
            axil_reg_agent.write_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, 32'h12345678);
            axil_reg_agent.read_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, rd_data);
            `FAIL_UNLESS_EQUAL(rd_data, 32'h12345678);
        `SVTEST_END

        `SVTEST(vpd_read_byte)
            byte rd_byte;
            wait (init_done || init_error);
            `FAIL_UNLESS(init_done);
            `FAIL_IF(init_error);
            vpd_agent.read_byte(0, rd_byte);
            `FAIL_UNLESS_EQUAL(rd_byte, pci_vpd_pkg::vpd_get_lrdt(pci_vpd_pkg::VPD_TAG_ID)); // First resource tag is ID
        `SVTEST_END

        `SVTEST(vpd_read)
            wait (init_done || init_error);
            `FAIL_UNLESS(init_done);
            `FAIL_IF(init_error);
            vpd_agent.read();
            `FAIL_UNLESS(vpd_agent.is_valid());
        `SVTEST_END

        `SVTEST(vpd_r_check)
            vpd_t vpd;
            vpd_r_t vpd_r;
            bit parse_error, checksum_error;
            wait (init_done || init_error);
            `FAIL_UNLESS(init_done);
            `FAIL_IF(init_error);
            vpd_agent.read();
            vpd = vpd_agent.get_vpd();
            `FAIL_UNLESS(vpd_agent.is_valid());
            vpd_r = vpd_parse_vpd_r(vpd);
            `FAIL_UNLESS(vpd_r.valid);
            `FAIL_UNLESS(vpd_r.checksum_ok);
        `SVTEST_END

        `SVTEST(sn_check)
            localparam byte EXP_SN [13] = "50121119CSPM\0";
            bit compare_ok;
            vpd_t vpd;
            vpd_r_t vpd_r;
            byte sn [];
            bit parse_error, checksum_error;
            wait (init_done || init_error);
            `FAIL_UNLESS(init_done);
            `FAIL_IF(init_error);
            vpd_agent.read();
            vpd = vpd_agent.get_vpd();
            `FAIL_UNLESS(vpd_agent.is_valid());
            vpd_r = vpd_parse_vpd_r(vpd);
            `FAIL_UNLESS(vpd_r.valid);
            `FAIL_UNLESS(vpd_r.checksum_ok);
            sn = vpd_r_get_record_value(vpd_r, "SN");
            `FAIL_UNLESS_EQUAL(sn.size(),$size(EXP_SN));
            compare_ok = 1'b1;
            foreach (sn[i]) if (sn[i] != EXP_SN[i]) compare_ok = 0;
            `FAIL_UNLESS(compare_ok);
        `SVTEST_END
    `SVUNIT_TESTS_END

endmodule


