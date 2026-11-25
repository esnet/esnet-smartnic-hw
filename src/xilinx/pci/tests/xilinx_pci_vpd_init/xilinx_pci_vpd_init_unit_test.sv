`include "svunit_defines.svh"
`define SVUNIT_TIMEOUT 1ms

module xilinx_pci_vpd_init_unit_test;
    import svunit_pkg::svunit_testcase;
    import pci_vpd_verif_pkg::*;

    string name = "xilinx_pci_vpd_init_ut";
    svunit_testcase svunit_ut;
    logic clk;
    logic srst;
    logic card_info_vld;
    logic card_info_error;
    logic [7:0] card_info_len;
    logic stall_reads;
    byte card_info_mem[255];
    logic [1:0] card_info_rd;
    logic [1:0][7:0] card_info_rd_addr;
    logic [1:0][7:0] card_info_rd_data;
    logic [1:0] card_info_rd_vld;
    logic [1:0] init_done, init_error, init_timeout, init_early_read;
    logic [1:0][13:0] init_time_ms;
    pci_vpd_intf vpd_if[2](.clk(clk));
    pci_vpd_intf_agent agents[2];

    `SVUNIT_CLK_GEN(clk, 5ns);

    for (genvar g = 0; g < 2; g++) begin : g__vpd
        xilinx_pci_vpd #(
            .CLK_FREQ_HZ(4000), // Four cycles per reported ms for these tests.
            .CARD_INFO_EN(g == 1),
            .CARD_INFO_TIMEOUT_MS(8),
            .PRODUCT_ID("Native shell"),
            .APPLICATION_ID("SmartNIC"),
            .BUILD_ID(32'h1234abcd),
            .BUILD_GIT_REPO("esnet-smartnic-hw"),
            .BUILD_GIT_HASH("01234567"),
            .BUILD_TIMESTAMP_STR("2026-11-25"),
            .FLASH_REG_OFFSET('h220000),
            .CMS_REG_OFFSET('h240000)
        ) DUT (
            .vpd_if(vpd_if[g]), .srst,
            .init_done(init_done[g]), .init_error(init_error[g]),
            .init_timeout(init_timeout[g]), .init_early_read(init_early_read[g]),
            .init_time_ms(init_time_ms[g]), .init_done_mask(1'b0),
            .card_info_vld, .card_info_error, .card_info_len,
            .card_info_rd(card_info_rd[g]), .card_info_rd_addr(card_info_rd_addr[g]),
            .card_info_rd_data(card_info_rd_data[g]), .card_info_rd_vld(card_info_rd_vld[g])
        );
        always @(posedge clk) begin
            card_info_rd_vld[g] <= !srst && !stall_reads && card_info_rd[g];
            if (card_info_rd[g] && card_info_rd_addr[g] < 255)
                card_info_rd_data[g] <= card_info_mem[card_info_rd_addr[g]];
        end
    end

    function void build();
        svunit_ut = new(name);
        agents[0] = new("static_vpd");
        agents[0].vpd_vif = vpd_if[0];
        agents[1] = new("dynamic_vpd");
        agents[1].vpd_vif = vpd_if[1];
    endfunction

    task reset();
        @(negedge clk);
        srst = 1;
        repeat (4) @(negedge clk);
        srst = 0;
    endtask

    task setup();
        svunit_ut.setup();
        srst = 1;
        card_info_vld = 0;
        card_info_error = 0;
        card_info_len = 0;
        stall_reads = 0;
        foreach (card_info_mem[i]) card_info_mem[i] = 0;
        foreach (agents[i]) agents[i].idle();
        reset();
    endtask

    task teardown();
        svunit_ut.teardown();
    endtask

    task check_value(input byte value[], input string expected);
        `FAIL_UNLESS_EQUAL(value.size(), expected.len()+1);
        if (value.size() == expected.len()+1) begin
            for (int i = 0; i < expected.len(); i++) begin
                `FAIL_UNLESS_EQUAL(value[i], expected.getc(i));
            end
            `FAIL_UNLESS_EQUAL(value[expected.len()], 0);
        end
    endtask

    task check_record(input vpd_r_t records, input string key, input string expected);
        byte value[];
        value = vpd_r_get_record_value(records, key);
        check_value(value, expected);
    endtask

    task check_static(input int idx);
        vpd_t image;
        vpd_r_t records;
        vpd_resource_t product;
        byte sn[];
        agents[idx].read();
        `FAIL_UNLESS(agents[idx].is_valid());
        image = agents[idx].get_vpd();
        product = vpd_get_resource(image, pci_vpd_pkg::VPD_TAG_ID);
        check_value(product.value, "Native shell");
        records = vpd_parse_vpd_r(image);
        `FAIL_UNLESS(records.valid);
        `FAIL_UNLESS(records.checksum_ok);
        sn = vpd_r_get_record_value(records, "SN");
        `FAIL_UNLESS_EQUAL(sn.size(), 0);
        check_record(records, "VA", "Application   : SmartNIC");
        check_record(records, "VB", "Build ID      : 305441741");
        check_record(records, "VR", "Build git repo: esnet-smartnic-hw");
        check_record(records, "VH", "Build git hash: 01234567");
        check_record(records, "VT", "Build time    : 2026-11-25");
        check_record(records, "VF", "Flash offset  : 0x220000");
        check_record(records, "VC", "CMS offset    : 0x240000");
    endtask

    `SVUNIT_TESTS_BEGIN
        `SVTEST(static_only)
            wait(init_done[0]);
            card_info_error = 1;
            card_info_vld = 1;
            `FAIL_IF(init_error[0] || init_timeout[0] || card_info_rd[0]);
            check_static(0);
            `FAIL_UNLESS(init_done[0]);
            `FAIL_IF(init_error[0] || init_timeout[0]);
        `SVTEST_END

        `SVTEST(clock_timing_and_timeout)
            repeat (3) @(negedge clk);
            `FAIL_UNLESS_EQUAL(init_time_ms[1], 0);
            @(negedge clk);
            `FAIL_UNLESS_EQUAL(init_time_ms[1], 1);
            wait(init_error[1]);
            `FAIL_UNLESS(init_timeout[1]);
            `FAIL_IF(init_done[1]);
            `FAIL_UNLESS_EQUAL(init_time_ms[1], 8);
            check_static(1);
        `SVTEST_END

        `SVTEST(provider_error)
            @(negedge clk);
            card_info_error = 1;
            wait(init_error[1]);
            `FAIL_IF(init_done[1] || init_timeout[1]);
            card_info_error = 0;
            card_info_vld = 1;
            check_static(1);
            `FAIL_UNLESS(init_error[1]);
            `FAIL_IF(init_done[1] || init_timeout[1] || card_info_rd[1]);
        `SVTEST_END

        `SVTEST(stalled_provider)
            stall_reads = 1;
            card_info_vld = 1;
            card_info_len = 8;
            wait(card_info_rd[1]);
            wait(init_error[1]);
            `FAIL_UNLESS(init_timeout[1]);
            check_static(1);
        `SVTEST_END

        `SVTEST(malformed_card_info)
            // A key and length claim bytes beyond the end of the buffer.
            card_info_mem[0] = 'h21;
            card_info_mem[1] = 8;
            card_info_len = 2;
            card_info_vld = 1;
            wait(init_error[1]);
            `FAIL_IF(init_timeout[1] || init_done[1]);
            check_static(1);
        `SVTEST_END

        `SVTEST(oversized_card_record)
            // This record fits its input buffer but exceeds VPD storage capacity.
            card_info_mem[0] = 'h27;
            card_info_mem[1] = 126;
            card_info_len = 128;
            card_info_vld = 1;
            wait(init_error[1]);
            `FAIL_IF(init_timeout[1] || init_done[1]);
            check_static(1);
        `SVTEST_END

        `SVTEST(early_read_and_reset_recovery)
            byte first_byte;
            agents[1].read_byte(0, first_byte);
            `FAIL_UNLESS_EQUAL(first_byte, 'h82);
            `FAIL_UNLESS(init_early_read[1]);
            wait(init_error[1]);
            `FAIL_UNLESS(init_timeout[1]);
            reset();
            `FAIL_IF(init_done[1] || init_error[1] || init_timeout[1] || init_early_read[1]);
            card_info_error = 1;
            wait(init_error[1]);
            `FAIL_IF(init_timeout[1]);
            check_static(1);
        `SVTEST_END

        `SVTEST(read_only_and_out_of_range)
            byte before_write, after_write;
            wait(init_done[0]);
            agents[0].read_byte(0, before_write);
            agents[0].write_byte(0, 0);
            agents[0].read_byte(0, after_write);
            `FAIL_UNLESS_EQUAL(after_write, before_write);
            agents[0].read_byte('h7fff, after_write);
            `FAIL_UNLESS_EQUAL(after_write, 8'hff);
            check_static(0);
        `SVTEST_END
    `SVUNIT_TESTS_END
endmodule
