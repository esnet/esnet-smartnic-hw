`include "svunit_defines.svh"

module xilinx_aved_adapter_unit_test;
    import svunit_pkg::svunit_testcase;
    import axi4_verif_pkg::*;
    import axi4_pkg::*;
    import axi4l_pkg::*;

    string name = "xilinx_aved_adapter_ut";
    svunit_testcase svunit_ut;

    `define SVUNIT_TIMEOUT 1ms

    // =========================================================================
    // Register offsets (core.stub.regio/core.yaml)
    // =========================================================================
    localparam bit [31:0] ADDR_ID         = 32'h0;
    localparam bit [31:0] ADDR_SCRATCHPAD = 32'h4;
    localparam bit [31:0] ID_EXPECTED     = 32'h434F5245;  // 'CORE'

    // =========================================================================
    // Clocks and resets
    //
    //   clk_pl0_100mhz    — system clock (100 MHz); drives adapter clk_pl0_100mhz and axil_app_if
    //   m_axi_pcie0_aclk — PCIe interface clock (250 MHz); drives the AXI4 master port
    //
    // arstn and m_axi_pcie0_aresetn are asserted together with clk_pl0_100mhz
    // reset so that pci_rstn_in de-asserts at the same time.
    // =========================================================================
    logic clk_pl0_100mhz             = 1'b0;
    logic m_axi_pcie0_aclk          = 1'b0;
    logic rstn_pl0_100mhz   = 1'b0;
    logic arstn        = 1'b0;
    logic m_axi_pcie0_aresetn = 1'b0;

    `SVUNIT_CLK_GEN(clk_pl0_100mhz,    5ns);   // 100 MHz
    `SVUNIT_CLK_GEN(m_axi_pcie0_aclk, 2ns);   // 250 MHz

    // =========================================================================
    // AXI4 interface — controller side; drives m_axi_pcie0_* flat ports.
    // Parameterised to match xilinx_aved_adapter's 512-bit / 64-bit-addr port.
    // =========================================================================
    axi4_intf #(
        .DATA_BYTE_WID ( 64 ),
        .ADDR_WID      ( 64 ),
        .ID_WID        ( 2  ),
        .USER_WID      ( 18 )
    ) pcie0_axi4_if (.aclk(m_axi_pcie0_aclk));

    // =========================================================================
    // Shell and core interfaces
    // =========================================================================
    axi4l_intf axil_app_if ();
    shell_intf shell_if    ();

    wire pci_rstn_in;
    wire pci_rstn;

    // =========================================================================
    // DUT chain:
    //   pcie0_axi4_if (flat signals) -> xilinx_aved_adapter -> axil_app_if
    //   -> xilinx_alveo_versal_shell -> shell_if -> core
    // =========================================================================
    xilinx_aved_adapter DUT_adapter (
        // Clocks and resets
        .clk_pl0_100mhz                   ( clk_pl0_100mhz             ),
        .m_axi_pcie0_aclk                ( m_axi_pcie0_aclk          ),
        .rstn_pl0_100mhz         ( rstn_pl0_100mhz   ),
        .arstn              ( arstn        ),
        .m_axi_pcie0_aresetn       ( m_axi_pcie0_aresetn ),
        // Shell-facing clock/reset
        .sys_clk                  (                    ),
        .pcie_clk                 (                    ),
        .pci_rstn_in              ( pci_rstn_in        ),
        .pci_rstn                 ( pci_rstn           ),
        .dma0_intrfc_aresetn             (                    ),
        // PCIE0 BAR2 AXI4 (512-bit) — driven from pcie0_axi4_if
        .m_axi_pcie0_awaddr       ( pcie0_axi4_if.awaddr    ),
        .m_axi_pcie0_awid         ( pcie0_axi4_if.awid      ),
        .m_axi_pcie0_awlen        ( pcie0_axi4_if.awlen     ),
        .m_axi_pcie0_awsize       ( pcie0_axi4_if.awsize    ),
        .m_axi_pcie0_awburst      ( pcie0_axi4_if.awburst   ),
        .m_axi_pcie0_awlock       ( pcie0_axi4_if.awlock    ),
        .m_axi_pcie0_awcache      ( pcie0_axi4_if.awcache   ),
        .m_axi_pcie0_awprot       ( pcie0_axi4_if.awprot    ),
        .m_axi_pcie0_awqos        ( pcie0_axi4_if.awqos     ),
        .m_axi_pcie0_awregion     ( pcie0_axi4_if.awregion  ),
        .m_axi_pcie0_awuser       ( pcie0_axi4_if.awuser    ),
        .m_axi_pcie0_awvalid      ( pcie0_axi4_if.awvalid   ),
        .m_axi_pcie0_awready      ( pcie0_axi4_if.awready   ),
        .m_axi_pcie0_wdata        ( pcie0_axi4_if.wdata     ),
        .m_axi_pcie0_wstrb        ( pcie0_axi4_if.wstrb     ),
        .m_axi_pcie0_wlast        ( pcie0_axi4_if.wlast     ),
        .m_axi_pcie0_wvalid       ( pcie0_axi4_if.wvalid    ),
        .m_axi_pcie0_wready       ( pcie0_axi4_if.wready    ),
        .m_axi_pcie0_bid          ( pcie0_axi4_if.bid       ),
        .m_axi_pcie0_bresp        ( pcie0_axi4_if.bresp     ),
        .m_axi_pcie0_bvalid       ( pcie0_axi4_if.bvalid    ),
        .m_axi_pcie0_bready       ( pcie0_axi4_if.bready    ),
        .m_axi_pcie0_araddr       ( pcie0_axi4_if.araddr    ),
        .m_axi_pcie0_arid         ( pcie0_axi4_if.arid      ),
        .m_axi_pcie0_arlen        ( pcie0_axi4_if.arlen     ),
        .m_axi_pcie0_arsize       ( pcie0_axi4_if.arsize    ),
        .m_axi_pcie0_arburst      ( pcie0_axi4_if.arburst   ),
        .m_axi_pcie0_arlock       ( pcie0_axi4_if.arlock    ),
        .m_axi_pcie0_arcache      ( pcie0_axi4_if.arcache   ),
        .m_axi_pcie0_arprot       ( pcie0_axi4_if.arprot    ),
        .m_axi_pcie0_arqos        ( pcie0_axi4_if.arqos     ),
        .m_axi_pcie0_arregion     ( pcie0_axi4_if.arregion  ),
        .m_axi_pcie0_aruser       ( pcie0_axi4_if.aruser    ),
        .m_axi_pcie0_arvalid      ( pcie0_axi4_if.arvalid   ),
        .m_axi_pcie0_arready      ( pcie0_axi4_if.arready   ),
        .m_axi_pcie0_rdata        ( pcie0_axi4_if.rdata     ),
        .m_axi_pcie0_rid          ( pcie0_axi4_if.rid       ),
        .m_axi_pcie0_rresp        ( pcie0_axi4_if.rresp     ),
        .m_axi_pcie0_rlast        ( pcie0_axi4_if.rlast     ),
        .m_axi_pcie0_rvalid       ( pcie0_axi4_if.rvalid    ),
        .m_axi_pcie0_rready       ( pcie0_axi4_if.rready    ),
        // PCIE0 DMA streams — not exercised
        .dma0_m_axis_h2c_0_tvalid    ( '0 ),
        .dma0_m_axis_h2c_0_tdata     ( '0 ),
        .dma0_m_axis_h2c_0_tlast     ( '0 ),
        .dma0_m_axis_h2c_0_tready    (    ),
        .dma0_m_axis_h2c_0_qid       ( '0 ),
        .dma0_m_axis_h2c_0_port_id   ( '0 ),
        .dma0_m_axis_h2c_0_mdata     ( '0 ),
        .dma0_m_axis_h2c_0_mty       ( '0 ),
        .dma0_m_axis_h2c_0_tcrc      ( '0 ),
        .dma0_m_axis_h2c_0_err       ( '0 ),
        .dma0_m_axis_h2c_0_zero_byte ( '0 ),
        .dma0_s_axis_c2h_0_tvalid        (    ),
        .dma0_s_axis_c2h_0_tdata         (    ),
        .dma0_s_axis_c2h_0_tlast         (    ),
        .dma0_s_axis_c2h_0_tready        ( '0 ),
        .dma0_s_axis_c2h_0_ctrl_qid      (    ),
        .dma0_s_axis_c2h_0_ctrl_len      (    ),
        .dma0_s_axis_c2h_0_ctrl_port_id  (    ),
        .dma0_s_axis_c2h_0_ctrl_has_cmpt (    ),
        .dma0_s_axis_c2h_0_ctrl_marker   (    ),
        .dma0_s_axis_c2h_0_mty           (    ),
        .dma0_s_axis_c2h_0_ecc           (    ),
        .dma0_s_axis_c2h_0_tcrc          (    ),
        .dma0_s_axis_c2h_cmpt_0_tvalid          (    ),
        .dma0_s_axis_c2h_cmpt_0_data            (    ),
        .dma0_s_axis_c2h_cmpt_0_size            (    ),
        .dma0_s_axis_c2h_cmpt_0_qid             (    ),
        .dma0_s_axis_c2h_cmpt_0_port_id         (    ),
        .dma0_s_axis_c2h_cmpt_0_cmpt_type       (    ),
        .dma0_s_axis_c2h_cmpt_0_wait_pld_pkt_id (    ),
        .dma0_s_axis_c2h_cmpt_0_dpar            (    ),
        .dma0_s_axis_c2h_cmpt_0_col_idx         (    ),
        .dma0_s_axis_c2h_cmpt_0_err_idx         (    ),
        .dma0_s_axis_c2h_cmpt_0_user_trig       (    ),
        .dma0_s_axis_c2h_cmpt_0_marker          (    ),
        .dma0_s_axis_c2h_cmpt_0_no_wrb_marker   (    ),
        .dma0_s_axis_c2h_cmpt_0_tready          ( '0 ),
        .dma0_dsc_crdt_in_0_crdt   (    ),
        .dma0_dsc_crdt_in_0_dir    (    ),
        .dma0_dsc_crdt_in_0_fence  (    ),
        .dma0_dsc_crdt_in_0_qid    (    ),
        .dma0_dsc_crdt_in_0_valid  (    ),
        .dma0_dsc_crdt_in_0_rdy    ( '0 ),
        .dma0_qsts_out_0_data      ( '0 ),
        .dma0_qsts_out_0_op        ( '0 ),
        .dma0_qsts_out_0_port_id   ( '0 ),
        .dma0_qsts_out_0_qid       ( '0 ),
        .dma0_qsts_out_0_vld       ( '0 ),
        .dma0_qsts_out_0_rdy       (    ),
        .dma0_tm_dsc_sts_0_avl     ( '0 ),
        .dma0_tm_dsc_sts_0_byp     ( '0 ),
        .dma0_tm_dsc_sts_0_dir     ( '0 ),
        .dma0_tm_dsc_sts_0_error   ( '0 ),
        .dma0_tm_dsc_sts_0_irq_arm ( '0 ),
        .dma0_tm_dsc_sts_0_mm      ( '0 ),
        .dma0_tm_dsc_sts_0_pidx    ( '0 ),
        .dma0_tm_dsc_sts_0_port_id ( '0 ),
        .dma0_tm_dsc_sts_0_qen     ( '0 ),
        .dma0_tm_dsc_sts_0_qid     ( '0 ),
        .dma0_tm_dsc_sts_0_qinv    ( '0 ),
        .dma0_tm_dsc_sts_0_rdy     (    ),
        .dma0_tm_dsc_sts_0_valid   ( '0 ),
        .dma0_usr_irq_0_vec        (    ),
        .dma0_usr_irq_0_fnc        (    ),
        .dma0_usr_irq_0_valid      (    ),
        .dma0_usr_irq_0_ack        ( '0 ),
        .dma0_usr_irq_0_fail       ( '0 ),
        .dma0_usr_flr_0_fnc        ( '0 ),
        .dma0_usr_flr_0_set        ( '0 ),
        .dma0_usr_flr_0_clear      (    ),
        .dma0_usr_flr_0_done_fnc   (    ),
        .dma0_usr_flr_0_done_vld   (    ),
        // AXI4-L controller output
        .axil_if                   ( axil_app_if )
    );

    xilinx_alveo_versal_shell DUT_shell (
        .sys_clk      ( clk_pl0_100mhz      ),
        .pcie_clk     ( m_axi_pcie0_aclk   ),
        .pci_rstn_in  ( pci_rstn_in ),
        .pci_rstn     ( pci_rstn    ),
        .axil_if      ( axil_app_if ),
        .shell_if
    );

    core DUT_core (
        .shell_if
    );

    // =========================================================================
    // AXI4 register agent — drives pcie0_axi4_if as a controller
    // =========================================================================
    axi4_reg_agent #(
        .DATA_BYTE_WID ( 64 ),
        .ADDR_WID      ( 64 ),
        .ID_WID        ( 2  ),
        .USER_WID      ( 18 )
    ) agent;

    // =========================================================================
    // Build
    // =========================================================================
    function void build();
        svunit_ut = new(name);
        agent = new();
        agent.axi4_vif = pcie0_axi4_if;
    endfunction

    // =========================================================================
    // Setup / teardown
    // =========================================================================
    task setup();
        svunit_ut.setup();
        agent.idle();
        rstn_pl0_100mhz   = 1'b0;
        arstn        = 1'b0;
        m_axi_pcie0_aresetn = 1'b0;
        repeat (8) @(posedge clk_pl0_100mhz);
        rstn_pl0_100mhz   = 1'b1;
        arstn        = 1'b1;
        m_axi_pcie0_aresetn = 1'b1;
        // Allow CDC and reset synchronisers to settle
        repeat (16) @(posedge clk_pl0_100mhz);
    endtask

    task teardown();
        svunit_ut.teardown();
    endtask

    // =========================================================================
    // Helpers
    //
    // axi4_reg_agent._write/_read use full-bus-width strobes, which is correct
    // for the axi4l_from_axi4_adapter (it extracts the lane from addr[5:2]).
    // =========================================================================
    task automatic axi4_write(input bit [31:0] addr, input bit [31:0] data);
        automatic int word_idx = addr[5:2];
        automatic bit [64-1:0][7:0] wdata = '0;
        automatic bit [64-1:0]      strb  = '0;
        automatic bit [1:0] resp;
        automatic bit       timeout;
        wdata[word_idx*4 +: 4] = data;
        strb[word_idx*4 +: 4]  = 4'hF;
        pcie0_axi4_if.write(64'(addr), wdata, strb, resp, timeout);
        `FAIL_IF_LOG(timeout, $sformatf("axi4_write to 0x%08x timed out", addr));
        `FAIL_UNLESS_LOG(resp === 2'b00,
            $sformatf("axi4_write to 0x%08x: expected OKAY, got 2'b%02b", addr, resp));
    endtask

    task automatic axi4_read(input bit [31:0] addr, output bit [31:0] data);
        automatic int word_idx = addr[5:2];
        automatic bit [64-1:0][7:0] rdata;
        automatic bit [1:0] resp;
        automatic bit       timeout;
        pcie0_axi4_if.read(64'(addr), rdata, resp, timeout);
        `FAIL_IF_LOG(timeout, $sformatf("axi4_read from 0x%08x timed out", addr));
        `FAIL_UNLESS_LOG(resp === 2'b00,
            $sformatf("axi4_read from 0x%08x: expected OKAY, got 2'b%02b", addr, resp));
        data = rdata[word_idx*4 +: 4];
    endtask

    // =========================================================================
    // Tests
    // =========================================================================
    `SVUNIT_TESTS_BEGIN

        // Verify the id register returns the 'CORE' sentinel value via PCIE0.
        `SVTEST(id_read)
            bit [31:0] rdata;
            axi4_read(ADDR_ID, rdata);
            `FAIL_UNLESS_EQUAL(rdata, ID_EXPECTED);
        `SVTEST_END

        // Verify the scratchpad register round-trips a written value via PCIE0.
        `SVTEST(scratchpad_write_read)
            bit [31:0] rdata;
            axi4_write(ADDR_SCRATCHPAD, 32'hDEAD_BEEF);
            axi4_read(ADDR_SCRATCHPAD, rdata);
            `FAIL_UNLESS_EQUAL(rdata, 32'hDEAD_BEEF);
        `SVTEST_END

        // Back-to-back reads: verify the CDC and axi4l_from_axi4_adapter pipeline
        // resets correctly between consecutive transactions.
        `SVTEST(back_to_back_reads)
            bit [31:0] rdata;
            axi4_write(ADDR_SCRATCHPAD, 32'hA5A5_A5A5);
            repeat (4) begin
                axi4_read(ADDR_ID, rdata);
                `FAIL_UNLESS_EQUAL(rdata, ID_EXPECTED);
                axi4_read(ADDR_SCRATCHPAD, rdata);
                `FAIL_UNLESS_EQUAL(rdata, 32'hA5A5_A5A5);
            end
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
