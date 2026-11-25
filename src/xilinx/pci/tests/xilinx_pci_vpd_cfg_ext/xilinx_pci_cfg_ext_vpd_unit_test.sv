`include "svunit_defines.svh"
//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 10ms

module xilinx_pci_cfg_ext_vpd_unit_test;
    import svunit_pkg::svunit_testcase;
    import axi4l_verif_pkg::*;
    import pci_vpd_verif_pkg::*;
    import xilinx_pci_verif_pkg::*;

    string name = "xilinx_pci_cfg_ext_vpd_ut";
    svunit_testcase svunit_ut;

    //===================================
    // Parameters
    //===================================
    localparam int NUM_FUNCS = 2;
    localparam logic[31:0] FLASH_REG_OFFSET = 32'habcdef01;
    localparam logic[31:0] CMS_REG_OFFSET   = 32'h56782345;
    localparam logic[31:0] BUILD_ID         = 32'h11223344;

    //===================================
    // DUT
    //===================================
    logic cms_clk;
    logic cms_srst;
    axi4l_intf axil_from_controller ();
    axi4l_intf axil_to_cms ();

    logic             aclk;
    logic             aresetn;

    logic             init_done;
    logic             init_error;
    logic             init_early_read;
    logic [13:0]      init_time_ms;
    logic             init_done_mask;

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

    xilinx_pci_cfg_ext_intf pci_cfg_ext_if (.clk(aclk));
    pci_vpd_intf vpd_if (.clk(cms_clk));

    xilinx_cms_cardinfo_fetch_fsm DUT0(.*);
    system_config_vpd    #(
        .BUILD_ID         (BUILD_ID),
        .FLASH_REG_OFFSET (FLASH_REG_OFFSET),
        .CMS_REG_OFFSET   (CMS_REG_OFFSET)
    ) DUT1 (
        .clk  ( cms_clk ),
        .srst ( cms_srst),
        .*
    );
`ifdef ONS_VPD
    qdma_pci_cfg_ext_vpd #(
        .NUM_PHYS_FUNC(NUM_FUNCS)
    ) DUT2 (
        .aclk, .aresetn,
        .cfg_ext_read_received(pci_cfg_ext_if.req && !pci_cfg_ext_if.wr_rd_n),
        .cfg_ext_write_received(pci_cfg_ext_if.req && pci_cfg_ext_if.wr_rd_n),
        .cfg_ext_register_number(pci_cfg_ext_if.register),
        .cfg_ext_function_number(pci_cfg_ext_if.func),
        .cfg_ext_write_data(pci_cfg_ext_if.wr_data),
        .cfg_ext_write_byte_enable(pci_cfg_ext_if.wr_byte_en),
        .cfg_ext_read_data(pci_cfg_ext_if.rd_data),
        .cfg_ext_read_data_valid(pci_cfg_ext_if.rd_vld),
        .vpd_clk(cms_clk), .vpd_srst(cms_srst),
        .vpd_req(vpd_if.req), .vpd_wr_rd_n(vpd_if.wr_rd_n),
        .vpd_addr(vpd_if.addr), .vpd_wr_data(vpd_if.wr_data),
        .vpd_rd_data(vpd_if.rd_data), .vpd_rd_vld(vpd_if.rd_vld)
    );
