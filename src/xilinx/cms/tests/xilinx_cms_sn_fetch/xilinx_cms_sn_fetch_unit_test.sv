`include "svunit_defines.svh"
//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 10ms

module xilinx_cms_sn_fetch_unit_test;
    import svunit_pkg::svunit_testcase;
    import axi4l_verif_pkg::*;

    string name = "xilinx_cms_sn_fetch_ut";
    svunit_testcase svunit_ut;

    //===================================
    // DUT
    //===================================
    logic cms_clk;
    logic cms_srst;
    axi4l_intf axil_from_controller ();
    axi4l_intf axil_to_cms ();

    logic             card_sn_vld;
    logic [7:0]       card_sn_len;
    logic [0:15][7:0] card_sn;

    logic             error_boot_timeout;
    logic             error_bad_axil_transaction;
    logic             error_card_info_length;
    logic             error_bad_info_parse;

    xilinx_cms_sn_fetch_fsm DUT(.*);

    //===================================
    // Testbench
    //===================================
    logic parse_error_no_key;
    logic parse_error_no_terminator;
    logic mb_timer_done;
    int mb_timer;
    int mb_boot_time;

    cms_reg_intf cms_reg_if ();

    cms_reg_blk cms_reg_blk_0 (
        .axil_if    ( axil_to_cms ),
        .reg_blk_if ( cms_reg_if )
    );

    assign cms_reg_if.host_status2_reg_nxt_v = 1'b1;
    assign cms_reg_if.host_status2_reg_nxt[0] = cms_reg_if.mb_resetn_reg[0];

    initial begin
        cms_reg_if.reg_map_id_reg_nxt = 32'h0;
        cms_reg_if.host_status2_reg_nxt[0] = 0;
    end
    always_ff @(posedge cms_clk) begin
        if (cms_srst) begin
            cms_reg_if.reg_map_id_reg_nxt = 32'h0;
            cms_reg_if.host_status2_reg_nxt[0] <= 0;
        end
        else if (cms_reg_if.mb_resetn_reg[0] && mb_timer_done) begin
            cms_reg_if.reg_map_id_reg_nxt = 32'h74736574;
            cms_reg_if.host_status2_reg_nxt[0] <= 1'b1;
        end else begin
            cms_reg_if.reg_map_id_reg_nxt = 32'h0;
            cms_reg_if.host_status2_reg_nxt[0] = 0;
        end
    end

    initial mb_timer = 0;
    always @(posedge cms_clk) begin
        if (cms_srst) mb_timer <= 0;
        else if (cms_reg_if.mb_resetn_reg[0]) mb_timer <= mb_timer + 1;
        else mb_timer <= 0;
    end

    assign mb_timer_done = (mb_timer >= mb_boot_time);

    assign cms_reg_if.host_msg_offset_reg_nxt_v = 1'b1;
    assign cms_reg_if.host_msg_offset_reg_nxt = 32'h1000;

    assign cms_reg_if.reg_map_id_reg_nxt_v = 1'b1;

    // Mailbox request is self-clearing
    always @(posedge cms_clk) begin
        if (cms_reg_if.control_reg.mailbox_msg_status) force cms_reg_blk_0.control_reg_reg._reg = '0;
        else release cms_reg_blk_0.control_reg_reg._reg;
    end

    assign cms_reg_if.mailbox_nxt_v[0] = 1'b1;
    always @(posedge cms_clk) begin
        if (axil_to_cms.awaddr == cms_reg_pkg::OFFSET_MAILBOX[0] && axil_to_cms.wvalid && axil_to_cms.wready) begin
            cms_reg_if.mailbox_nxt[0] <= axil_to_cms.wdata;
        end else if (cms_reg_if.control_reg.mailbox_msg_status && cms_reg_if.mailbox[0][31:24] == 8'h04) begin
            cms_reg_if.mailbox_nxt[0] <= cms_reg_if.mailbox[0] | 8'h3b;
        end
    end

    for (genvar g_reg = 1; g_reg < 16; g_reg++) begin : g__reg
        assign cms_reg_if.mailbox_nxt_v[g_reg] = 1'b1;
    end : g__reg
    assign cms_reg_if.mailbox_nxt[1]  = {8'h4c,8'h41,8'h0d,8'h27};
    assign cms_reg_if.mailbox_nxt[2]  = {8'h20,8'h4f,8'h45,8'h56};
    assign cms_reg_if.mailbox_nxt[3]  = {8'h20,8'h30,8'h35,8'h55};
    assign cms_reg_if.mailbox_nxt[4]  = {8'h26,8'h00,8'h51,8'h50};
    assign cms_reg_if.mailbox_nxt[5]  = parse_error_no_key ? {8'h20,8'h00,8'h31,8'h02} : {8'h21,8'h00,8'h31,8'h02};
    assign cms_reg_if.mailbox_nxt[6]  = {8'h31,8'h30,8'h35,8'h0d};
    assign cms_reg_if.mailbox_nxt[7]  = {8'h31,8'h31,8'h31,8'h32};
    assign cms_reg_if.mailbox_nxt[8]  = {8'h50,8'h53,8'h43,8'h39};
    assign cms_reg_if.mailbox_nxt[9]  = parse_error_no_terminator ? {8'h08,8'h4b,8'h01,8'h4d} : {8'h08,8'h4b,8'h00,8'h4d};
    assign cms_reg_if.mailbox_nxt[10] = {8'h0a,8'h00,8'h00,8'h04};
    assign cms_reg_if.mailbox_nxt[11] = {8'hd8,8'h0f,8'h05,8'h35};
    assign cms_reg_if.mailbox_nxt[12] = {8'h2b,8'h50,8'h01,8'h2a};
    assign cms_reg_if.mailbox_nxt[13] = {8'h01,8'h29,8'h07,8'h01};
    assign cms_reg_if.mailbox_nxt[14] = {8'h35,8'h04,8'h28,8'h00};
    assign cms_reg_if.mailbox_nxt[15] = {8'h00,8'h00,8'h30,8'h2e};

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

        parse_error_no_key = 1'b0;
        parse_error_no_terminator = 1'b0;
        mb_boot_time = 100;

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

        `SVTEST(boot_timeout)
            mb_boot_time = 300;
            wait (card_sn_vld || error_boot_timeout || error_bad_axil_transaction || error_card_info_length || error_bad_info_parse);
            `FAIL_UNLESS(error_boot_timeout);
            // Test write/read of regmap from controller
            axil_reg_agent.write_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, 32'h12345678);
            axil_reg_agent.read_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, rd_data);
            `FAIL_UNLESS_EQUAL(rd_data, 32'h12345678);
        `SVTEST_END

        `SVTEST(read_sn)
            wait (card_sn_vld || error_boot_timeout || error_bad_axil_transaction || error_card_info_length || error_bad_info_parse);
            `FAIL_UNLESS(card_sn_vld);
            `FAIL_UNLESS_EQUAL(card_sn_len, 12);
            `FAIL_UNLESS_EQUAL(card_sn, {8'h35, 8'h30, 8'h31, 8'h32, 8'h31, 8'h31, 8'h31, 8'h39, 8'h43, 8'h53, 8'h50, 8'h4d, 8'h00, 8'h00, 8'h00, 8'h00});
            // Test write/read of regmap from controller
            axil_reg_agent.write_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, 32'h12345678);
            axil_reg_agent.read_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, rd_data);
            `FAIL_UNLESS_EQUAL(rd_data, 32'h12345678);
        `SVTEST_END

        `SVTEST(bad_cardinfo__no_key)
            parse_error_no_key = 1'b1;
            wait (card_sn_vld || error_boot_timeout || error_bad_axil_transaction || error_card_info_length || error_bad_info_parse);
            `FAIL_IF(card_sn_vld);
            `FAIL_UNLESS(error_bad_info_parse);
            // Test write/read of regmap from controller
            axil_reg_agent.write_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, 32'h12345678);
            axil_reg_agent.read_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, rd_data);
            `FAIL_UNLESS_EQUAL(rd_data, 32'h12345678);
        `SVTEST_END

        `SVTEST(bad_cardinfo__no_terminator)
            parse_error_no_terminator = 1'b1;
            wait (card_sn_vld || error_boot_timeout || error_bad_axil_transaction || error_card_info_length || error_bad_info_parse);
            `FAIL_IF(card_sn_vld);
            `FAIL_UNLESS(error_bad_info_parse);
            // Test write/read of regmap from controller
            axil_reg_agent.write_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, 32'h12345678);
            axil_reg_agent.read_reg(cms_reg_pkg::OFFSET_MB_RESETN_REG, rd_data);
            `FAIL_UNLESS_EQUAL(rd_data, 32'h012345678);
        `SVTEST_END


    `SVUNIT_TESTS_END

endmodule


