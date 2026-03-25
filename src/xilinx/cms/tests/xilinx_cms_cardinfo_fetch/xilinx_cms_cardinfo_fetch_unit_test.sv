`include "svunit_defines.svh"
//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 10ms

module xilinx_cms_cardinfo_fetch_unit_test;
    import svunit_pkg::svunit_testcase;
    import axi4l_verif_pkg::*;

    string name = "xilinx_cms_cardinfo_fetch_ut";
    svunit_testcase svunit_ut;

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

    logic             error_boot_timeout;
    logic             error_bad_axil_transaction;
    logic             error_card_info_length;

    xilinx_cms_cardinfo_fetch_fsm DUT(.*);

    //===================================
    // Testbench
    //===================================
    logic error_no_sn_key;
    logic error_no_sn_terminator;
    int mb_boot_time;

    xilinx_cms_model i_xilinx_cms_model (
        .axil_if (axil_to_cms),
        .*
    );

    clocking cb @(posedge cms_clk);
        output card_info_rd, card_info_rd_addr;
        input  card_info_vld, card_info_len, card_info_rd_vld, card_info_rd_data;
    endclocking

    std_reset_intf reset_if (.clk(cms_clk));

    // Connect reset interface
    assign axil_from_controller.aclk = cms_clk;
    assign axil_from_controller.aresetn = !reset_if.reset;
    assign cms_srst = reset_if.reset;
    assign reset_if.ready = !reset_if.reset;

    // Agents
    axi4l_reg_agent #() axil_reg_agent;

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

    endfunction


    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();
        /* Place Setup Code Here */
        reset();

        error_no_sn_key = 1'b0;
        error_no_sn_terminator = 1'b0;
        mb_boot_time = 100;

        card_info_rd = 1'b0;

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
    byte cardinfo [];
    byte sn [];
    bit no_key;
    bit parse_error;

    `SVUNIT_TESTS_BEGIN

        `SVTEST(hard_reset)
        `SVTEST_END

        `SVTEST(boot_timeout)
            mb_boot_time = 300;
            wait (card_info_vld || error_boot_timeout || error_bad_axil_transaction || error_card_info_length);
            `FAIL_UNLESS(error_boot_timeout);
            // Test write/read of regmap from controller
            axil_reg_agent.write_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, 32'h12345678);
            axil_reg_agent.read_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, rd_data);
            `FAIL_UNLESS_EQUAL(rd_data, 32'h12345678);
        `SVTEST_END

        `SVTEST(cardinfo_fetch)
            wait (card_info_vld || error_boot_timeout || error_bad_axil_transaction || error_card_info_length);
            `FAIL_UNLESS(card_info_vld);
            `FAIL_UNLESS_EQUAL(card_info_len, 'h3b);
            // Test write/read of regmap from controller
            axil_reg_agent.write_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, 32'h12345678);
            axil_reg_agent.read_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, rd_data);
            `FAIL_UNLESS_EQUAL(rd_data, 32'h12345678);
        `SVTEST_END

        `SVTEST(cardinfo_sn_ok)
            localparam byte EXP_SN [13] = "50121119CSPM\0";
            wait (card_info_vld || error_boot_timeout || error_bad_axil_transaction || error_card_info_length);
            `FAIL_UNLESS(card_info_vld);
            `FAIL_UNLESS_EQUAL(card_info_len, 'h3b);
            read_card_info(cardinfo);
            parse_card_sn(cardinfo, sn, no_key, parse_error);
            `FAIL_IF(no_key);
            `FAIL_IF(parse_error);
            `FAIL_UNLESS_EQUAL(sn.size(),$size(EXP_SN));
            foreach (sn[i]) `FAIL_UNLESS_EQUAL(sn[i], EXP_SN[i]);
            // Test write/read of regmap from controller
            axil_reg_agent.write_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, 32'h12345678);
            axil_reg_agent.read_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, rd_data);
            `FAIL_UNLESS_EQUAL(rd_data, 32'h12345678);
        `SVTEST_END

        `SVTEST(cardinfo_no_sn_key)
            error_no_sn_key = 1'b1;
            wait (card_info_vld || error_boot_timeout || error_bad_axil_transaction || error_card_info_length);
            `FAIL_UNLESS(card_info_vld);
            `FAIL_UNLESS_EQUAL(card_info_len, 'h3b);
            read_card_info(cardinfo);
            parse_card_sn(cardinfo, sn, no_key, parse_error);
            `FAIL_UNLESS(no_key);
            `FAIL_IF(parse_error);
            // Test write/read of regmap from controller
            axil_reg_agent.write_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, 32'h12345678);
            axil_reg_agent.read_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, rd_data);
            `FAIL_UNLESS_EQUAL(rd_data, 32'h12345678);
        `SVTEST_END

        `SVTEST(cardinfo_sn_bad)
            localparam byte EXP_SN [13] = "50121119CSPM\0";
            bit compare_ok;
            error_no_sn_terminator = 1'b1;
            wait (card_info_vld || error_boot_timeout || error_bad_axil_transaction || error_card_info_length);
            `FAIL_UNLESS(card_info_vld);
            `FAIL_UNLESS_EQUAL(card_info_len, 'h3b);
            read_card_info(cardinfo);
            parse_card_sn(cardinfo, sn, no_key, parse_error);
            `FAIL_IF(no_key);
            `FAIL_IF(parse_error);
            `FAIL_UNLESS_EQUAL(sn.size(),$size(EXP_SN));
            compare_ok = 1'b1;
            foreach (sn[i]) if (sn[i] != EXP_SN[i]) compare_ok = 0;
            `FAIL_IF(compare_ok);
            // Test write/read of regmap from controller
            axil_reg_agent.write_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, 32'h12345678);
            axil_reg_agent.read_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, rd_data);
            `FAIL_UNLESS_EQUAL(rd_data, 32'h012345678);
        `SVTEST_END


    `SVUNIT_TESTS_END

    task read_byte(input int idx, output byte data);
        cb.card_info_rd <= 1'b1;
        cb.card_info_rd_addr <= idx;
        @(cb);
        cb.card_info_rd <= 1'b0;
        wait (cb.card_info_rd_vld);
        data = cb.card_info_rd_data;
    endtask

    task read_card_info(output byte cardinfo []);
        cardinfo = new[card_info_len];
        foreach (cardinfo[i]) read_byte(i, cardinfo[i]);
    endtask

    function automatic void parse_card_sn(input byte cardinfo [], output byte sn [], output bit not_found, output bit parse_error);
        localparam byte SEARCH_KEY = 8'h21;
        int parse_idx = 0;
        parse_error = 1'b0;
        not_found = 1'b1;
        while (not_found && parse_idx <= cardinfo.size()-1) begin
            byte record_key;
            byte record_len;
            record_key = cardinfo[parse_idx++];
            record_len = cardinfo[parse_idx++];
            if (record_key == SEARCH_KEY) begin
                not_found = 1'b0;
                if (parse_idx + record_len < cardinfo.size()) begin
                    sn = new[record_len];
                    foreach (sn[i]) sn[i] = cardinfo[parse_idx+i];
                    return;
                end else begin
                    parse_error = 1'b1;
                    return;
                end
            end else begin
                if (parse_idx + record_len <= cardinfo.size()) begin
                    parse_idx += record_len;
                    continue;
                end else begin
                    parse_error = 1'b1;
                    return;
                end
            end
        end

    endfunction

endmodule


