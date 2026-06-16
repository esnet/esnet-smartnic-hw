`include "svunit_defines.svh"

module xilinx_aved_adapter_unit_test;
    import svunit_pkg::svunit_testcase;
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
    // Interfaces
    //
    //   axil_if     — testbench drives flat M_AXI_USR_MGMT signals into adapter
    //   axil_app_if — adapter output (controller) wired to shell peripheral input
    // =========================================================================
    axi4l_intf axil_if     ();
    axi4l_intf axil_app_if ();
    shell_intf shell_if    ();

    // =========================================================================
    // PCIE0 clock/reset — adapter needs these; tie to the management clock and
    // assert/deassert with the management reset since they are unused by this
    // test (PCIE0 BAR2 path is not exercised here).
    // =========================================================================
    logic clk_pcie0        = 1'b0;
    logic aresetn_pl0      = 1'b0;
    logic aresetn_pcie0_link = 1'b0;

    always @(posedge axil_if.aclk) clk_pcie0 <= ~clk_pcie0;

    wire pcie_rstn_in;  // adapter output → shell input (pre-JTAG combined reset)
    wire pcie_rstn;     // shell output → adapter input (post-JTAG reset)

    // =========================================================================
    // DUT chain:
    //   axil_if (flat signals) -> xilinx_aved_adapter -> axil_app_if
    //   -> xilinx_alveo_versal_shell -> shell_if -> core
    // =========================================================================
    xilinx_aved_adapter DUT_adapter (
        // Clocks and resets
        .clk_pl                   ( axil_if.aclk           ),
        .resetn_pl_periph         ( axil_if.aresetn         ),
        .clk_pcie0                ( clk_pcie0               ),
        .aresetn_pl0              ( aresetn_pl0             ),
        .aresetn_pcie0_link       ( aresetn_pcie0_link      ),
        // Shell-facing clock/reset
        .sys_clk                  (                         ),
        .pcie_clk                 (                         ),
        .pcie_rstn_in             ( pcie_rstn_in            ),
        .pcie_rstn                ( pcie_rstn               ),
        .resetn_pcie0             (                         ),
        // PCIE1 management AXI4-Lite
        .m_axi_usr_mgmt_awaddr    ( axil_if.awaddr          ),
        .m_axi_usr_mgmt_awprot    ( axil_if.awprot          ),
        .m_axi_usr_mgmt_awvalid   ( axil_if.awvalid         ),
        .m_axi_usr_mgmt_awready   ( axil_if.awready         ),
        .m_axi_usr_mgmt_wdata     ( axil_if.wdata           ),
        .m_axi_usr_mgmt_wstrb     ( axil_if.wstrb           ),
        .m_axi_usr_mgmt_wvalid    ( axil_if.wvalid          ),
        .m_axi_usr_mgmt_wready    ( axil_if.wready          ),
        .m_axi_usr_mgmt_bresp     ( axil_if.bresp           ),
        .m_axi_usr_mgmt_bvalid    ( axil_if.bvalid          ),
        .m_axi_usr_mgmt_bready    ( axil_if.bready          ),
        .m_axi_usr_mgmt_araddr    ( axil_if.araddr          ),
        .m_axi_usr_mgmt_arprot    ( axil_if.arprot          ),
        .m_axi_usr_mgmt_arvalid   ( axil_if.arvalid         ),
        .m_axi_usr_mgmt_arready   ( axil_if.arready         ),
        .m_axi_usr_mgmt_rdata     ( axil_if.rdata           ),
        .m_axi_usr_mgmt_rresp     ( axil_if.rresp           ),
        .m_axi_usr_mgmt_rvalid    ( axil_if.rvalid          ),
        .m_axi_usr_mgmt_rready    ( axil_if.rready          ),
        // PCIE0 BAR2 AXI4 (512-bit) — not exercised; tie inputs to 0
        .m_axi_pcie0_awaddr       ( '0 ),
        .m_axi_pcie0_awid         ( '0 ),
        .m_axi_pcie0_awlen        ( '0 ),
        .m_axi_pcie0_awsize       ( '0 ),
        .m_axi_pcie0_awburst      ( '0 ),
        .m_axi_pcie0_awlock       ( '0 ),
        .m_axi_pcie0_awcache      ( '0 ),
        .m_axi_pcie0_awprot       ( '0 ),
        .m_axi_pcie0_awqos        ( '0 ),
        .m_axi_pcie0_awregion     ( '0 ),
        .m_axi_pcie0_awuser       ( '0 ),
        .m_axi_pcie0_awvalid      ( '0 ),
        .m_axi_pcie0_awready      (    ),
        .m_axi_pcie0_wdata        ( '0 ),
        .m_axi_pcie0_wstrb        ( '0 ),
        .m_axi_pcie0_wlast        ( '0 ),
        .m_axi_pcie0_wvalid       ( '0 ),
        .m_axi_pcie0_wready       (    ),
        .m_axi_pcie0_bid          (    ),
        .m_axi_pcie0_bresp        (    ),
        .m_axi_pcie0_bvalid       (    ),
        .m_axi_pcie0_bready       ( '0 ),
        .m_axi_pcie0_araddr       ( '0 ),
        .m_axi_pcie0_arid         ( '0 ),
        .m_axi_pcie0_arlen        ( '0 ),
        .m_axi_pcie0_arsize       ( '0 ),
        .m_axi_pcie0_arburst      ( '0 ),
        .m_axi_pcie0_arlock       ( '0 ),
        .m_axi_pcie0_arcache      ( '0 ),
        .m_axi_pcie0_arprot       ( '0 ),
        .m_axi_pcie0_arqos        ( '0 ),
        .m_axi_pcie0_arregion     ( '0 ),
        .m_axi_pcie0_aruser       ( '0 ),
        .m_axi_pcie0_arvalid      ( '0 ),
        .m_axi_pcie0_arready      (    ),
        .m_axi_pcie0_rdata        (    ),
        .m_axi_pcie0_rid          (    ),
        .m_axi_pcie0_rresp        (    ),
        .m_axi_pcie0_rlast        (    ),
        .m_axi_pcie0_rvalid       (    ),
        .m_axi_pcie0_rready       ( '0 ),
        // PCIE0 H2C stream — not exercised
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
        // PCIE0 C2H stream — not exercised
        .dma0_s_axis_c2h_0_tvalid       (    ),
        .dma0_s_axis_c2h_0_tdata        (    ),
        .dma0_s_axis_c2h_0_tlast        (    ),
        .dma0_s_axis_c2h_0_tready       ( '0 ),
        .dma0_s_axis_c2h_0_ctrl_qid     (    ),
        .dma0_s_axis_c2h_0_ctrl_len     (    ),
        .dma0_s_axis_c2h_0_ctrl_port_id (    ),
        .dma0_s_axis_c2h_0_ctrl_has_cmpt(    ),
        .dma0_s_axis_c2h_0_ctrl_marker  (    ),
        .dma0_s_axis_c2h_0_mty          (    ),
        .dma0_s_axis_c2h_0_ecc          (    ),
        .dma0_s_axis_c2h_0_tcrc         (    ),
        // PCIE0 C2H completion — not exercised
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
        // PCIE0 descriptor credit — not exercised
        .dma0_dsc_crdt_in_0_crdt   (    ),
        .dma0_dsc_crdt_in_0_dir    (    ),
        .dma0_dsc_crdt_in_0_fence  (    ),
        .dma0_dsc_crdt_in_0_qid    (    ),
        .dma0_dsc_crdt_in_0_valid  (    ),
        .dma0_dsc_crdt_in_0_rdy    ( '0 ),
        // PCIE0 queue status — not exercised
        .dma0_qsts_out_0_data      ( '0 ),
        .dma0_qsts_out_0_op        ( '0 ),
        .dma0_qsts_out_0_port_id   ( '0 ),
        .dma0_qsts_out_0_qid       ( '0 ),
        .dma0_qsts_out_0_vld       ( '0 ),
        .dma0_qsts_out_0_rdy       (    ),
        // PCIE0 TM descriptor status — not exercised
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
        // PCIE0 user interrupt — not exercised
        .dma0_usr_irq_0_vec   (    ),
        .dma0_usr_irq_0_fnc   (    ),
        .dma0_usr_irq_0_valid (    ),
        .dma0_usr_irq_0_ack   ( '0 ),
        .dma0_usr_irq_0_fail  ( '0 ),
        // PCIE0 FLR — not exercised
        .dma0_usr_flr_0_fnc      ( '0 ),
        .dma0_usr_flr_0_set      ( '0 ),
        .dma0_usr_flr_0_clear    (    ),
        .dma0_usr_flr_0_done_fnc (    ),
        .dma0_usr_flr_0_done_vld (    ),
        // AXI4-L controller output
        .axil_if                  ( axil_app_if             )
    );

    xilinx_alveo_versal_shell DUT_shell (
        .sys_clk      ( axil_if.aclk   ),
        .pcie_clk     ( clk_pcie0      ),
        .pcie_rstn_in ( pcie_rstn_in    ),
        .pcie_rstn    ( pcie_rstn      ),
        .axil_if      ( axil_app_if    ),
        .shell_if
    );

    core DUT_core (
        .shell_if
    );

    // =========================================================================
    // Clock  (100 MHz)
    // =========================================================================
    `SVUNIT_CLK_GEN(axil_if.aclk, 5ns);

    // =========================================================================
    // Build
    // =========================================================================
    function void build();
        svunit_ut = new(name);
    endfunction

    // =========================================================================
    // Setup / teardown
    // =========================================================================
    task setup();
        svunit_ut.setup();
        axil_if.idle_controller();
        axil_if.aresetn      = 1'b0;
        aresetn_pl0          = 1'b0;
        aresetn_pcie0_link   = 1'b0;
        repeat (8) @(posedge axil_if.aclk);
        axil_if.aresetn      = 1'b1;
        aresetn_pl0          = 1'b1;
        aresetn_pcie0_link   = 1'b1;
        repeat (4) @(posedge axil_if.aclk);
    endtask

    task teardown();
        svunit_ut.teardown();
    endtask

    // =========================================================================
    // Helpers
    // =========================================================================
    task automatic axil_write(input bit [31:0] addr, input bit [31:0] data);
        axi4l_pkg::resp_t resp;
        bit timeout;
        axil_if.write(addr, data, resp, timeout);
        `FAIL_UNLESS_EQUAL(timeout, 1'b0);
        `FAIL_UNLESS_EQUAL(resp.encoded, axi4l_pkg::RESP_OKAY);
    endtask

    task automatic axil_read(input bit [31:0] addr, output bit [31:0] data);
        axi4l_pkg::resp_t resp;
        bit timeout;
        axil_if.read(addr, data, resp, timeout);
        `FAIL_UNLESS_EQUAL(timeout, 1'b0);
        `FAIL_UNLESS_EQUAL(resp.encoded, axi4l_pkg::RESP_OKAY);
    endtask

    // =========================================================================
    // Tests
    // =========================================================================
    `SVUNIT_TESTS_BEGIN

        // Verify the id register returns the 'CORE' sentinel value.
        `SVTEST(id_read)
            bit [31:0] rdata;
            axil_read(ADDR_ID, rdata);
            `FAIL_UNLESS_EQUAL(rdata, ID_EXPECTED);
        `SVTEST_END

        // Verify the scratchpad register round-trips a written value.
        `SVTEST(scratchpad_write_read)
            bit [31:0] rdata;
            axil_write(ADDR_SCRATCHPAD, 32'hDEAD_BEEF);
            axil_read(ADDR_SCRATCHPAD, rdata);
            `FAIL_UNLESS_EQUAL(rdata, 32'hDEAD_BEEF);
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
