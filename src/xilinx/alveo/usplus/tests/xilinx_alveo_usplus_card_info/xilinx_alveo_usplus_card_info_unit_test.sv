`include "svunit_defines.svh"
`define SVUNIT_TIMEOUT 100us
module xilinx_alveo_usplus_card_info_unit_test;
    import svunit_pkg::svunit_testcase;
    import xilinx_pci_pkg::*;

    string name = "xilinx_alveo_usplus_card_info_ut";
    svunit_testcase svunit_ut;
    logic clk;
    logic srst;
    logic source_vld;
    logic [7:0] source_len;
    logic [1:0] source_rd;
    logic [1:0][7:0] source_rd_addr;
    logic [1:0][7:0] source_rd_data;
    logic [1:0] source_rd_vld;
    logic [1:0] card_info_vld;
    logic [1:0][8:0] card_info_len;
    logic [1:0] card_info_rd;
    logic [1:0][8:0] card_info_rd_addr;
    logic [1:0][7:0] card_info_rd_data;
    logic [1:0] card_info_rd_vld;
    byte source_mem[255];

    `SVUNIT_CLK_GEN(clk, 5ns);

    for (genvar g = 0; g < 2; g++) begin : g__provider
        xilinx_alveo_usplus_card_info #(
            .FLASH_REG_OFFSET ( g == 0 ? 32'h00220000 : 32'h0 ),
            .CMS_REG_OFFSET   ( g == 0 ? 32'h00240000 : 32'hffffffff )
        ) DUT (
            .clk,
            .srst,
            .source_vld,
            .source_len,
            .source_rd         ( source_rd[g] ),
            .source_rd_addr    ( source_rd_addr[g] ),
            .source_rd_data    ( source_rd_data[g] ),
            .source_rd_vld     ( source_rd_vld[g] ),
            .card_info_vld     ( card_info_vld[g] ),
            .card_info_len     ( card_info_len[g] ),
            .card_info_rd      ( card_info_rd[g] ),
            .card_info_rd_addr ( card_info_rd_addr[g] ),
            .card_info_rd_data ( card_info_rd_data[g] ),
            .card_info_rd_vld  ( card_info_rd_vld[g] )
        );
        always_ff @(posedge clk) begin
            source_rd_vld[g] <= !srst && source_rd[g];
            if (source_rd[g]) source_rd_data[g] <= source_mem[source_rd_addr[g]];
        end
    end

    function void build();
        svunit_ut = new(name);
    endfunction

    task setup();
        svunit_ut.setup();
        srst = 1;
        source_vld = 0;
        source_len = 0;
        card_info_rd = 0;
        card_info_rd_addr = 0;
        foreach (source_mem[i]) source_mem[i] = byte'(i ^ 'h5a);
        repeat (4) @(negedge clk);
        srst = 0;
    endtask

    task teardown();
        svunit_ut.teardown();
    endtask

    task read_byte(input int provider, input int addr, output byte value);
        @(negedge clk);
        card_info_rd_addr[provider] = 9'(addr);
        card_info_rd[provider] = 1;
        @(negedge clk);
        card_info_rd[provider] = 0;
        for (int i = 0; i < 8; i++) begin
            if (card_info_rd_vld[provider]) begin
                value = card_info_rd_data[provider];
                return;
            end
            @(negedge clk);
        end
        `FAIL_UNLESS_LOG(0, "Card-info read timed out");
    endtask

    task check_record(input int provider, input byte key, input string expected, inout int addr);
        byte value;
        read_byte(provider, addr++, value);
        `FAIL_UNLESS_EQUAL(value, key);
        read_byte(provider, addr++, value);
        `FAIL_UNLESS_EQUAL(value, expected.len() + 1);
        for (int i = 0; i < expected.len(); i++) begin
            read_byte(provider, addr++, value);
            `FAIL_UNLESS_EQUAL(value, expected.getc(i));
        end
        read_byte(provider, addr++, value);
        `FAIL_UNLESS_EQUAL(value, 0);
    endtask

    `SVUNIT_TESTS_BEGIN
        `SVTEST(offset_records_preserve_text_format)
            int addr = 0;
            source_vld = 1;
            check_record(0, CARD_INFO_KEY__FLASH_REG_OFFSET, "Flash offset  : 0x220000", addr);
            check_record(0, CARD_INFO_KEY__CMS_REG_OFFSET, "CMS offset    : 0x240000", addr);
            `FAIL_UNLESS_EQUAL(card_info_len[0], addr);
            `FAIL_UNLESS(card_info_vld[0]);
        `SVTEST_END

        `SVTEST(zero_and_full_width_offsets)
            int addr = 0;
            check_record(1, CARD_INFO_KEY__FLASH_REG_OFFSET, "Flash offset  : 0x0", addr);
            check_record(1, CARD_INFO_KEY__CMS_REG_OFFSET, "CMS offset    : 0xffffffff", addr);
            `FAIL_UNLESS_EQUAL(card_info_len[1], addr);
            `FAIL_IF(card_info_vld[1]);
        `SVTEST_END

        `SVTEST(full_source_cache_and_address_boundary)
            int prefix_len;
            byte value;
            prefix_len = int'(card_info_len[0]);
            source_len = 255;
            source_vld = 1;
            @(negedge clk);
            `FAIL_UNLESS_EQUAL(card_info_len[0], prefix_len + 255);
            `FAIL_UNLESS(card_info_len[0] > 255);
            foreach (source_mem[i]) begin
                read_byte(0, prefix_len + i, value);
                `FAIL_UNLESS_EQUAL(value, source_mem[i]);
            end
            read_byte(0, prefix_len + 255, value);
            `FAIL_UNLESS_EQUAL(value, 8'hff);
        `SVTEST_END

        `SVTEST(reset_suppresses_responses)
            byte value;
            source_vld = 1;
            read_byte(0, 0, value);
            srst = 1;
            @(negedge clk);
            `FAIL_IF(card_info_rd_vld[0] || card_info_rd_vld[1]);
            `FAIL_IF(source_rd[0] || source_rd[1]);
        `SVTEST_END
    `SVUNIT_TESTS_END
endmodule : xilinx_alveo_usplus_card_info_unit_test