`else
    xilinx_pci_cfg_ext_vpd #(
        .NUM_PHYS_FUNC ( NUM_FUNCS )
    ) DUT2 (
        .aresetn,
        .cfg_ext_if(pci_cfg_ext_if),
        .vpd_srst(cms_srst),
        .vpd_if
    );

`endif

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
    assign vpd_req = vpd_if.req;
    assign vpd_wr_rd_n = vpd_if.wr_rd_n;
    assign vpd_addr = vpd_if.addr;
    assign vpd_wr_data = vpd_if.wr_data;
    assign vpd_if.rd_data = vpd_rd_data;
    assign vpd_if.rd_vld = vpd_rd_vld;

    // Connect reset interface
    assign axil_from_controller.aclk = cms_clk;
    assign axil_from_controller.aresetn = !reset_if.reset;
    assign cms_srst = reset_if.reset;
    assign aresetn = !reset_if.reset;
    assign reset_if.ready = !reset_if.reset;

    // Agents
    axi4l_reg_agent #() axil_reg_agent;

    xilinx_pci_cfg_ext_intf_agent pci_cfg_ext_agent;
    xilinx_pci_cfg_ext_vpd_agent  vpd_agent [NUM_FUNCS];

    // Assign AXI clock (250MHz)
    `SVUNIT_CLK_GEN(aclk, 2ns);

    // Assign CMS clock (50MHz)
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

        pci_cfg_ext_agent = new();
        pci_cfg_ext_agent.pci_cfg_ext_vif = pci_cfg_ext_if;

        // Build and connect VPD agents
        foreach (vpd_agent[i]) begin
            vpd_agent[i] = new($sformatf("vpd_agent[%0d]", i), i);
            vpd_agent[i].pci_cfg_ext_agent = pci_cfg_ext_agent;
        end
    endfunction


    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();
        /* Place Setup Code Here */
        foreach(vpd_agent[i]) vpd_agent[i].idle();
        reset();

        init_done_mask = 1'b0;
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
    byte written_bytes[$];
    always @(posedge cms_clk) begin
        if (cms_srst) written_bytes.delete();
        else if (vpd_if.req && vpd_if.wr_rd_n) written_bytes.push_back(vpd_if.wr_data);
    end


    `SVUNIT_TESTS_BEGIN

        `SVTEST(hard_reset)
        `SVTEST_END

        `SVTEST(config_range)
            `FAIL_UNLESS(xilinx_pci_pkg::cfg_ext_legacy_access_in_range('h2c, 0));
            `FAIL_UNLESS(xilinx_pci_pkg::cfg_ext_legacy_access_in_range('h2f, 255));
            `FAIL_IF(xilinx_pci_pkg::cfg_ext_legacy_access_in_range('h2b, 0));
            `FAIL_IF(xilinx_pci_pkg::cfg_ext_legacy_access_in_range('h30, 0));
            `FAIL_IF(xilinx_pci_pkg::cfg_ext_legacy_access_in_range('h2c, -1));
            `FAIL_IF(xilinx_pci_pkg::cfg_ext_legacy_access_in_range('h2c, 256));
        `SVTEST_END

        `SVTEST(config_byte_enables_and_function_isolation)
            bit error, timeout;
            pci_cfg_ext_agent.write('h2d, 0, 'h11223344, error, timeout);
            `FAIL_IF(error || timeout);
            pci_cfg_ext_agent.write('h2d, 1, 'haabbccdd, error, timeout);
            `FAIL_IF(error || timeout);
            pci_cfg_ext_agent.write('h2d, 0, 'h55667788, error, timeout, 4'b0101);
            `FAIL_IF(error || timeout);
            pci_cfg_ext_agent.read('h2d, 0, rd_data, error, timeout);
            `FAIL_IF(error || timeout);
            `FAIL_UNLESS_EQUAL(rd_data, 32'h11663388);
            pci_cfg_ext_agent.read('h2d, 1, rd_data, error, timeout);
            `FAIL_IF(error || timeout);
            `FAIL_UNLESS_EQUAL(rd_data, 32'haabbccdd);
            pci_cfg_ext_agent.write('h2d, 255, '1, error, timeout);
            `FAIL_IF(error || timeout);
            pci_cfg_ext_agent.read('h2d, 255, rd_data, error, timeout);
            `FAIL_IF(error || timeout);
            `FAIL_UNLESS_EQUAL(rd_data, 0);
            pci_cfg_ext_agent.read('h2d, 0, rd_data, error, timeout);
            `FAIL_IF(error || timeout);
            `FAIL_UNLESS_EQUAL(rd_data, 32'h11663388);
        `SVTEST_END

        `SVTEST(vpd_write_byte_order)
            bit error, timeout;
            // Exercise all four bytes from PF1 through the request CDC FIFO.
            pci_cfg_ext_agent.write('h2d, 1, 'h12345678, error, timeout);
            `FAIL_IF(error || timeout);
            pci_cfg_ext_agent.write('h2c, 1, 'h80000000, error, timeout);
            `FAIL_IF(error || timeout);
            wait(written_bytes.size() == 4);
            `FAIL_UNLESS_EQUAL(written_bytes[0], 8'h78);
            `FAIL_UNLESS_EQUAL(written_bytes[1], 8'h56);
            `FAIL_UNLESS_EQUAL(written_bytes[2], 8'h34);
            `FAIL_UNLESS_EQUAL(written_bytes[3], 8'h12);
        `SVTEST_END

        `SVTEST(vpd_write_backpressure)
            bit error, timeout;
            pci_cfg_ext_agent.write('h2d, 0, 'h12345678, error, timeout);
            `FAIL_IF(error || timeout);
            repeat (64) begin
                pci_cfg_ext_agent.write('h2c, 0, 'h80000000, error, timeout);
                `FAIL_IF(error || timeout);
                do begin
                    pci_cfg_ext_agent.read('h2c, 0, rd_data, error, timeout);
                    `FAIL_IF(error || timeout);
                end while (rd_data[31]);
            end
            wait(written_bytes.size() == 256);
            foreach(written_bytes[i]) begin
                case (i % 4)
                    0: begin
                        `FAIL_UNLESS_EQUAL(written_bytes[i], 8'h78);
                    end
                    1: begin
                        `FAIL_UNLESS_EQUAL(written_bytes[i], 8'h56);
                    end
                    2: begin
                        `FAIL_UNLESS_EQUAL(written_bytes[i], 8'h34);
                    end
                    3: begin
                        `FAIL_UNLESS_EQUAL(written_bytes[i], 8'h12);
                    end
                endcase
            end
        `SVTEST_END

        `SVTEST(reset_pending_read)
            bit error, timeout;
            byte first_byte;
            pci_cfg_ext_agent.write('h2c, 0, 0, error, timeout);
            `FAIL_IF(error || timeout);
            wait(vpd_if.req && !vpd_if.wr_rd_n);
            reset();
            pci_cfg_ext_agent.read('h2c, 0, rd_data, error, timeout);
            `FAIL_IF(error || timeout);
            `FAIL_UNLESS_EQUAL(rd_data, 32'h00000003);
            vpd_agent[0].read_byte(0, first_byte);
            `FAIL_UNLESS_EQUAL(first_byte, pci_vpd_pkg::vpd_get_lrdt(pci_vpd_pkg::VPD_TAG_ID));
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
            vpd_agent[0].read_byte(0, rd_byte);
            `FAIL_UNLESS_EQUAL(rd_byte, pci_vpd_pkg::vpd_get_lrdt(pci_vpd_pkg::VPD_TAG_ID)); // First resource tag is ID
        `SVTEST_END

        `SVTEST(vpd_read)
            wait (init_done || init_error);
            `FAIL_UNLESS(init_done);
            `FAIL_IF(init_error);
            vpd_agent[0].read();
            `FAIL_UNLESS(vpd_agent[0].is_valid());
        `SVTEST_END

        `SVTEST(vpd_read_multi_thread)
            wait (init_done || init_error);
            `FAIL_UNLESS(init_done);
            `FAIL_IF(init_error);
            foreach (vpd_agent[i]) begin : f__agent
                automatic int idx = i;
                fork
                    begin
                        #(1us*idx); // Stagger start time
                        vpd_agent[idx].read();
                    end
                join_none
            end : f__agent
            #1;
            wait fork;
            foreach (vpd_agent[i]) `FAIL_UNLESS(vpd_agent[i].is_valid());
        `SVTEST_END

        `SVTEST(vpd_r_check)
            vpd_t vpd;
            vpd_r_t vpd_r;
            bit parse_error, checksum_error;
            wait (init_done || init_error);
            `FAIL_UNLESS(init_done);
            `FAIL_IF(init_error);
            vpd_agent[0].read();
            vpd = vpd_agent[0].get_vpd();
            `FAIL_UNLESS(vpd_agent[0].is_valid());
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
            vpd_agent[0].read();
            vpd = vpd_agent[0].get_vpd();
            `FAIL_UNLESS(vpd_agent[0].is_valid());
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


