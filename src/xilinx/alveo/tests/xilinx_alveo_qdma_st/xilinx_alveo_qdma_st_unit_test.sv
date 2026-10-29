`include "svunit_defines.svh"

module xilinx_alveo_qdma_st_unit_test;
    import svunit_pkg::svunit_testcase;
    import xilinx_qdma_pkg::*;
    import packet_verif_pkg::*;

    string name = "xilinx_alveo_qdma_st_ut";
    svunit_testcase svunit_ut;

    `define SVUNIT_TIMEOUT 500us

    localparam int QID_WID     = 12;
    localparam int MAX_PKT_LEN = 9100;

    // Packet debug blocks in the qdma_decoder address map
    localparam int CAPTURE_BASE  = 'h1000;
    localparam int PLAYBACK_BASE = 'h2000;
    localparam int DEBUG_MEM_SIZE = 16384;

    // =========================================================================
    // Clocks and reset
    //
    // Free-running from time 0: the ASYNC packet FIFOs' reset synchronisers
    // need clock activity before setup() runs, otherwise xsim hangs.
    // =========================================================================
    logic aclk     = 1'b0;
    logic core_clk = 1'b0;
    logic axil_clk = 1'b0;
    logic aresetn  = 1'b0;

    always #2ns   aclk     = ~aclk;     // 250 MHz — QDMA clock domain
    always #2.5ns core_clk = ~core_clk; // 200 MHz — core clock domain
    always #5ns   axil_clk = ~axil_clk; // 100 MHz — management clock domain

    wire core_srst = ~aresetn;

    // =========================================================================
    // Interfaces
    // =========================================================================
    axi4l_intf axil_if ();
    assign axil_if.aclk = axil_clk;
    always @(posedge axil_clk) axil_if.aresetn <= aresetn;
    initial axil_if.aresetn = 1'b0;

    packet_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .META_WID(PKT_H2C_META_WID))
        pkt_h2c_dma (.clk(aclk));
    packet_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .META_WID(PKT_C2H_META_WID))
        pkt_c2h_dma (.clk(aclk));

    localparam int TID_WID = QID_WID;

    axi4s_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID               ),
        .TID_WID       ( TID_WID                          ),
        .TDEST_WID     ( shell_pkg::DMA_ST_AXIS_TDEST_WID ),
        .TUSER_WID     ( shell_pkg::DMA_ST_AXIS_TUSER_WID )
    ) axis_h2c (.aclk(core_clk));

    axi4s_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID               ),
        .TID_WID       ( TID_WID                          ),
        .TDEST_WID     ( shell_pkg::DMA_ST_AXIS_TDEST_WID ),
        .TUSER_WID     ( shell_pkg::DMA_ST_AXIS_TUSER_WID )
    ) axis_c2h (.aclk(core_clk));

    // Drive all TB-sourced interface signals from time 0 to avoid X at CDC.
    initial begin
        pkt_h2c_dma.vld  = 1'b0;
        pkt_h2c_dma.data = '0;
        pkt_h2c_dma.eop  = 1'b0;
        pkt_h2c_dma.mty  = '0;
        pkt_h2c_dma.err  = 1'b0;
        pkt_h2c_dma.meta = '0;
        axis_c2h.tvalid  = 1'b0;
        axis_c2h.tdata   = '0;
        axis_c2h.tkeep   = '0;
        axis_c2h.tlast   = 1'b0;
        axis_c2h.tid     = '0;
        axis_c2h.tdest   = '0;
        axis_c2h.tuser   = '0;
        pkt_c2h_dma.rdy  = 1'b1;
        axis_h2c.tready  = 1'b1;
    end

    // =========================================================================
    // DUT
    // =========================================================================
    xilinx_alveo_qdma_st #(
        .QID_WID     ( QID_WID     ),
        .MAX_PKT_LEN ( MAX_PKT_LEN )
    ) DUT (
        .aclk,
        .aresetn,
        .core_clk,
        .core_srst,
        .axil_if,
        .pkt_h2c_dma,
        .pkt_c2h_dma,
        .axis_h2c,
        .axis_c2h
    );

    // =========================================================================
    // Verif objects
    // =========================================================================
    // H2C driver: packet_intf_driver with pkt_h2c_meta_t meta so it can carry
    // the computed CRC into the DUT's CRC checker.
    packet_intf_driver  #(AXIS_DATA_BYTE_WID, pkt_h2c_meta_t) h2c_driver;
    // C2H DMA monitor: receives completed C2H packets from the DUT.
    packet_intf_monitor #(AXIS_DATA_BYTE_WID, pkt_c2h_meta_t) c2h_dma_monitor;

    // Packet debug agents: capture taps the H2C stream, playback injects C2H.
    packet_capture_monitor #(pkt_h2c_meta_t) h2c_capture;
    packet_playback_driver #(pkt_c2h_meta_t) c2h_playback;

    // Register agents
    axi4l_verif_pkg::axi4l_reg_agent axil_reg_agent;
    packet_verif_pkg::packet_counters_reg_agent cnt_h2c_in;
    packet_verif_pkg::packet_counters_reg_agent cnt_h2c_out;
    packet_verif_pkg::packet_counters_reg_agent cnt_c2h_in;
    packet_verif_pkg::packet_counters_reg_agent cnt_c2h_out;

    function void build();
        svunit_ut = new(name);

        h2c_driver = new("h2c_driver");
        h2c_driver.packet_vif = pkt_h2c_dma;

        c2h_dma_monitor = new("c2h_dma_monitor");
        c2h_dma_monitor.packet_vif = pkt_c2h_dma;

        axil_reg_agent = new("axil_reg_agent");
        axil_reg_agent.axil_vif = axil_if;
        h2c_capture = new("h2c_capture", DEBUG_MEM_SIZE, AXIS_DATA_BYTE_WID*8,
                          axil_reg_agent, CAPTURE_BASE);
        c2h_playback = new("c2h_playback", DEBUG_MEM_SIZE, AXIS_DATA_BYTE_WID*8,
                           axil_reg_agent, PLAYBACK_BASE);

        cnt_h2c_in  = new("cnt_h2c_in",  axil_reg_agent, 'h0100);
        cnt_h2c_out = new("cnt_h2c_out", axil_reg_agent, 'h0200);
        cnt_c2h_in  = new("cnt_c2h_in",  axil_reg_agent, 'h0300);
        cnt_c2h_out = new("cnt_c2h_out", axil_reg_agent, 'h0400);
    endfunction

    task setup();
        svunit_ut.setup();
        idle();
        aresetn = 1'b0;
        repeat (16) @(posedge aclk);
        aresetn = 1'b1;
        repeat (32) @(posedge aclk);
        repeat (32) @(posedge core_clk);
    endtask

    task teardown();
        svunit_ut.teardown();
        idle();
    endtask

    task idle();
        axil_if.idle_controller();
        h2c_driver.idle();
        axis_c2h.idle_tx();
        pkt_c2h_dma.rdy <= 1'b1;
        axis_h2c.tready <= 1'b1;
    endtask

    // =========================================================================
    // Register access
    // =========================================================================
    task automatic reg_write(input bit [31:0] addr, input bit [31:0] data);
        axi4l_pkg::resp_t resp;
        bit timeout;
        axil_if.write(addr, data, resp, timeout);
        `FAIL_IF_LOG(timeout, "AXI-L write timed out")
        `FAIL_UNLESS_LOG(resp === axi4l_pkg::RESP_OKAY, "AXI-L write returned an error response")
    endtask

    task automatic reg_read(input bit [31:0] addr, output bit [31:0] data);
        axi4l_pkg::resp_t resp;
        bit timeout;
        axil_if.read(addr, data, resp, timeout);
        `FAIL_IF_LOG(timeout, "AXI-L read timed out")
        `FAIL_UNLESS_LOG(resp === axi4l_pkg::RESP_OKAY, "AXI-L read returned an error response")
    endtask

    task automatic set_loopback(input bit mode);
        bit [31:0] status;
        reg_write(qdma_reg_pkg::OFFSET_LOOPBACK_CONFIG, 32'(mode));
        forever begin
            reg_read(qdma_reg_pkg::OFFSET_LOOPBACK_STATUS, status);
            if (status[0] === mode && status[1] === 1'b0) break;
        end
    endtask

    // =========================================================================
    // H2C send helper
    //
    // Builds a deterministic byte array, computes the correct CRC-32 over it,
    // packs both into pkt_h2c_meta_t, and sends via the packet_intf_driver.
    // The DUT's packet_crc_rx will verify the CRC against pkt_h2c_dma.meta.tcrc.
    // =========================================================================
    task automatic send_h2c(
        input int                 num_bytes,
        input logic [QID_WID-1:0] qid  = '0,
        input logic               err  = 1'b0,
        input byte                seed = 8'h00
    );
        byte data[];
        pkt_h2c_meta_t meta;
        packet_raw#(pkt_h2c_meta_t) pkt;

        // Build deterministic payload and packet, then read back the CRC.
        data = new[num_bytes];
        for (int i = 0; i < num_bytes; i++) data[i] = seed + i;

        pkt = packet_raw#(pkt_h2c_meta_t)::create_from_bytes("h2c_pkt", data, '0, err);
        meta.tcrc = pkt.crc();
        meta.qid  = QID_WID'(qid);
        pkt.set_meta(meta);
        h2c_driver.send(pkt);
    endtask

    // Send with intentionally wrong CRC — DUT should mark err=1 and DROP_ERRORED
    // discards the packet.  Use err=0 on the QDMA-side so only the CRC check fires.
    task automatic send_h2c_bad_crc(
        input int                 num_bytes,
        input logic [QID_WID-1:0] qid = '0
    );
        byte data[];
        pkt_h2c_meta_t meta;
        packet_raw#(pkt_h2c_meta_t) pkt;

        data = new[num_bytes];
        for (int i = 0; i < num_bytes; i++) data[i] = 8'(i);

        pkt = packet_raw#(pkt_h2c_meta_t)::create_from_bytes("h2c_bad_crc", data, '0, 1'b0);
        meta.tcrc = pkt.crc() ^ 32'hFFFF_FFFF;  // flip all bits — guaranteed mismatch
        meta.qid  = QID_WID'(qid);
        pkt.set_meta(meta);
        h2c_driver.send(pkt);
    endtask

    // =========================================================================
    // C2H DMA receive helper
    //
    // Receives one packet from pkt_c2h_dma via the packet_intf_monitor and
    // unpacks pkt_c2h_meta_t to return qid and byte count.
    // =========================================================================
    task automatic recv_c2h_dma(
        output int                 num_bytes,
        output logic [QID_WID-1:0] qid,
        output logic               err
    );
        packet#(pkt_c2h_meta_t) pkt;
        pkt_c2h_meta_t meta;
        c2h_dma_monitor.receive(pkt);
        meta      = pkt.get_meta();
        qid       = QID_WID'(meta.qid);
        num_bytes = pkt.size();
        err       = pkt.is_errored();
    endtask

    // =========================================================================
    // Core-side (axi4s) helpers — unchanged; axis_c2h/axis_h2c are plain
    // axi4s_intf so we drive/sample them directly.
    // =========================================================================
    task automatic send_axis(
        input int                 num_bytes,
        input logic [QID_WID-1:0] qid = '0
    );
        int remaining = num_bytes;
        int idx = 0;
        logic [AXIS_DATA_BYTE_WID-1:0][7:0] tdata;
        logic [AXIS_DATA_BYTE_WID-1:0]      tkeep;
        logic tlast;
        int this_beat;
        while (remaining > 0) begin
            this_beat = (remaining > AXIS_DATA_BYTE_WID) ? AXIS_DATA_BYTE_WID : remaining;
            for (int b = 0; b < AXIS_DATA_BYTE_WID; b++) begin
                tdata[b] = 8'(idx + b);
                tkeep[b] = (b < this_beat);
            end
            tlast = (remaining <= AXIS_DATA_BYTE_WID);
            axis_c2h.send(tdata, tkeep, tlast, TID_WID'(qid));
            remaining -= AXIS_DATA_BYTE_WID;
            idx       += AXIS_DATA_BYTE_WID;
        end
    endtask

    task automatic recv_axis(
        output int                 num_bytes,
        output logic [QID_WID-1:0] qid
    );
        logic [AXIS_DATA_BYTE_WID-1:0][7:0] tdata;
        logic [AXIS_DATA_BYTE_WID-1:0]      tkeep;
        logic tlast;
        logic [TID_WID-1:0] tid;
        logic [shell_pkg::DMA_ST_AXIS_TDEST_WID-1:0] tdest;
        logic [shell_pkg::DMA_ST_AXIS_TUSER_WID-1:0] tuser;
        num_bytes = 0;
        forever begin
            axis_h2c.receive(tdata, tkeep, tlast, tid, tdest, tuser);
            for (int b = 0; b < AXIS_DATA_BYTE_WID; b++) if (tkeep[b]) num_bytes++;
            if (tlast) break;
        end
        qid = QID_WID'(tid);
    endtask

    task automatic expect_idle_core(input int cycles);
        repeat (cycles) begin
            @(posedge core_clk);
            `FAIL_IF_LOG(axis_h2c.tvalid, "unexpected traffic on axis_h2c")
        end
    endtask

    task automatic expect_idle_dma(input int cycles);
        repeat (cycles) begin
            @(posedge aclk);
            `FAIL_IF_LOG(pkt_c2h_dma.vld, "unexpected packet on pkt_c2h_dma")
        end
    endtask

    // =========================================================================
    // Packet debug helpers
    //
    // The enables take effect at a packet boundary after crossing from the
    // management clock, so allow them to settle before driving traffic.
    // =========================================================================
    task automatic set_capture_en(input bit en);
        reg_write(CAPTURE_BASE + packet_capture_reg_pkg::OFFSET_CONTROL, 32'(en) << 1);
        repeat (32) @(posedge aclk);
    endtask

    task automatic set_playback_en(input bit en);
        reg_write(PLAYBACK_BASE + packet_playback_reg_pkg::OFFSET_CONTROL, 32'(en) << 1);
        repeat (32) @(posedge aclk);
    endtask

    // Capture one H2C packet while send_h2c / send_h2c_bad_crc drives it.
    task automatic capture_h2c(output packet#(pkt_h2c_meta_t) pkt);
        bit error, timeout;
        h2c_capture.capture(pkt, error, timeout);
        `FAIL_IF_LOG(error,   "capture reported an error")
        `FAIL_IF_LOG(timeout, "capture timed out")
    endtask

    // Play one packet into C2H with the given QDMA-side meta.
    task automatic play_c2h(
        input int                 num_bytes,
        input logic [QID_WID-1:0] qid,
        input logic [31:0]        tcrc,
        input byte                seed = 8'h00
    );
        byte data[];
        pkt_c2h_meta_t meta;
        packet_raw#(pkt_c2h_meta_t) pkt;
        bit error, timeout;

        data = new[num_bytes];
        for (int i = 0; i < num_bytes; i++) data[i] = seed + i;

        meta.size = 16'(num_bytes);
        meta.tcrc = tcrc;
        meta.qid  = QID_WID'(qid);
        pkt = packet_raw#(pkt_c2h_meta_t)::create_from_bytes("c2h_play", data, meta, 1'b0);
        c2h_playback.send_one(pkt, error, timeout);
        `FAIL_IF_LOG(error,   "playback reported an error")
        `FAIL_IF_LOG(timeout, "playback timed out")
    endtask

    // =========================================================================
    // Counter helpers
    // =========================================================================
    task automatic settle_counts();
        repeat (64) @(posedge aclk);
        repeat (64) @(posedge core_clk);
    endtask

    task automatic clear_all_counts();
        cnt_h2c_in.clear();
        cnt_h2c_out.clear();
        cnt_c2h_in.clear();
        cnt_c2h_out.clear();
        settle_counts();
    endtask

    task automatic check_counts(
        input packet_verif_pkg::packet_counters_reg_agent agent,
        input string                                      label,
        input longint unsigned                            exp_pkt_ok,
        input longint unsigned                            exp_byte_ok,
        input longint unsigned                            exp_pkt_err,
        input longint unsigned                            exp_byte_err
    );
        longint unsigned pkt_ok, pkt_err, byte_ok, byte_err;
        agent.get_pkt_ok_count(pkt_ok);
        agent.get_pkt_err_count(pkt_err);
        agent.get_byte_ok_count(byte_ok);
        agent.get_byte_err_count(byte_err);
        `FAIL_UNLESS_LOG(pkt_ok   === exp_pkt_ok,
            $sformatf("%s: ok pkt count %0d, expected %0d",   label, pkt_ok,   exp_pkt_ok))
        `FAIL_UNLESS_LOG(byte_ok  === exp_byte_ok,
            $sformatf("%s: ok byte count %0d, expected %0d",  label, byte_ok,  exp_byte_ok))
        `FAIL_UNLESS_LOG(pkt_err  === exp_pkt_err,
            $sformatf("%s: err pkt count %0d, expected %0d",  label, pkt_err,  exp_pkt_err))
        `FAIL_UNLESS_LOG(byte_err === exp_byte_err,
            $sformatf("%s: err byte count %0d, expected %0d", label, byte_err, exp_byte_err))
    endtask

    task automatic check_all_counts_zero();
        check_counts(cnt_h2c_in,  "h2c_in",  0, 0, 0, 0);
        check_counts(cnt_h2c_out, "h2c_out", 0, 0, 0, 0);
        check_counts(cnt_c2h_in,  "c2h_in",  0, 0, 0, 0);
        check_counts(cnt_c2h_out, "c2h_out", 0, 0, 0, 0);
    endtask

    `SVUNIT_TESTS_BEGIN

        // ---------------------------------------------------------------
        // Datapath
        // ---------------------------------------------------------------

        // H2C: correct CRC passes the checker and reaches the core.
        `SVTEST(h2c_crosses_to_core)
            int bytes;
            logic [QID_WID-1:0] qid;
            fork
                send_h2c(192, 12'h123);
                recv_axis(bytes, qid);
            join
            `FAIL_UNLESS_EQUAL(bytes, 192)
            `FAIL_UNLESS_EQUAL(qid, 12'h123)
        `SVTEST_END

        // H2C: wrong CRC is caught — the FIFO drops the packet (DROP_ERRORED=1)
        // and the core sees nothing.
        `SVTEST(h2c_bad_crc_dropped)
            send_h2c_bad_crc(128, 12'h001);
            expect_idle_core(128);
        `SVTEST_END

        // H2C: QDMA-signalled err=1 is dropped independently of CRC.
        `SVTEST(h2c_qdma_err_dropped)
            send_h2c(128, 12'h001, .err(1'b1));
            expect_idle_core(128);
        `SVTEST_END

        // H2C: a dropped packet does not block the next good one.
        `SVTEST(h2c_bad_crc_does_not_block)
            int bytes;
            logic [QID_WID-1:0] qid;
            send_h2c_bad_crc(128, 12'h001);
            fork
                send_h2c(64, 12'h002);
                recv_axis(bytes, qid);
            join
            `FAIL_UNLESS_EQUAL(bytes, 64)
            `FAIL_UNLESS_EQUAL(qid, 12'h002)
        `SVTEST_END

        // C2H: packet size is packed into pkt_c2h_dma.meta at the FIFO output.
        `SVTEST(c2h_crosses_to_dma_with_size)
            logic [PKT_C2H_META_WID-1:0] meta_at_sop;
            pkt_c2h_meta_t c2h_meta;
            fork
                send_axis(100, 12'h0AB);
                begin
                    @(posedge aclk iff (pkt_c2h_dma.vld && pkt_c2h_dma.rdy));
                    meta_at_sop = pkt_c2h_dma.meta;
                end
            join
            c2h_meta = meta_at_sop;
            `FAIL_UNLESS_EQUAL(c2h_meta.size, 16'd100)
        `SVTEST_END

        `SVTEST(c2h_partial_beat_size)
            logic [PKT_C2H_META_WID-1:0] meta_at_sop;
            pkt_c2h_meta_t c2h_meta;
            fork
                send_axis(37, 12'h7FF);
                begin
                    @(posedge aclk iff (pkt_c2h_dma.vld && pkt_c2h_dma.rdy));
                    meta_at_sop = pkt_c2h_dma.meta;
                end
            join
            c2h_meta = meta_at_sop;
            `FAIL_UNLESS_EQUAL(c2h_meta.size, 16'd37)
        `SVTEST_END

        // ---------------------------------------------------------------
        // Loopback
        // ---------------------------------------------------------------

        `SVTEST(loopback_reg_defaults)
            bit [31:0] data;
            reg_read(qdma_reg_pkg::OFFSET_LOOPBACK_CONFIG, data);
            `FAIL_UNLESS_EQUAL(data[0], 1'b0)
            reg_read(qdma_reg_pkg::OFFSET_LOOPBACK_STATUS, data);
            `FAIL_UNLESS_EQUAL(data[0], 1'b0)
            `FAIL_UNLESS_EQUAL(data[1], 1'b0)
        `SVTEST_END

        `SVTEST(loopback_reg_window_complete)
            bit [31:0] data;
            reg_read(qdma_reg_pkg::OFFSET_LOOPBACK_CONFIG, data);
            reg_read(qdma_reg_pkg::OFFSET_LOOPBACK_STATUS, data);
            reg_read(qdma_reg_pkg::OFFSET_RESERVED_0, data);
            `FAIL_UNLESS_EQUAL(data, 32'h0)
            reg_read(qdma_reg_pkg::OFFSET_RESERVED_1, data);
            `FAIL_UNLESS_EQUAL(data, 32'h0)
        `SVTEST_END

        `SVTEST(loopback_h2c_returns_as_c2h)
            int bytes;
            logic [QID_WID-1:0] qid;
            logic err;
            set_loopback(1'b1);
            fork
                send_h2c(128, 12'h0C5);
                recv_c2h_dma(bytes, qid, err);
            join
            `FAIL_UNLESS_EQUAL(bytes, 128)
            `FAIL_UNLESS_EQUAL(qid, 12'h0C5)
        `SVTEST_END

        `SVTEST(loopback_core_h2c_idle)
            int bytes;
            logic [QID_WID-1:0] qid;
            logic err;
            set_loopback(1'b1);
            fork
                send_h2c(128, 12'h00C);
                recv_c2h_dma(bytes, qid, err);
                expect_idle_core(192);
            join
            `FAIL_UNLESS_EQUAL(qid, 12'h00C)
        `SVTEST_END

        `SVTEST(loopback_core_c2h_discarded)
            set_loopback(1'b1);
            send_axis(128, 12'h07F);
            expect_idle_dma(192);
        `SVTEST_END

        `SVTEST(loopback_disable_restores_normal)
            int bytes;
            logic [QID_WID-1:0] qid;
            logic err;
            set_loopback(1'b1);
            set_loopback(1'b0);
            fork
                send_h2c(64, 12'h055);
                recv_axis(bytes, qid);
            join
            `FAIL_UNLESS_EQUAL(bytes, 64)
            `FAIL_UNLESS_EQUAL(qid, 12'h055)
            fork
                send_axis(64, 12'h02B);
                recv_c2h_dma(bytes, qid, err);
            join
            `FAIL_UNLESS_EQUAL(bytes, 64)
            `FAIL_UNLESS_EQUAL(qid, 12'h02B)
        `SVTEST_END

        // ---------------------------------------------------------------
        // Packet debug (capture / playback)
        // ---------------------------------------------------------------

        // Both blocks decode at their windows and report their parameterization.
        `SVTEST(debug_blocks_decode)
            int sz, meta_wid;
            h2c_capture.read_mem_size(sz);
            `FAIL_UNLESS_EQUAL(sz, DEBUG_MEM_SIZE)
            h2c_capture.read_meta_width(meta_wid);
            `FAIL_UNLESS_EQUAL(meta_wid, PKT_H2C_META_WID)
            c2h_playback.read_mem_size(sz);
            `FAIL_UNLESS_EQUAL(sz, DEBUG_MEM_SIZE)
            c2h_playback.read_meta_width(meta_wid);
            `FAIL_UNLESS_EQUAL(meta_wid, PKT_C2H_META_WID)
        `SVTEST_END

        // Disabled by default: neither block is in the datapath, so both
        // directions pass traffic with the debug blocks present and idle.
        `SVTEST(debug_isolated_by_default)
            int bytes;
            logic [QID_WID-1:0] qid;
            logic err;
            fork
                send_h2c(128, 12'h0D1);
                recv_axis(bytes, qid);
            join
            `FAIL_UNLESS_EQUAL(bytes, 128)
            `FAIL_UNLESS_EQUAL(qid, 12'h0D1)
            fork
                send_axis(128, 12'h0D2);
                recv_c2h_dma(bytes, qid, err);
            join
            `FAIL_UNLESS_EQUAL(bytes, 128)
            `FAIL_UNLESS_EQUAL(qid, 12'h0D2)
        `SVTEST_END

        // Capture enabled: the H2C packet lands in the capture buffer intact,
        // with the DMA engine's tcrc and qid in its meta, and the core sees
        // nothing.
        `SVTEST(capture_h2c_diverts_and_records)
            packet#(pkt_h2c_meta_t) cap;
            byte exp_data[];
            byte got_data[];
            pkt_h2c_meta_t exp_meta, got_meta;
            packet_raw#(pkt_h2c_meta_t) exp_pkt;
            localparam int BYTES = 200;
            localparam byte SEED = 8'h5A;

            exp_data = new[BYTES];
            for (int i = 0; i < BYTES; i++) exp_data[i] = SEED + i;
            exp_pkt = packet_raw#(pkt_h2c_meta_t)::create_from_bytes("exp", exp_data, '0, 1'b0);
            exp_meta.tcrc = exp_pkt.crc();
            exp_meta.qid  = QID_WID'(12'h2A5);

            set_capture_en(1'b1);
            fork
                send_h2c(BYTES, 12'h2A5, 1'b0, SEED);
                capture_h2c(cap);
                expect_idle_core(1024);
            join

            `FAIL_UNLESS_EQUAL(cap.size(), BYTES)
            got_data = cap.to_bytes();
            for (int i = 0; i < BYTES; i++)
                `FAIL_UNLESS_EQUAL(got_data[i], exp_data[i])
            got_meta = cap.get_meta();
            `FAIL_UNLESS_EQUAL(got_meta.tcrc, exp_meta.tcrc)
            `FAIL_UNLESS_EQUAL(got_meta.qid,  exp_meta.qid)
        `SVTEST_END

        // Capture sits ahead of the CRC check, so a packet with a wrong tcrc is
        // captured whole, with the wrong tcrc visible in the meta.
        `SVTEST(capture_h2c_records_bad_crc)
            packet#(pkt_h2c_meta_t) cap;
            byte exp_data[];
            packet_raw#(pkt_h2c_meta_t) exp_pkt;
            pkt_h2c_meta_t got_meta;
            localparam int BYTES = 100;

            exp_data = new[BYTES];
            for (int i = 0; i < BYTES; i++) exp_data[i] = 8'(i);
            exp_pkt = packet_raw#(pkt_h2c_meta_t)::create_from_bytes("exp", exp_data, '0, 1'b0);

            set_capture_en(1'b1);
            fork
                send_h2c_bad_crc(BYTES, 12'h003);
                capture_h2c(cap);
            join

            `FAIL_UNLESS_EQUAL(cap.size(), BYTES)
            got_meta = cap.get_meta();
            `FAIL_UNLESS_EQUAL(got_meta.tcrc, exp_pkt.crc() ^ 32'hFFFF_FFFF)
        `SVTEST_END

        // Clearing the capture enable restores the datapath.
        `SVTEST(capture_disable_restores_datapath)
            packet#(pkt_h2c_meta_t) cap;
            int bytes;
            logic [QID_WID-1:0] qid;
            set_capture_en(1'b1);
            fork
                send_h2c(64, 12'h011);
                capture_h2c(cap);
            join
            set_capture_en(1'b0);
            fork
                send_h2c(96, 12'h012);
                recv_axis(bytes, qid);
            join
            `FAIL_UNLESS_EQUAL(bytes, 96)
            `FAIL_UNLESS_EQUAL(qid, 12'h012)
        `SVTEST_END

        // Playback enabled: the injected packet reaches the DMA engine with
        // the data and the meta (size, tcrc, qid) programmed in the registers.
        `SVTEST(playback_c2h_injects)
            packet#(pkt_c2h_meta_t) rx;
            pkt_c2h_meta_t meta;
            byte got_data[];
            localparam int BYTES = 150;
            localparam byte SEED = 8'hC3;

            set_playback_en(1'b1);
            fork
                play_c2h(BYTES, 12'h5C3, 32'hDEAD_BEEF, SEED);
                c2h_dma_monitor.receive(rx);
            join

            `FAIL_UNLESS_EQUAL(rx.size(), BYTES)
            got_data = rx.to_bytes();
            for (int i = 0; i < BYTES; i++)
                `FAIL_UNLESS_EQUAL(got_data[i], byte'(SEED + i))
            meta = rx.get_meta();
            `FAIL_UNLESS_EQUAL(meta.size, 16'(BYTES))
            `FAIL_UNLESS_EQUAL(meta.tcrc, 32'hDEAD_BEEF)
            `FAIL_UNLESS_EQUAL(meta.qid,  QID_WID'(12'h5C3))
        `SVTEST_END

        // While playback is selected the datapath is held, not drained: a
        // packet sent from the core is delivered once playback is disabled.
        `SVTEST(playback_holds_datapath_until_disabled)
            int bytes;
            logic [QID_WID-1:0] qid;
            logic err;
            set_playback_en(1'b1);
            send_axis(128, 12'h0E1);
            expect_idle_dma(256);
            fork
                set_playback_en(1'b0);
                recv_c2h_dma(bytes, qid, err);
            join
            `FAIL_UNLESS_EQUAL(bytes, 128)
            `FAIL_UNLESS_EQUAL(qid, 12'h0E1)
        `SVTEST_END

        // The two enables are independent: playback on, capture off leaves
        // H2C on the datapath.
        `SVTEST(debug_enables_independent)
            int bytes;
            logic [QID_WID-1:0] qid;
            set_playback_en(1'b1);
            fork
                send_h2c(64, 12'h0F1);
                recv_axis(bytes, qid);
            join
            `FAIL_UNLESS_EQUAL(bytes, 64)
            `FAIL_UNLESS_EQUAL(qid, 12'h0F1)
        `SVTEST_END

        // ---------------------------------------------------------------
        // Packet counters
        // ---------------------------------------------------------------

        `SVTEST(counters_idle_zero)
            check_all_counts_zero();
        `SVTEST_END

        `SVTEST(counters_h2c_ok)
            localparam int PKTS      = 4;
            localparam int BYTES_PER = 192;
            int bytes;
            logic [QID_WID-1:0] qid;
            clear_all_counts();
            for (int i = 0; i < PKTS; i++) begin
                fork
                    send_h2c(BYTES_PER, 12'h011);
                    recv_axis(bytes, qid);
                join
            end
            settle_counts();
            check_counts(cnt_h2c_in,  "h2c_in",  PKTS, PKTS*BYTES_PER, 0, 0);
            check_counts(cnt_h2c_out, "h2c_out", PKTS, PKTS*BYTES_PER, 0, 0);
        `SVTEST_END

        // Bad-CRC packet is counted as errored at h2c_in, never reaches h2c_out.
        `SVTEST(counters_h2c_err)
            clear_all_counts();
            send_h2c_bad_crc(128, 12'h022);
            expect_idle_core(128);
            settle_counts();
            check_counts(cnt_h2c_in,  "h2c_in",  0, 0, 1, 128);
            check_counts(cnt_h2c_out, "h2c_out", 0, 0, 0, 0);
        `SVTEST_END

        `SVTEST(counters_c2h_ok)
            localparam int PKTS      = 3;
            localparam int BYTES_PER = 128;
            int bytes;
            logic [QID_WID-1:0] qid;
            logic err;
            clear_all_counts();
            for (int i = 0; i < PKTS; i++) begin
                fork
                    send_axis(BYTES_PER, 12'h033);
                    recv_c2h_dma(bytes, qid, err);
                join
            end
            settle_counts();
            check_counts(cnt_c2h_in,  "c2h_in",  PKTS, PKTS*BYTES_PER, 0, 0);
            check_counts(cnt_c2h_out, "c2h_out", PKTS, PKTS*BYTES_PER, 0, 0);
        `SVTEST_END

        `SVTEST(counters_loopback_tracks_reflected_traffic)
            localparam int BYTES = 128;
            int bytes;
            logic [QID_WID-1:0] qid;
            logic err;
            set_loopback(1'b1);
            clear_all_counts();
            fork
                send_h2c(BYTES, 12'h044);
                recv_c2h_dma(bytes, qid, err);
            join
            settle_counts();
            check_counts(cnt_h2c_in,  "h2c_in",  1, BYTES, 0, 0);
            check_counts(cnt_h2c_out, "h2c_out", 1, BYTES, 0, 0);
            check_counts(cnt_c2h_in,  "c2h_in",  1, BYTES, 0, 0);
            check_counts(cnt_c2h_out, "c2h_out", 1, BYTES, 0, 0);
        `SVTEST_END

        `SVTEST(counters_clear)
            longint unsigned pkts;
            int bytes;
            logic [QID_WID-1:0] qid;
            clear_all_counts();
            fork
                send_h2c(64, 12'h055);
                recv_axis(bytes, qid);
            join
            settle_counts();
            cnt_h2c_in.get_pkt_ok_count(pkts);
            `FAIL_UNLESS_EQUAL(pkts, 1)
            clear_all_counts();
            check_all_counts_zero();
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule : xilinx_alveo_qdma_st_unit_test
