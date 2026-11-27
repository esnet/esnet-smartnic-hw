`include "svunit_defines.svh"

module xilinx_aved_adapter_unit_test;
    import svunit_pkg::svunit_testcase;
    import axi4_verif_pkg::*;
    import axi4_pkg::*;
    import axi4l_pkg::*;
    import xilinx_pci_verif_pkg::*;

    string name = "xilinx_aved_adapter_ut";
    svunit_testcase svunit_ut;

    `define SVUNIT_TIMEOUT 1ms

    // =========================================================================
    // Register offsets
    //
    // BAR2 is split by shell_decoder_core.yaml into shell_cfg at 0x000000, hw
    // at 0x200000 and core at 0x400000.  These reach core.stub's own registers
    // (core.stub.regio/core.yaml), so a passing read exercises the whole path
    // from PCIE0 BAR2 through the shell decoder down to the core.
    // =========================================================================
    localparam bit [31:0] CORE_BASE       = 32'h400000;
    localparam bit [31:0] ADDR_ID         = CORE_BASE + 32'h0;
    localparam bit [31:0] ADDR_SCRATCHPAD = CORE_BASE + 32'h4;
    localparam bit [31:0] ID_EXPECTED     = 32'h434F5245;  // 'CORE'

    // QDMA streaming adapter registers: hw sub-space (0x200000) + 0x000000.
    localparam bit [31:0] QDMA_BASE       = 32'h200000;
    localparam bit [31:0] ADDR_LB_CONFIG  = QDMA_BASE + 32'h0;
    localparam bit [31:0] ADDR_LB_STATUS  = QDMA_BASE + 32'h4;

    // Packet counter sub-blocks, per qdma_decoder.yaml.
    localparam bit [31:0] ADDR_H2C_IN_CNT  = QDMA_BASE + 32'h100;
    localparam bit [31:0] ADDR_H2C_OUT_CNT = QDMA_BASE + 32'h200;
    localparam bit [31:0] ADDR_C2H_IN_CNT  = QDMA_BASE + 32'h300;
    localparam bit [31:0] ADDR_C2H_OUT_CNT = QDMA_BASE + 32'h400;

    // Offsets within a packet_counters block.
    localparam bit [31:0] CNT_OFF_INFO       = 32'h00;
    localparam bit [31:0] CNT_OFF_PKT_OK_LO  = 32'h0C;

    // =========================================================================
    // Clocks and resets
    //
    //   clk_pl0_100mhz    — system clock (100 MHz); drives adapter clk_pl0_100mhz and axil_app_if
    //   m_axi_pcie0_aclk — PCIe interface clock (250 MHz); drives the AXI4 master port
    //
    // rstn_pl0_100mhz and m_axi_pcie0_aresetn are asserted together
    // reset so that pci_rstn_in de-asserts at the same time.
    // =========================================================================
    logic clk_pl0_100mhz     = 1'b0;
    logic m_axi_pcie0_aclk   = 1'b0;
    logic rstn_pl0_100mhz    = 1'b0;
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
    shell_intf shell_if ();
    xilinx_pci_cfg_ext_intf cfg_host_if (.clk(m_axi_pcie0_aclk));
    xilinx_pci_cfg_ext_intf cfg_ext_if (.clk(m_axi_pcie0_aclk));
    logic [7:0] cfg_function_hi = '0;
    xilinx_pci_cfg_ext_intf_agent cfg_agent;
    xilinx_pci_cfg_ext_vpd_agent vpd_agents[2];

    // DMA streams between adapter and shell, in the PCIE0 (QDMA) clock domain.
    // Meta widths match PKT_H2C_META_WID / PKT_C2H_META_WID from xilinx_qdma_pkg.
    packet_intf #(
        .DATA_BYTE_WID ( xilinx_qdma_pkg::AXIS_DATA_BYTE_WID ),
        .META_WID      ( xilinx_qdma_pkg::PKT_H2C_META_WID   )
    ) pkt_h2c_dma (.clk(m_axi_pcie0_aclk));

    packet_intf #(
        .DATA_BYTE_WID ( xilinx_qdma_pkg::AXIS_DATA_BYTE_WID ),
        .META_WID      ( xilinx_qdma_pkg::PKT_C2H_META_WID   )
    ) pkt_c2h_dma (.clk(m_axi_pcie0_aclk));

    wire pci_rstn_in;
    wire pci_rstn;

    // =========================================================================
    // DUT chain:
    //   pcie0_axi4_if (flat signals) -> xilinx_aved_adapter -> axil_app_if
    //   -> xilinx_alveo_versal_shell -> shell_if -> core
    // =========================================================================
    xilinx_aved_adapter DUT_adapter (
        .cfg_ext_if,
        .pcie0_cfg_ext_read_received     ( cfg_host_if.req && !cfg_host_if.wr_rd_n ),
        .pcie0_cfg_ext_write_received    ( cfg_host_if.req && cfg_host_if.wr_rd_n ),
        .pcie0_cfg_ext_register_number   ( cfg_host_if.register ),
        .pcie0_cfg_ext_function_number   ( {cfg_function_hi, cfg_host_if.func} ),
        .pcie0_cfg_ext_write_data        ( cfg_host_if.wr_data ),
        .pcie0_cfg_ext_write_byte_enable ( cfg_host_if.wr_byte_en ),
        .pcie0_cfg_ext_read_data         ( cfg_host_if.rd_data ),
        .pcie0_cfg_ext_read_data_valid   ( cfg_host_if.rd_vld ),
        // Clocks and resets
        .clk_pl0_100mhz                   ( clk_pl0_100mhz             ),
        .m_axi_pcie0_aclk                ( m_axi_pcie0_aclk          ),
        .rstn_pl0_100mhz          ( rstn_pl0_100mhz    ),
        .m_axi_pcie0_aresetn       ( m_axi_pcie0_aresetn ),
        // Shell-facing clock/reset
        .sys_clk_100mhz           (                    ),
        .pci_rstn_in              ( pci_rstn_in        ),
        .pci_rstn                 ( pci_rstn           ),
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
        .axil_if ( axil_app_if ),
        // DMA streams (PCIE0 clock domain; the shell owns the CDC)
        .pkt_h2c ( pkt_h2c_dma ),
        .pkt_c2h ( pkt_c2h_dma )
    );

    xilinx_alveo_versal_shell #(
        .APPLICATION_ID ( "test_shell" ),
        .BUILD_ID       ( 123 )
    ) DUT_shell (
        .cfg_ext_if,
        .sys_clk_100mhz ( clk_pl0_100mhz ),
        .pci_rstn_in    ( pci_rstn_in ),
        .pci_rstn       ( pci_rstn    ),
        .axil_top         ( axil_app_if       ),
        .dma_aclk         ( m_axi_pcie0_aclk  ),
        .dma_aresetn      ( m_axi_pcie0_aresetn ),
        .pkt_h2c_dma ( pkt_h2c_dma ),
        .pkt_c2h_dma ( pkt_c2h_dma ),
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
        cfg_agent = new();
        cfg_agent.pci_cfg_ext_vif = cfg_host_if;
        foreach (vpd_agents[i]) begin
            vpd_agents[i] = new($sformatf("pf%0d", i), i);
            vpd_agents[i].pci_cfg_ext_agent = cfg_agent;
        end
    endfunction

    // =========================================================================
    // Setup / teardown
    // =========================================================================
    task setup();
        svunit_ut.setup();
        agent.idle();
        cfg_agent.idle();
        cfg_function_hi = 0;
        rstn_pl0_100mhz    = 1'b0;
        m_axi_pcie0_aresetn = 1'b0;
        repeat (8) @(posedge clk_pl0_100mhz);
        rstn_pl0_100mhz    = 1'b1;
        m_axi_pcie0_aresetn = 1'b1;
        // Allow free-running VPD startup and CDC resets to settle.
        wait(DUT_shell.i_xilinx_alveo_shell.i_xilinx_alveo_vpd.init_done);
        repeat (64) @(negedge m_axi_pcie0_aclk);
    endtask

    task teardown();
        svunit_ut.teardown();
    endtask

    // =========================================================================
    // Helpers
    //
    // Use the agent's single-beat API to preserve the byte strobes and the
    // placement of each 32-bit register within the 512-bit AXI4 beat.
    // =========================================================================
    task automatic axi4_write(input bit [31:0] addr, input bit [31:0] data);
        automatic int word_idx = addr[5:2];
        automatic bit [64-1:0][7:0] wdata = '0;
        automatic bit [64-1:0]      strb  = '0;
        automatic bit [1:0] resp;
        automatic bit       timeout;
        wdata[word_idx*4 +: 4] = data;
        strb[word_idx*4 +: 4]  = 4'hF;
        agent.write(64'(addr), wdata, strb, resp, timeout);
        `FAIL_IF_LOG(timeout, $sformatf("axi4_write to 0x%08x timed out", addr));
        `FAIL_UNLESS_LOG(resp === 2'b00,
            $sformatf("axi4_write to 0x%08x: expected OKAY, got 2'b%02b", addr, resp));
    endtask

    task automatic axi4_read(input bit [31:0] addr, output bit [31:0] data);
        automatic int word_idx = addr[5:2];
        automatic bit [64-1:0][7:0] rdata;
        automatic bit [1:0] resp;
        automatic bit       timeout;
        agent.read(64'(addr), rdata, resp, timeout);
        `FAIL_IF_LOG(timeout, $sformatf("axi4_read from 0x%08x timed out", addr));
        `FAIL_UNLESS_LOG(resp === 2'b00,
            $sformatf("axi4_read from 0x%08x: expected OKAY, got 2'b%02b", addr, resp));
        data = rdata[word_idx*4 +: 4];
    endtask

    // =========================================================================
    // Tests
    // =========================================================================
    task check_vpd(input int pf);
        bit [31:0] data;
        bit error;
        bit timeout;
        byte value;
        cfg_agent.read('h2c, pf, data, error, timeout);
        `FAIL_IF(error || timeout);
        `FAIL_UNLESS_EQUAL(data[15:0], 16'h0003);
        vpd_agents[pf].read_byte(0, value);
        `FAIL_UNLESS_EQUAL(value, 8'h82);
        vpd_agents[pf].read_byte(3, value);
        `FAIL_UNLESS_EQUAL(value, 8'h45); // First product-name character: E
    endtask

    `SVUNIT_TESTS_BEGIN
        `SVTEST(alveo_shell_vpd_registers)
            bit [31:0] value;
            axi4_read(32'h1000, value);
            `FAIL_UNLESS_EQUAL(value, 0);
            axi4_read(32'h1004, value);
            `FAIL_UNLESS(value[0]);
            `FAIL_IF(value[1] || value[17]);
            axi4_read(32'h1008, value);
            `FAIL_UNLESS_EQUAL(value, 0);
            axi4_write(32'h1000, 1);
            repeat (64) @(negedge clk_pl0_100mhz);
            `FAIL_IF(DUT_shell.i_xilinx_alveo_shell.vpd_ready);
            axi4_read(32'h1004, value);
            `FAIL_IF(value[0]);
            axi4_write(32'h1000, 0);
            repeat (64) @(negedge clk_pl0_100mhz);
            `FAIL_UNLESS(DUT_shell.i_xilinx_alveo_shell.vpd_ready);
        `SVTEST_END

        `SVTEST(vpd_both_pfs)
            check_vpd(0);
            check_vpd(1);
        `SVTEST_END

        `SVTEST(vpd_initialization_with_pcie_held_in_reset)
            m_axi_pcie0_aresetn = 0;
            wait(DUT_shell.i_xilinx_alveo_shell.i_xilinx_alveo_vpd.init_done);
            `FAIL_UNLESS(DUT_shell.i_xilinx_alveo_shell.i_xilinx_alveo_vpd.init_done);
            `FAIL_IF(m_axi_pcie0_aresetn);
            @(negedge m_axi_pcie0_aclk);
            m_axi_pcie0_aresetn = 1;
            repeat (64) @(negedge clk_pl0_100mhz);
            check_vpd(0);
            check_vpd(1);
        `SVTEST_END

        `SVTEST(vpd_wide_function_does_not_alias_pf)
            bit [31:0] data;
            bit error;
            bit timeout;
            foreach (vpd_agents[pf]) begin
                cfg_agent.write('h2d, pf, 32'h12345678, error, timeout);
                `FAIL_IF(error || timeout);
                cfg_function_hi = 1;
                cfg_agent.read('h2c, pf, data, error, timeout);
                `FAIL_IF(error || timeout);
                `FAIL_UNLESS_EQUAL(data, 0);
                cfg_agent.write('h2d, pf, 32'hdeadbeef, error, timeout);
                `FAIL_IF(error || timeout);
                cfg_function_hi = 0;
                cfg_agent.read('h2d, pf, data, error, timeout);
                `FAIL_IF(error || timeout);
                `FAIL_UNLESS_EQUAL(data, 32'h12345678);
                check_vpd(pf);
            end
            cfg_function_hi = '1;
            cfg_agent.read('h2c, 'hff, data, error, timeout);
            `FAIL_IF(error || timeout);
            `FAIL_UNLESS_EQUAL(data, 0);
        `SVTEST_END


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

        // The QDMA adapter's loopback registers are reachable from PCIE0 BAR2
        // through the shell's hw decoder and back down into the adapter, and
        // the requested mode is applied across the management/core crossing.
        `SVTEST(qdma_loopback_register_path)
            bit [31:0] rdata;
            axi4_read(ADDR_LB_STATUS, rdata);
            `FAIL_UNLESS_EQUAL(rdata[0], 1'b0);   // not enabled out of reset

            axi4_write(ADDR_LB_CONFIG, 32'h1);
            axi4_read(ADDR_LB_CONFIG, rdata);
            `FAIL_UNLESS_EQUAL(rdata[0], 1'b1);

            // The enable crosses to the core domain and the status crosses
            // back, so the applied mode lags the request.
            for (int i = 0; i < 100; i++) begin
                axi4_read(ADDR_LB_STATUS, rdata);
                if (rdata[0] === 1'b1 && rdata[1] === 1'b0) break;
            end
            `FAIL_UNLESS_EQUAL(rdata[0], 1'b1);   // enabled
            `FAIL_UNLESS_EQUAL(rdata[1], 1'b0);   // no longer switching
        `SVTEST_END

        // Each packet counter block decodes at its own sub-address over the
        // real route from PCIE0. The info register is non-zero (it reports the
        // counter widths), which distinguishes a decoded block from a read
        // that fell through to unmapped space.
        `SVTEST(qdma_counter_blocks_decode)
            bit [31:0] info;
            bit [31:0] bases [4];
            bases = '{ADDR_H2C_IN_CNT, ADDR_H2C_OUT_CNT, ADDR_C2H_IN_CNT, ADDR_C2H_OUT_CNT};
            foreach (bases[i]) begin
                bit [31:0] pkt_ok;
                axi4_read(bases[i] + CNT_OFF_INFO, info);
                `FAIL_UNLESS(info !== 32'h0);
                // Counts start at zero: no DMA traffic has run in this test.
                axi4_read(bases[i] + CNT_OFF_PKT_OK_LO, pkt_ok);
                `FAIL_UNLESS_EQUAL(pkt_ok, 32'h0);
            end
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
