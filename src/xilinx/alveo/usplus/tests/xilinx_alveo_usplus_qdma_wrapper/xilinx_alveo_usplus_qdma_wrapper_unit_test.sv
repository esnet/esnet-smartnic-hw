`include "svunit_defines.svh"

module xilinx_alveo_usplus_qdma_wrapper_unit_test;
    import svunit_pkg::svunit_testcase;
    import xilinx_qdma_pkg::*;

    string name = "xilinx_alveo_usplus_qdma_wrapper_ut";
    svunit_testcase svunit_ut;
    `define SVUNIT_TIMEOUT 500us
    `define IP DUT.i_xilinx_alveo_usplus_qdma.i_xilinx_alveo_usplus_qdma

    logic pcie_rstn = 0;
    logic pcie_refclk_p = 0;
    wire pcie_refclk_n = ~pcie_refclk_p;
    wire [15:0] pcie_rxp = '0, pcie_rxn = '1;
    wire [15:0] pcie_txp, pcie_txn;
    wire clk_125mhz, clk_250mhz, dma_aclk, dma_aresetn;
    logic core_clk = 0;
    always #2ns pcie_refclk_p = ~pcie_refclk_p;
    always #2.7ns core_clk = ~core_clk;

    axi4l_intf axil_if ();
    packet_intf #(.DATA_BYTE_WID(64), .META_WID(PKT_H2C_META_WID)) pkt_h2c_dma (.clk(dma_aclk));
    packet_intf #(.DATA_BYTE_WID(64), .META_WID(PKT_C2H_META_WID)) pkt_c2h_dma (.clk(dma_aclk));
    axi4s_intf #(.DATA_BYTE_WID(shell_pkg::DMA_ST_DATA_BYTE_WID),
                 .TID_WID(shell_pkg::DMA_ST_QID_WID),
                 .TDEST_WID(shell_pkg::DMA_ST_AXIS_TDEST_WID),
                 .TUSER_WID(shell_pkg::DMA_ST_AXIS_TUSER_WID)) axis_h2c (.aclk(core_clk));
    axi4s_intf #(.DATA_BYTE_WID(shell_pkg::DMA_ST_DATA_BYTE_WID),
                 .TID_WID(shell_pkg::DMA_ST_QID_WID),
                 .TDEST_WID(shell_pkg::DMA_ST_AXIS_TDEST_WID),
                 .TUSER_WID(shell_pkg::DMA_ST_AXIS_TUSER_WID)) axis_c2h (.aclk(core_clk));

    xilinx_alveo_usplus_host DUT (.*);
    xilinx_alveo_qdma_st #(.QID_WID(11)) i_datapath (
        .aclk(dma_aclk), .aresetn(dma_aresetn),
        .core_clk, .core_srst(~dma_aresetn),
        .axil_if, .pkt_h2c_dma, .pkt_c2h_dma, .axis_h2c, .axis_c2h
    );

    function void build();
        svunit_ut = new(name);
    endfunction

    task automatic reset_link();
        @(negedge pcie_refclk_p);
        pcie_rstn = 0;
        repeat (16) @(posedge pcie_refclk_p);
        @(negedge pcie_refclk_p);
        pcie_rstn = 1;
        repeat (64) @(posedge dma_aclk);
        repeat (32) @(posedge core_clk);
    endtask

    task setup();
        svunit_ut.setup();
        `IP.axil_test_if.idle_controller();
        `IP.tb_h2c_valid = 0;
        `IP.tb_c2h_ready = 1;
        `IP.tb_cmpt_ready = 1;
        axis_h2c.idle_rx();
        axis_c2h.idle_tx();
        reset_link();
    endtask

    task teardown();
        svunit_ut.teardown();
    endtask

    function automatic logic [31:0] qdma_crc(input byte raw[]);
        int nbeats = (raw.size()+63)/64;
        byte rev[] = new[nbeats*64];
        foreach (rev[i]) begin
            int src = (i/64)*64 + (63-i%64);
            rev[i] = src < raw.size() ? raw[src] : 8'h00;
        end
        return crc_verif_pkg::calculate(32, crc_pkg::CRC32_MPEG2.POLY,
            crc_pkg::CRC32_MPEG2.INIT, 0, 0, crc_pkg::CRC32_MPEG2.XOROUT, rev);
    endfunction

    task automatic make_data(input int size, output byte data[]);
        data = new[size];
        foreach (data[i]) data[i] = 8'(i*7+3);
    endtask

    task automatic send_h2c(input byte data[], input logic [10:0] qid,
                            input bit bad_crc = 0, input bit err = 0);
        logic [31:0] tcrc = qdma_crc(data);
        if (bad_crc) tcrc = ~tcrc;
        `IP.send_h2c(data, qid, tcrc, err);
    endtask

    task automatic recv_core(input byte expected[], input logic [8:0] qid);
        logic [63:0][7:0] data;
        logic [63:0] keep;
        logic last;
        logic [8:0] tid;
        logic [shell_pkg::DMA_ST_AXIS_TDEST_WID-1:0] dest;
        logic [shell_pkg::DMA_ST_AXIS_TUSER_WID-1:0] user_meta;
        int offset = 0;
        do begin
            axis_h2c.receive(data, keep, last, tid, dest, user_meta);
            `FAIL_UNLESS_EQUAL(tid, qid)
            `FAIL_UNLESS_EQUAL(user_meta, '0)
            for (int i = 0; i < 64; i++) begin
                if (keep[i]) begin
                    `FAIL_IF(offset >= expected.size())
                    if (offset < expected.size()) `FAIL_UNLESS_EQUAL(data[i], expected[offset])
                    offset++;
                end
            end
        end while (!last);
        `FAIL_UNLESS_EQUAL(offset, expected.size())
    endtask

    task automatic send_core(input byte data[], input logic [8:0] qid);
        logic [63:0][7:0] word_data;
        logic [63:0] keep;
        int n;
        for (int offset = 0; offset < data.size(); offset += 64) begin
            n = data.size()-offset;
            if (n > 64) n = 64;
            word_data = '0;
            keep = '0;
            for (int i = 0; i < n; i++) begin
                word_data[i] = data[offset+i];
                keep[i] = 1;
            end
            axis_c2h.send(word_data, keep, offset+n == data.size(), qid);
        end
    endtask

    task automatic wait_c2h(input int packets);
        while (`IP.c2h_packets < packets || `IP.cmpt_packets < packets) @(posedge dma_aclk);
        repeat (8) @(posedge dma_aclk);
    endtask

    task automatic check_native_c2h(input byte data[], input logic [10:0] qid,
                                    input int pkt_id = 1);
        `FAIL_UNLESS_EQUAL(`IP.c2h_bytes.size(), data.size())
        foreach (data[i]) begin
            if (i < `IP.c2h_bytes.size()) `FAIL_UNLESS_EQUAL(`IP.c2h_bytes[i], data[i])
        end
        `FAIL_UNLESS_EQUAL(`IP.last_len, data.size())
        `FAIL_UNLESS_EQUAL(`IP.last_qid, qid)
        `FAIL_UNLESS_EQUAL(`IP.last_crc, qdma_crc(data))
        `FAIL_UNLESS_EQUAL(`IP.last_cmpt[19:4], data.size())
        `FAIL_UNLESS_EQUAL(`IP.last_cmpt[3], 1'b1)
        `FAIL_UNLESS_EQUAL(`IP.last_cmpt_id, pkt_id)
    endtask

    task automatic reg_write(input bit [31:0] addr, input bit [31:0] data);
        axi4l_pkg::resp_t resp;
        bit timeout;
        `IP.axil_test_if.write(addr, data, resp, timeout);
        `FAIL_IF(timeout)
        `FAIL_UNLESS_EQUAL(resp, axi4l_pkg::RESP_OKAY)
    endtask

    task automatic reg_read(input bit [31:0] addr, output bit [31:0] data);
        axi4l_pkg::resp_t resp;
        bit timeout;
        `IP.axil_test_if.read(addr, data, resp, timeout);
        `FAIL_IF(timeout)
        `FAIL_UNLESS_EQUAL(resp, axi4l_pkg::RESP_OKAY)
    endtask

    task automatic check_counter(input bit [31:0] offset, input int expected);
        bit [31:0] value;
        reg_read('h100+offset, value);
        `FAIL_UNLESS_EQUAL(value, expected)
    endtask

    `SVUNIT_TESTS_BEGIN
        `SVTEST(h2c_native_lengths_and_queue)
            int sizes[] = '{1, 63, 64, 65, 129, 9100};
            foreach (sizes[i]) begin
                byte data[];
                make_data(sizes[i], data);
                fork
                    send_h2c(data, 11'd511);
                    recv_core(data, 9'd511);
                join
            end
        `SVTEST_END

        `SVTEST(h2c_crc_qdma_error_and_oor)
            byte data[];
            make_data(65, data);
            send_h2c(data, 11'd512);
            send_h2c(data, 11'd2047, .bad_crc(1));
            send_h2c(data, 11'd3, .bad_crc(1));
            send_h2c(data, 11'd3, .err(1));
            repeat (128) begin
                @(posedge core_clk);
                `FAIL_IF(axis_h2c.tvalid)
            end
            check_counter(packet_counters_reg_pkg::OFFSET_CNT_PKT_OTHER_LOWER, 2);
            check_counter(packet_counters_reg_pkg::OFFSET_CNT_BYTE_OTHER_LOWER, 130);
            check_counter(packet_counters_reg_pkg::OFFSET_CNT_PKT_ERR_LOWER, 2);
            check_counter(packet_counters_reg_pkg::OFFSET_CNT_BYTE_ERR_LOWER, 130);
            fork
                send_h2c(data, 11'd0);
                recv_core(data, 9'd0);
            join
        `SVTEST_END

        `SVTEST(c2h_partial_packet_and_independent_stalls)
            byte data[];
            make_data(100, data);
            `IP.tb_cmpt_ready = 0;
            send_core(data, 9'd511);
            repeat (32) @(posedge dma_aclk);
            `FAIL_UNLESS_EQUAL(`IP.c2h_beats, 0)
            `FAIL_UNLESS_EQUAL(`IP.cmpt_packets, 0)
            `IP.tb_c2h_ready = 0;
            `IP.tb_cmpt_ready = 1;
            repeat (32) @(posedge dma_aclk);
            `FAIL_UNLESS_EQUAL(`IP.c2h_beats, 0)
            `IP.tb_c2h_ready = 1;
            wait_c2h(1);
            `FAIL_UNLESS_EQUAL(`IP.c2h_beats, 2)
            check_native_c2h(data, 11'd511);
            `IP.c2h_bytes.delete();
            make_data(64, data);
            send_core(data, 9'd0);
            wait_c2h(2);
            `FAIL_UNLESS_EQUAL(`IP.c2h_beats, 3)
            check_native_c2h(data, 11'd0, 2);
        `SVTEST_END

        `SVTEST(loopback_control_crosses_host_management_clock)
            bit [31:0] status;
            byte data[];
            make_data(129, data);
            reg_write(0, 1);
            do reg_read(4, status); while (status[1:0] != 1);
            send_h2c(data, 11'd17);
            wait_c2h(1);
            check_native_c2h(data, 11'd17);
            repeat (32) begin
                @(posedge core_clk);
                `FAIL_IF(axis_h2c.tvalid)
            end
            check_counter(packet_counters_reg_pkg::OFFSET_CNT_PKT_OK_LOWER, 1);
            reg_write(0, 0);
            do reg_read(4, status); while (status[1:0] != 0);
            fork
                send_h2c(data, 11'd18);
                recv_core(data, 9'd18);
            join
        `SVTEST_END

        `SVTEST(reset_flushes_pending_c2h_and_packet_id)
            byte data[];
            make_data(100, data);
            `IP.tb_cmpt_ready = 0;
            send_core(data, 9'd1);
            repeat (32) @(posedge dma_aclk);
            reset_link();
            `IP.tb_cmpt_ready = 1;
            repeat (32) @(posedge dma_aclk);
            `FAIL_UNLESS_EQUAL(`IP.c2h_packets, 0)
            make_data(65, data);
            send_core(data, 9'd2);
            wait_c2h(1);
            check_native_c2h(data, 11'd2);
        `SVTEST_END
    `SVUNIT_TESTS_END
    `undef IP
endmodule
