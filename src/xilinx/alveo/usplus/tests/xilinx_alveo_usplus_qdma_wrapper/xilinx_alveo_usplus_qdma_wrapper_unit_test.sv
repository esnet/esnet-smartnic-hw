`include "svunit_defines.svh"

module xilinx_alveo_usplus_qdma_wrapper_unit_test;
    import svunit_pkg::svunit_testcase;
    import xilinx_pci_verif_pkg::*;
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

    xilinx_pci_cfg_ext_intf cfg_ext_if (.clk(dma_aclk));
    pci_vpd_intf vpd_if (.clk(dma_aclk));
    xilinx_pci_cfg_ext_vpd i_cfg_vpd (
        .cfg_ext_if, .aresetn(dma_aresetn), .vpd_srst(!dma_aresetn), .vpd_if
    );
    xilinx_pci_vpd #(.CARD_INFO_EN(0)) i_vpd (
        .vpd_if, .srst(!dma_aresetn),
        .init_done(), .init_error(), .init_timeout(), .init_early_read(), .init_time_ms(),
        .init_done_mask(1'b0), .card_info_vld(1'b0), .card_info_error(1'b0),
        .card_info_len(9'b0), .card_info_rd(), .card_info_rd_addr(),
        .card_info_rd_data(8'b0), .card_info_rd_vld(1'b0)
    );
    xilinx_pci_cfg_ext_intf_agent cfg_agent;
    xilinx_pci_cfg_ext_vpd_agent vpd_agents[2];
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

    axi4l_verif_pkg::axi4l_reg_agent #() reg_agent;

    axi4s_verif_pkg::axi4s_driver #(
        .DATA_BYTE_WID ( shell_pkg::DMA_ST_DATA_BYTE_WID ),
        .TID_T        ( bit [shell_pkg::DMA_ST_QID_WID-1:0] ),
        .TDEST_T      ( bit [shell_pkg::DMA_ST_AXIS_TDEST_WID-1:0] ),
        .TUSER_T      ( bit [shell_pkg::DMA_ST_AXIS_TUSER_WID-1:0] )
    ) c2h_driver;
    axi4s_verif_pkg::axi4s_monitor #(
        .DATA_BYTE_WID ( shell_pkg::DMA_ST_DATA_BYTE_WID ),
        .TID_T        ( bit [shell_pkg::DMA_ST_QID_WID-1:0] ),
        .TDEST_T      ( bit [shell_pkg::DMA_ST_AXIS_TDEST_WID-1:0] ),
        .TUSER_T      ( bit [shell_pkg::DMA_ST_AXIS_TUSER_WID-1:0] )
    ) h2c_monitor;

    function void build();
        svunit_ut = new(name);
        cfg_agent = new();
        cfg_agent.pci_cfg_ext_vif = `IP.cfg_test_if;
        foreach (vpd_agents[i]) begin
            vpd_agents[i] = new($sformatf("vpd_pf%0d", i), i);
            vpd_agents[i].pci_cfg_ext_agent = cfg_agent;
        end
        c2h_driver = new("c2h_driver");
        c2h_driver.axis_vif = axis_c2h;
        h2c_monitor = new("h2c_monitor");
        h2c_monitor.axis_vif = axis_h2c;
        reg_agent = new("reg_agent", 256, 256);
        reg_agent.axil_vif = `IP.axil_test_if;
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
        cfg_agent.idle();
        reg_agent.idle();
        `IP.tb_h2c_valid = 0;
        `IP.tb_c2h_ready = 1;
        `IP.tb_cmpt_ready = 1;
        `IP.usr_flr_set = 0;
        `IP.usr_flr_fnc = 0;
        h2c_monitor.idle();
        c2h_driver.idle();
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
            h2c_monitor.receive_beat(data, keep, last, tid, dest, user_meta);
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
            c2h_driver.send_beat(word_data, keep, offset+n == data.size(), qid);
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
        bit error;
        string msg;
        bit timeout;
        reg_agent.lock();
        reg_agent._write(addr, data, error, timeout, msg);
        reg_agent.unlock();
        `FAIL_IF(timeout)
        `FAIL_IF_LOG(error, msg)
    endtask

    task automatic reg_read(input bit [31:0] addr, output bit [31:0] data);
        bit error;
        string msg;
        bit timeout;
        reg_agent.lock();
        reg_agent._read(addr, data, error, timeout, msg);
        reg_agent.unlock();
        `FAIL_IF(timeout)
        `FAIL_IF_LOG(error, msg)
    endtask

    task automatic check_counter(input bit [31:0] offset, input int expected);
        bit [31:0] value;
        reg_read('h100+offset, value);
        `FAIL_UNLESS_EQUAL(value, expected)
    endtask

    `SVUNIT_TESTS_BEGIN
        `SVTEST(flr_completes_with_the_requested_function)
            for (int fnc = 0; fnc < 12; fnc++) begin
                @(negedge dma_aclk);
                `IP.usr_flr_fnc = 8'(fnc);
                `IP.usr_flr_set = 1;
                @(posedge dma_aclk); #1ns;
                `FAIL_UNLESS_EQUAL(`IP.usr_flr_done_vld, 0)
                @(negedge dma_aclk);
                `IP.usr_flr_set = 0;
                repeat (2) begin
                    @(posedge dma_aclk); #1ns;
                    `FAIL_UNLESS_EQUAL(`IP.usr_flr_done_vld, 0)
                end
                @(posedge dma_aclk); #1ns;
                `FAIL_UNLESS_EQUAL(`IP.usr_flr_done_vld, 1)
                `FAIL_UNLESS_EQUAL(`IP.usr_flr_done_fnc, 8'(fnc))
                @(posedge dma_aclk); #1ns;
                `FAIL_UNLESS_EQUAL(`IP.usr_flr_done_vld, 0)
            end
        `SVTEST_END

        `SVTEST(flr_preserves_back_to_back_function_notifications)
            for (int cycle = 0; cycle < 12; cycle++) begin
                @(negedge dma_aclk);
                `IP.usr_flr_set = cycle < 8;
                `IP.usr_flr_fnc = 8'(cycle);
                @(posedge dma_aclk); #1ns;
                if (cycle >= 3 && cycle < 11) begin
                    `FAIL_UNLESS_EQUAL(`IP.usr_flr_done_vld, 1)
                    `FAIL_UNLESS_EQUAL(`IP.usr_flr_done_fnc, 8'(cycle - 3))
                end else `FAIL_UNLESS_EQUAL(`IP.usr_flr_done_vld, 0)
            end
        `SVTEST_END

        `SVTEST(link_reset_discards_pending_flr_completion)
            @(negedge dma_aclk);
            `IP.usr_flr_set = 1;
            `IP.usr_flr_fnc = 8'h07;
            @(posedge dma_aclk);
            @(negedge dma_aclk);
            `IP.usr_flr_set = 0;
            reset_link();
            repeat (8) begin
                @(posedge dma_aclk); #1ns;
                `FAIL_UNLESS_EQUAL(`IP.usr_flr_done_vld, 0)
            end
        `SVTEST_END

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
        `SVTEST(configuration_vpd_ports)
            byte value;
            foreach (vpd_agents[i]) begin
                vpd_agents[i].read_byte(0, value);
                `FAIL_UNLESS_EQUAL(value, 8'h82);
            end
        `SVTEST_END

    `SVUNIT_TESTS_END
    `undef IP
endmodule
