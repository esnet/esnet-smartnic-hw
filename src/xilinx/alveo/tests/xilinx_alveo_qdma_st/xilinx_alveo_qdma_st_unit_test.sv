`include "svunit_defines.svh"

module xilinx_alveo_qdma_st_unit_test;
    import svunit_pkg::svunit_testcase;
    import xilinx_qdma_pkg::*;

    string name = "xilinx_alveo_qdma_st_ut";
    svunit_testcase svunit_ut;

    `define SVUNIT_TIMEOUT 500us

    localparam int QID_WID     = 12;
    localparam int MAX_PKT_LEN = 9100;

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

    packet_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .META_WID(QID_WID))
        pkt_h2c_dma  (.clk(aclk));      // TB drives  (QDMA domain)
    packet_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .META_WID(QID_WID))
        pkt_c2h_dma  (.clk(aclk));      // TB receives (QDMA domain)
    packet_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .META_WID(QID_WID))
        pkt_h2c_core (.clk(core_clk));  // TB receives (core domain)
    packet_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .META_WID(QID_WID))
        pkt_c2h_core (.clk(core_clk));  // TB drives  (core domain)

    packet_pkg::size_t pkt_c2h_dma_size;

    // Drive all TB-sourced interface signals from time 0 — the ASYNC FIFOs'
    // CDC logic hangs xsim if any DUT input is X before setup() runs.
    initial begin
        pkt_h2c_dma.vld  = 1'b0;
        pkt_h2c_dma.data = '0;
        pkt_h2c_dma.eop  = 1'b0;
        pkt_h2c_dma.mty  = '0;
        pkt_h2c_dma.err  = 1'b0;
        pkt_h2c_dma.meta = '0;
        pkt_c2h_core.vld  = 1'b0;
        pkt_c2h_core.data = '0;
        pkt_c2h_core.eop  = 1'b0;
        pkt_c2h_core.mty  = '0;
        pkt_c2h_core.err  = 1'b0;
        pkt_c2h_core.meta = '0;
        pkt_c2h_dma.rdy   = 1'b1;
        pkt_h2c_core.rdy  = 1'b1;
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
        .pkt_c2h_dma_size,
        .pkt_h2c_core,
        .pkt_c2h_core
    );

    // =========================================================================
    // Register agents
    // =========================================================================
    axi4l_verif_pkg::axi4l_reg_agent axil_reg_agent;
    packet_verif_pkg::packet_counters_reg_agent cnt_h2c_in;
    packet_verif_pkg::packet_counters_reg_agent cnt_h2c_out;
    packet_verif_pkg::packet_counters_reg_agent cnt_c2h_in;
    packet_verif_pkg::packet_counters_reg_agent cnt_c2h_out;

    function void build();
        svunit_ut = new(name);
        axil_reg_agent = new("axil_reg_agent");
        axil_reg_agent.axil_vif = axil_if;
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
        // Let the FIFO memory init and the CDC synchronisers settle
        repeat (32) @(posedge aclk);
        repeat (32) @(posedge core_clk);
    endtask

    task teardown();
        svunit_ut.teardown();
        idle();
    endtask

    task idle();
        axil_if.idle_controller();
        pkt_h2c_dma.idle_tx();
        pkt_c2h_core.idle_tx();
        pkt_c2h_dma.rdy  <= 1'b1;
        pkt_h2c_core.rdy <= 1'b1;
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

    // Set loopback mode and wait until the block reports it applied.
    task automatic set_loopback(input bit mode);
        bit [31:0] status;
        reg_write(qdma_reg_pkg::OFFSET_LOOPBACK_CONFIG, 32'(mode));
        forever begin
            reg_read(qdma_reg_pkg::OFFSET_LOOPBACK_STATUS, status);
            if (status[0] === mode && status[1] === 1'b0) break;
        end
    endtask

    // =========================================================================
    // Stimulus helpers
    // =========================================================================

    // Send a packet of num_bytes into one of the two input interfaces.
    // Data is deterministic from a seed so the far end can check it.
    task automatic send_pkt(
        virtual packet_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .META_WID(QID_WID)) vif,
        input int                 num_bytes,
        input logic [QID_WID-1:0] qid  = '0,
        input logic               err  = 1'b0,
        input byte                seed = 8'h00
    );
        int remaining = num_bytes;
        int idx = 0;
        logic [0:AXIS_DATA_BYTE_WID-1][7:0] beat;
        logic [5:0] mty;
        logic eop;
        while (remaining > 0) begin
            for (int b = 0; b < AXIS_DATA_BYTE_WID; b++) beat[b] = seed + idx + b;
            eop = (remaining <= AXIS_DATA_BYTE_WID);
            mty = eop ? 6'(AXIS_DATA_BYTE_WID - remaining) : 6'd0;
            vif.send(beat, eop, mty, eop ? err : 1'b0, qid);
            remaining -= AXIS_DATA_BYTE_WID;
            idx       += AXIS_DATA_BYTE_WID;
        end
    endtask

    // Receive one packet, returning its byte count, qid and err flag.
    task automatic recv_pkt(
        virtual packet_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .META_WID(QID_WID)) vif,
        output int                 num_bytes,
        output logic [QID_WID-1:0] qid,
        output logic               err
    );
        logic [0:AXIS_DATA_BYTE_WID-1][7:0] beat;
        logic [5:0] mty;
        logic eop;
        int beats = 0;
        num_bytes = 0;
        forever begin
            vif.receive(beat, eop, mty, err, qid);
            beats++;
            if (eop) break;
        end
        num_bytes = beats * AXIS_DATA_BYTE_WID - mty;
    endtask

    // Expect nothing on an output for the given number of cycles.
    task automatic expect_idle_core(input int cycles);
        repeat (cycles) begin
            @(posedge core_clk);
            `FAIL_IF_LOG(pkt_h2c_core.vld, "unexpected packet on pkt_h2c_core")
        end
    endtask

    task automatic expect_idle_dma(input int cycles);
        repeat (cycles) begin
            @(posedge aclk);
            `FAIL_IF_LOG(pkt_c2h_dma.vld, "unexpected packet on pkt_c2h_dma")
        end
    endtask

    // =========================================================================
    // Counter helpers
    //
    // The counters free-run (control.latch defaults to latch-on-clock), so a
    // plain read suffices once traffic has stopped.  settle_counts covers the
    // event-to-register pipeline and the AXI-L crossing into each block.
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

    task automatic check_pkt_counts(
        input packet_verif_pkg::packet_counters_reg_agent agent,
        input string                                      label,
        input longint unsigned                            exp_pkt_ok,
        input longint unsigned                            exp_pkt_err
    );
        longint unsigned pkt_ok, pkt_err;
        agent.get_pkt_ok_count(pkt_ok);
        agent.get_pkt_err_count(pkt_err);
        `FAIL_UNLESS_LOG(pkt_ok === exp_pkt_ok,
            $sformatf("%s: ok packet count %0d, expected %0d", label, pkt_ok, exp_pkt_ok))
        `FAIL_UNLESS_LOG(pkt_err === exp_pkt_err,
            $sformatf("%s: err packet count %0d, expected %0d", label, pkt_err, exp_pkt_err))
    endtask

    task automatic check_counts(
        input packet_verif_pkg::packet_counters_reg_agent agent,
        input string                                      label,
        input longint unsigned                            exp_pkt_ok,
        input longint unsigned                            exp_byte_ok,
        input longint unsigned                            exp_pkt_err,
        input longint unsigned                            exp_byte_err
    );
        longint unsigned byte_ok, byte_err;
        check_pkt_counts(agent, label, exp_pkt_ok, exp_pkt_err);
        agent.get_byte_ok_count(byte_ok);
        agent.get_byte_err_count(byte_err);
        `FAIL_UNLESS_LOG(byte_ok === exp_byte_ok,
            $sformatf("%s: ok byte count %0d, expected %0d", label, byte_ok, exp_byte_ok))
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
        // Datapath: the FIFOs carry packets across the clock boundary
        // ---------------------------------------------------------------

        // H2C crosses from the QDMA domain to the core domain intact.
        `SVTEST(h2c_crosses_to_core)
            int bytes;
            logic [QID_WID-1:0] qid;
            logic err;
            fork
                send_pkt(pkt_h2c_dma, 192, 12'h123);
                recv_pkt(pkt_h2c_core, bytes, qid, err);
            join
            `FAIL_UNLESS_EQUAL(bytes, 192);
            `FAIL_UNLESS_EQUAL(qid, 12'h123);
            `FAIL_UNLESS_EQUAL(err, 1'b0);
        `SVTEST_END

        // C2H crosses from the core domain back to the QDMA domain, and the
        // length is published for the adapter.
        `SVTEST(c2h_crosses_to_dma_with_size)
            int bytes;
            logic [QID_WID-1:0] qid;
            logic err;
            logic [15:0] size_at_sop;
            fork
                send_pkt(pkt_c2h_core, 100, 12'h0AB);
                begin
                    @(posedge aclk iff (pkt_c2h_dma.vld && pkt_c2h_dma.rdy));
                    size_at_sop = pkt_c2h_dma_size;
                end
            join
            // Length must be valid from the first beat — QDMA needs it then.
            `FAIL_UNLESS_EQUAL(size_at_sop, 16'd100);
        `SVTEST_END

        // A partial final beat round-trips with the right byte count.
        `SVTEST(c2h_partial_beat_size)
            logic [15:0] size_at_sop;
            fork
                send_pkt(pkt_c2h_core, 37, 12'h7FF);
                begin
                    @(posedge aclk iff (pkt_c2h_dma.vld && pkt_c2h_dma.rdy));
                    size_at_sop = pkt_c2h_dma_size;
                end
            join
            `FAIL_UNLESS_EQUAL(size_at_sop, 16'd37);
        `SVTEST_END

        // The H2C FIFO drops errored packets rather than passing undefined
        // payload to the core (DROP_ERRORED=1).
        `SVTEST(h2c_errored_packet_dropped)
            send_pkt(pkt_h2c_dma, 128, 12'h001, 1'b1);
            expect_idle_core(128);
        `SVTEST_END

        // A dropped errored packet does not block the one behind it.
        `SVTEST(h2c_errored_does_not_block)
            int bytes;
            logic [QID_WID-1:0] qid;
            logic err;
            send_pkt(pkt_h2c_dma, 128, 12'h001, 1'b1);
            fork
                send_pkt(pkt_h2c_dma, 64, 12'h002);
                recv_pkt(pkt_h2c_core, bytes, qid, err);
            join
            `FAIL_UNLESS_EQUAL(bytes, 64);
            `FAIL_UNLESS_EQUAL(qid, 12'h002);
        `SVTEST_END

        // ---------------------------------------------------------------
        // Loopback
        // ---------------------------------------------------------------

        // Loopback is off out of reset and the register block reads back.
        `SVTEST(loopback_reg_defaults)
            bit [31:0] data;
            reg_read(qdma_reg_pkg::OFFSET_LOOPBACK_CONFIG, data);
            `FAIL_UNLESS_EQUAL(data[0], 1'b0);
            reg_read(qdma_reg_pkg::OFFSET_LOOPBACK_STATUS, data);
            `FAIL_UNLESS_EQUAL(data[0], 1'b0);   // not enabled
            `FAIL_UNLESS_EQUAL(data[1], 1'b0);   // not switching
        `SVTEST_END

        // Every register in the block's 16-byte window answers, so a CPM5
        // 16-byte read cannot straddle an unmapped offset.
        `SVTEST(loopback_reg_window_complete)
            bit [31:0] data;
            reg_read(qdma_reg_pkg::OFFSET_LOOPBACK_CONFIG, data);
            reg_read(qdma_reg_pkg::OFFSET_LOOPBACK_STATUS, data);
            reg_read(qdma_reg_pkg::OFFSET_RESERVED_0, data);
            `FAIL_UNLESS_EQUAL(data, 32'h0);
            reg_read(qdma_reg_pkg::OFFSET_RESERVED_1, data);
            `FAIL_UNLESS_EQUAL(data, 32'h0);
        `SVTEST_END

        // With loopback enabled, H2C comes back as C2H on the same queue
        // without the core being involved.
        `SVTEST(loopback_h2c_returns_as_c2h)
            int bytes;
            logic [QID_WID-1:0] qid;
            logic err;
            set_loopback(1'b1);
            fork
                send_pkt(pkt_h2c_dma, 128, 12'h0C5);
                recv_pkt(pkt_c2h_dma, bytes, qid, err);
            join
            `FAIL_UNLESS_EQUAL(bytes, 128);
            `FAIL_UNLESS_EQUAL(qid, 12'h0C5);
        `SVTEST_END

        // While looped back the core sees no H2C traffic.
        `SVTEST(loopback_core_h2c_idle)
            int bytes;
            logic [QID_WID-1:0] qid;
            logic err;
            set_loopback(1'b1);
            fork
                send_pkt(pkt_h2c_dma, 128, 12'h00C);
                recv_pkt(pkt_c2h_dma, bytes, qid, err);
                expect_idle_core(192);
            join
            `FAIL_UNLESS_EQUAL(qid, 12'h00C);
        `SVTEST_END

        // While looped back, C2H from the core is discarded, not forwarded.
        `SVTEST(loopback_core_c2h_discarded)
            set_loopback(1'b1);
            send_pkt(pkt_c2h_core, 128, 12'h07F);
            expect_idle_dma(192);
        `SVTEST_END

        // Disabling loopback restores normal routing in both directions.
        `SVTEST(loopback_disable_restores_normal)
            int bytes;
            logic [QID_WID-1:0] qid;
            logic err;
            set_loopback(1'b1);
            set_loopback(1'b0);
            fork
                send_pkt(pkt_h2c_dma, 64, 12'h055);
                recv_pkt(pkt_h2c_core, bytes, qid, err);
            join
            `FAIL_UNLESS_EQUAL(bytes, 64);
            `FAIL_UNLESS_EQUAL(qid, 12'h055);
            fork
                send_pkt(pkt_c2h_core, 64, 12'h02B);
                recv_pkt(pkt_c2h_dma, bytes, qid, err);
            join
            `FAIL_UNLESS_EQUAL(bytes, 64);
            `FAIL_UNLESS_EQUAL(qid, 12'h02B);
        `SVTEST_END

        // ---------------------------------------------------------------
        // Packet counters
        // ---------------------------------------------------------------

        // All four blocks read zero out of reset, which also proves each
        // decodes at its own sub-address.
        `SVTEST(counters_idle_zero)
            check_all_counts_zero();
        `SVTEST_END

        // Good H2C traffic is counted on both sides of the H2C FIFO.
        `SVTEST(counters_h2c_ok)
            localparam int PKTS  = 4;
            localparam int BYTES_PER = 192;
            int bytes;
            logic [QID_WID-1:0] qid;
            logic err;
            clear_all_counts();
            for (int i = 0; i < PKTS; i++) begin
                fork
                    send_pkt(pkt_h2c_dma, BYTES_PER, 12'h011);
                    recv_pkt(pkt_h2c_core, bytes, qid, err);
                join
            end
            settle_counts();
            check_counts(cnt_h2c_in,  "h2c_in",  PKTS, PKTS*BYTES_PER, 0, 0);
            check_counts(cnt_h2c_out, "h2c_out", PKTS, PKTS*BYTES_PER, 0, 0);
        `SVTEST_END

        // An errored H2C packet lands in the error bin on the way in and,
        // since the FIFO drops it, never appears on the way out.
        `SVTEST(counters_h2c_err)
            clear_all_counts();
            send_pkt(pkt_h2c_dma, 128, 12'h022, 1'b1);
            expect_idle_core(128);
            settle_counts();
            check_counts(cnt_h2c_in,  "h2c_in",  0, 0, 1, 128);
            check_counts(cnt_h2c_out, "h2c_out", 0, 0, 0, 0);
        `SVTEST_END

        // Good C2H traffic from the core is counted on both sides.
        `SVTEST(counters_c2h_ok)
            localparam int PKTS = 3;
            localparam int BYTES_PER = 128;
            int bytes;
            logic [QID_WID-1:0] qid;
            logic err;
            clear_all_counts();
            for (int i = 0; i < PKTS; i++) begin
                fork
                    send_pkt(pkt_c2h_core, BYTES_PER, 12'h033);
                    recv_pkt(pkt_c2h_dma, bytes, qid, err);
                join
            end
            settle_counts();
            check_counts(cnt_c2h_in,  "c2h_in",  PKTS, PKTS*BYTES_PER, 0, 0);
            check_counts(cnt_c2h_out, "c2h_out", PKTS, PKTS*BYTES_PER, 0, 0);
        `SVTEST_END

        // Under loopback the reflected traffic enters the C2H FIFO, so the
        // C2H counters move even though the core sent nothing.  All four
        // taps count: both are on the FIFOs, which sit either side of the
        // loopback switch, so h2c_out still sees the packet leave the H2C
        // FIFO even though it is reflected rather than passed to the core.
        `SVTEST(counters_loopback_tracks_reflected_traffic)
            localparam int BYTES = 128;
            int bytes;
            logic [QID_WID-1:0] qid;
            logic err;
            set_loopback(1'b1);
            clear_all_counts();
            fork
                send_pkt(pkt_h2c_dma, BYTES, 12'h044);
                recv_pkt(pkt_c2h_dma, bytes, qid, err);
            join
            settle_counts();
            check_counts(cnt_h2c_in,  "h2c_in",  1, BYTES, 0, 0);
            check_counts(cnt_h2c_out, "h2c_out", 1, BYTES, 0, 0);
            check_counts(cnt_c2h_in,  "c2h_in",  1, BYTES, 0, 0);
            check_counts(cnt_c2h_out, "c2h_out", 1, BYTES, 0, 0);
        `SVTEST_END

        // Writing control.clear returns every counter to zero.
        `SVTEST(counters_clear)
            longint unsigned pkts;
            int bytes;
            logic [QID_WID-1:0] qid;
            logic err;
            clear_all_counts();
            fork
                send_pkt(pkt_h2c_dma, 64, 12'h055);
                recv_pkt(pkt_h2c_core, bytes, qid, err);
            join
            settle_counts();
            cnt_h2c_in.get_pkt_ok_count(pkts);
            `FAIL_UNLESS_EQUAL(pkts, 1);
            clear_all_counts();
            check_all_counts_zero();
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule : xilinx_alveo_qdma_st_unit_test
