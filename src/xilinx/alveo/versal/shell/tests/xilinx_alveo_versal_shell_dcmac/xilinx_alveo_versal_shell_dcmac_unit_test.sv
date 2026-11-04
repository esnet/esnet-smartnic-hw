`include "svunit_defines.svh"

module xilinx_alveo_versal_shell_dcmac_unit_test;
    import svunit_pkg::svunit_testcase;
    import axi4l_pkg::*;
    import axi4s_verif_pkg::*;
    import packet_verif_pkg::*;
    import xilinx_qdma_pkg::*;
    import xilinx_alveo_versal_reg_verif_pkg::*;
    import xilinx_gtm_reg_verif_pkg::*;
    import smartnic_pkg::*;

    string name = "xilinx_alveo_versal_shell_dcmac_ut";
    svunit_testcase svunit_ut;

    `define SVUNIT_TIMEOUT 1ms

    // =========================================================================
    // Register offsets (core.stub.regio/core.yaml)
    // =========================================================================
    localparam bit [31:0] ADDR_ID         = 32'h400000;
    localparam bit [31:0] ADDR_SCRATCHPAD = 32'h4;
    localparam bit [31:0] ID_EXPECTED     = 32'hC0BEBEEF;  // 'smartnic'

    localparam PHY0    = 4'h0;
    localparam PHY1    = 4'h1;
    localparam PF0     = 4'h2;
    localparam PF1     = 4'h3;

    // =========================================================================
    // Interfaces
    //
    //   axil_if  — testbench drives management AXI4-L directly into the shell
    //   shell_if — shell output wired to core.stub
    // =========================================================================
    axi4l_intf axil_if  ();

    // DMA streams. The QDMA adapter is above the shell in the real design,
    // so these are terminated rather than driven.
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( PKT_H2C_META_WID   )
    ) pkt_h2c_dma (.clk(axil_if.aclk));

    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( PKT_C2H_META_WID   )
    ) pkt_c2h_dma (.clk(axil_if.aclk));

    shell_intf #(
        .DMA_ST_QUEUES ( xilinx_alveo_versal_pkg::DMA_ST_QUEUES )
    ) shell_if ();


    // =========================================================================
    // PCIe reset signals — shell needs these to synthesise pci_rstn.
    // Driven in lockstep with the management reset since no real PCIe link
    // is present in simulation.
    // =========================================================================
    logic pci_rstn_in = 1'b0;
    wire  pci_rstn;

    logic gt_ref_clk0_n, gt_ref_clk0_p;

    gtm_regs_reg_pkg::reg_ch0_fabric_intf_cfg1_t reg_ch0_fabric_intf_cfg1;

    // =========================================================================
    // DUT: xilinx_alveo_versal_shell
    //   axil_if drives the peripheral management port directly.
    //   core.stub is connected via shell_if.
    // =========================================================================
    xilinx_alveo_versal_shell DUT (
        .sys_clk_100mhz ( axil_if.aclk ),
        .pci_rstn_in ( pci_rstn_in  ),
        .pci_rstn    ( pci_rstn     ),
        .gt_ref_clk0_n ( gt_ref_clk0_n  ),
        .gt_ref_clk0_p ( gt_ref_clk0_p  ),
        .gt_rxp_in ('0),
        .gt_rxn_in ('0),
        .gt_txp_out (),
        .gt_txn_out (),
        .axil_top (axil_if),
        .dma_aclk         ( axil_if.aclk     ),
        .dma_aresetn      ( axil_if.aresetn  ),
        .pkt_h2c_dma      ( pkt_h2c_dma      ),
	.pkt_c2h_dma      ( pkt_c2h_dma      ),
        .shell_if (shell_if)
    );

    packet_intf_tx_term i_packet_intf_tx_term__h2c (.to_rx   (pkt_h2c_dma));
    packet_intf_rx_sink i_packet_intf_rx_sink__c2h (.from_tx (pkt_c2h_dma));

    core DUT_core (
        .shell_if
    );

    localparam int  DATA_BYTE_WID = 64;
    localparam type TID_IN_T      = port_t; //adpt_tx_tid_t;
    localparam type TDEST_IN_T    = port_t;
    localparam type TUSER_IN_T    = bit; // error
    localparam type TRANSACTION_IN_T  = axi4s_transaction#(TID_IN_T, TDEST_IN_T, TUSER_IN_T);

    axi4s_playback_driver#(DATA_BYTE_WID, port_t, TDEST_IN_T, TUSER_IN_T)  pkt_playback_driver;

    axi4l_verif_pkg::axi4l_reg_agent #() reg_agent;
    gtm_regs_reg_blk_agent gtm_agent;

    bit [31:0] rdata;

    logic aligned = 1'b0;

    // =========================================================================
    // FEC TX dout-start monitors
    // Pulses once per FEC codeword on the SERDES clock.
    // lane 0 active → C0 is transmitting; lane 1 active → C0 is in 200G (dual-lane) mode.
    // =========================================================================
    wire mon_fec_start_0 =
        DUT.dcmac_wrapper_0.i_xilinx_dcmac_wrapper.fec_tx_dout_start_0;
    wire mon_fec_start_1 =
        DUT.dcmac_wrapper_0.i_xilinx_dcmac_wrapper.fec_tx_dout_start_1;

    int fec_start_0_count = 0;
    int fec_start_1_count = 0;

    always @(posedge mon_fec_start_0) begin
        fec_start_0_count++;
        if (fec_start_0_count == 1)
            $display("[%0t] *** fec_tx_dout_start_0: FIRST pulse — lane 0 is active", $time);
        else if (fec_start_0_count % 100 == 0)
            $display("[%0t]     fec_tx_dout_start_0: %0d pulses so far", $time, fec_start_0_count);
    end

    always @(posedge mon_fec_start_1) begin
        fec_start_1_count++;
        if (fec_start_1_count == 1)
            $display("[%0t] *** fec_tx_dout_start_1: FIRST pulse — lane 1 is active (200G confirmed)", $time);
        else if (fec_start_1_count % 100 == 0)
            $display("[%0t]     fec_tx_dout_start_1: %0d pulses so far", $time, fec_start_1_count);
    end

    // =========================================================================
    // GT serial TX→RX loopback via force on GTME5_QUAD simulation model ports.
    // Two quads: g_gt[0] and g_gt[1], 4 channels each — mirrors the example
    // design's i_xilinx_dcmac_0_gtwiz_versal_0 / _1 loopback structure.
    // =========================================================================
    integer gt_loopback0_p_0;
    integer gt_loopback0_n_0;
    integer gt_loopback1_p_0;
    integer gt_loopback1_n_0;
    integer gt_loopback2_p_0;
    integer gt_loopback2_n_0;
    integer gt_loopback3_p_0;
    integer gt_loopback3_n_0;

    integer gt_loopback0_p_1;
    integer gt_loopback0_n_1;
    integer gt_loopback1_p_1;
    integer gt_loopback1_n_1;
    integer gt_loopback2_p_1;
    integer gt_loopback2_n_1;
    integer gt_loopback3_p_1;
    integer gt_loopback3_n_1;

    `define GT_QUAD_0 DUT.dcmac_wrapper_0.g_gt[0].i_xilinx_gtm_wrapper.i_xilinx_gtm_0\
        .inst.intf_quad_map_inst.quad_top_inst.gt_quad_base_0_inst.inst.quad_inst
    `define GT_QUAD_1 DUT.dcmac_wrapper_0.g_gt[1].i_xilinx_gtm_wrapper.i_xilinx_gtm_0\
        .inst.intf_quad_map_inst.quad_top_inst.gt_quad_base_0_inst.inst.quad_inst

    always @(*) begin
        force gt_loopback0_p_0 = `GT_QUAD_0.CH0_GTMTXP_integer;
        force gt_loopback0_n_0 = `GT_QUAD_0.CH0_GTMTXN_integer;
        force `GT_QUAD_0.CH0_GTMRXP_integer = gt_loopback0_p_0;
        force `GT_QUAD_0.CH0_GTMRXN_integer = gt_loopback0_n_0;

        force gt_loopback1_p_0 = `GT_QUAD_0.CH1_GTMTXP_integer;
        force gt_loopback1_n_0 = `GT_QUAD_0.CH1_GTMTXN_integer;
        force `GT_QUAD_0.CH1_GTMRXP_integer = gt_loopback1_p_0;
        force `GT_QUAD_0.CH1_GTMRXN_integer = gt_loopback1_n_0;

        force gt_loopback2_p_0 = `GT_QUAD_0.CH2_GTMTXP_integer;
        force gt_loopback2_n_0 = `GT_QUAD_0.CH2_GTMTXN_integer;
        force `GT_QUAD_0.CH2_GTMRXP_integer = gt_loopback2_p_0;
        force `GT_QUAD_0.CH2_GTMRXN_integer = gt_loopback2_n_0;

        force gt_loopback3_p_0 = `GT_QUAD_0.CH3_GTMTXP_integer;
        force gt_loopback3_n_0 = `GT_QUAD_0.CH3_GTMTXN_integer;
        force `GT_QUAD_0.CH3_GTMRXP_integer = gt_loopback3_p_0;
        force `GT_QUAD_0.CH3_GTMRXN_integer = gt_loopback3_n_0;

        force gt_loopback0_p_1 = `GT_QUAD_1.CH0_GTMTXP_integer;
        force gt_loopback0_n_1 = `GT_QUAD_1.CH0_GTMTXN_integer;
        force `GT_QUAD_1.CH0_GTMRXP_integer = gt_loopback0_p_1;
        force `GT_QUAD_1.CH0_GTMRXN_integer = gt_loopback0_n_1;

        force gt_loopback1_p_1 = `GT_QUAD_1.CH1_GTMTXP_integer;
        force gt_loopback1_n_1 = `GT_QUAD_1.CH1_GTMTXN_integer;
        force `GT_QUAD_1.CH1_GTMRXP_integer = gt_loopback1_p_1;
        force `GT_QUAD_1.CH1_GTMRXN_integer = gt_loopback1_n_1;

        force gt_loopback2_p_1 = `GT_QUAD_1.CH2_GTMTXP_integer;
        force gt_loopback2_n_1 = `GT_QUAD_1.CH2_GTMTXN_integer;
        force `GT_QUAD_1.CH2_GTMRXP_integer = gt_loopback2_p_1;
        force `GT_QUAD_1.CH2_GTMRXN_integer = gt_loopback2_n_1;

        force gt_loopback3_p_1 = `GT_QUAD_1.CH3_GTMTXP_integer;
        force gt_loopback3_n_1 = `GT_QUAD_1.CH3_GTMTXN_integer;
        force `GT_QUAD_1.CH3_GTMRXP_integer = gt_loopback3_p_1;
        force `GT_QUAD_1.CH3_GTMRXN_integer = gt_loopback3_n_1;
    end

    `undef GT_QUAD_0
    `undef GT_QUAD_1

    // =========================================================================
    // Clock (100 MHz)
    // =========================================================================
    `SVUNIT_CLK_GEN(axil_if.aclk, 5ns);

    `SVUNIT_CLK_GEN(gt_ref_clk0_p, 1.5525ns);

    assign gt_ref_clk0_n = ~gt_ref_clk0_p;

    // =========================================================================
    // Build
    // =========================================================================
    function void build();
        svunit_ut = new(name);

        reg_agent = new("axi4l_reg_agent");
        reg_agent.axil_vif = axil_if;

        gtm_agent = new("gtm_regs_reg_blk_agent", 32'h002C_0000);
        gtm_agent.reg_agent = reg_agent;

        pkt_playback_driver = new("axi4s_playback_driver", 16384, reg_agent, 'h405000);
        pkt_playback_driver.inbox = new();
    endfunction

    // =========================================================================
    // Setup / teardown
    // =========================================================================
    task setup();
        svunit_ut.setup();
        reg_agent.idle();

        axil_if.aresetn = 1'b0;
        pci_rstn_in     = 1'b0;
        repeat (8) @(posedge axil_if.aclk);
        axil_if.aresetn = 1'b1;
        pci_rstn_in     = 1'b1;
        repeat (10) @(posedge axil_if.aclk);

        #35us;  // wait for stable clocks

        dcmac_config();

        pkt_playback_driver.init();
        fork pkt_playback_driver.run(); join_none

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
//        `FAIL_UNLESS_EQUAL(resp.encoded, axi4l_pkg::RESP_OKAY);
    endtask

    task automatic axil_read(input bit [31:0] addr, output bit [31:0] data);
        axi4l_pkg::resp_t resp;
        bit timeout;
        axil_if.read(addr, data, resp, timeout);
        `FAIL_UNLESS_EQUAL(timeout, 1'b0);
//        `FAIL_UNLESS_EQUAL(resp.encoded, axi4l_pkg::RESP_OKAY);
    endtask

    task automatic dcmac_config ();
        // dcmac reset and config
        $display ("Resetting and Configuring DCMAC...");
        //reg_ch0_fabric_intf_cfg1 = {22'h00, 3'h2, 7'h00};
        gtm_agent.write_ch0_fabric_intf_cfg1({22'h00, 3'h1, 7'h00});
        gtm_agent.write_ch1_fabric_intf_cfg1({22'h00, 3'h1, 7'h00});
        gtm_agent.write_ch2_fabric_intf_cfg1({22'h00, 3'h1, 7'h00});
        gtm_agent.write_ch3_fabric_intf_cfg1({22'h00, 3'h1, 7'h00});
        gtm_agent.read_ch0_fabric_intf_cfg1(reg_ch0_fabric_intf_cfg1);
        gtm_agent.read_ch1_fabric_intf_cfg1(reg_ch0_fabric_intf_cfg1);
        gtm_agent.read_ch2_fabric_intf_cfg1(reg_ch0_fabric_intf_cfg1);
        gtm_agent.read_ch3_fabric_intf_cfg1(reg_ch0_fabric_intf_cfg1);

//        axil_write(32'h0020_0004, 32'h0122_1122);  // GLOBAL_MODE 100G
        axil_write(32'h0020_0004, 32'h0155_0022);  // GLOBAL_MODE

        // assert all reset
        $display ("Assert all resets...");
        axil_write(32'h0020_00F0, 32'hFFFF_FFFF);  // GLOBAL_CONTROL_REG_RX - assert resets
        axil_write(32'h0020_10F0, 32'hFFFF_FFFF);  // C0_PORT_CONTROL_REG_RX - assert resets
        axil_write(32'h0020_20F0, 32'hFFFF_FFFF);
        axil_write(32'h0020_30F0, 32'hFFFF_FFFF);
        axil_write(32'h0020_40F0, 32'hFFFF_FFFF);
        axil_write(32'h0020_50F0, 32'hFFFF_FFFF);
        axil_write(32'h0020_60F0, 32'hFFFF_FFFF);  // C5_PORT_CONTROL_REG_RX - assert resets
/*
*/
        axil_write(32'h0020_00F8, 32'hFFFF_FFFF);  // GLOBAL_CONTROL_REG_TX - assert resets
        axil_write(32'h0020_10F8, 32'hFFFF_FFFF);  // C0_PORT_CONTROL_REG_TX - assert resets
        axil_write(32'h0020_20F8, 32'hFFFF_FFFF);
        axil_write(32'h0020_30F8, 32'hFFFF_FFFF);
        axil_write(32'h0020_40F8, 32'hFFFF_FFFF);
        axil_write(32'h0020_50F8, 32'hFFFF_FFFF);
        axil_write(32'h0020_60F8, 32'hFFFF_FFFF);  // C5_PORT_CONTROL_REG_TX - assert resets
/*
*/
        // client reset flush
        $display ("Client reset flush...");
        axil_write(32'h0020_1030, 32'h0000_0001);  // C0_CHANNEL_CONTROL_REG_RX - assert tx flush
        axil_write(32'h0020_1038, 32'h0000_0001);  // C0_CHANNEL_CONTROL_REG_TX - assert rx flush
        repeat (100) @(posedge axil_if.aclk);
        axil_write(32'h0020_10f0, 32'h0000_0003);  // C0_PORT_CONTROL_REG_RX - assert tx phy reset
        axil_write(32'h0020_10f8, 32'h0000_0003);  // C0_PORT_CONTROL_REG_TX - assert rx phy reset

        axil_write(32'h0020_2030, 32'h0000_0001);
        axil_write(32'h0020_2038, 32'h0000_0001);
        repeat (100) @(posedge axil_if.aclk);
        axil_write(32'h0020_20f0, 32'h0000_0003);
        axil_write(32'h0020_20f8, 32'h0000_0003);

        axil_write(32'h0020_3030, 32'h0000_0001);
        axil_write(32'h0020_3038, 32'h0000_0001);
        repeat (100) @(posedge axil_if.aclk);
        axil_write(32'h0020_30f0, 32'h0000_0003);
        axil_write(32'h0020_30f8, 32'h0000_0003);

        axil_write(32'h0020_4030, 32'h0000_0001);
        axil_write(32'h0020_4038, 32'h0000_0001);
        repeat (100) @(posedge axil_if.aclk);
        axil_write(32'h0020_40f0, 32'h0000_0003);
        axil_write(32'h0020_40f8, 32'h0000_0003);

        axil_write(32'h0020_5030, 32'h0000_0001);
        axil_write(32'h0020_5038, 32'h0000_0001);
        repeat (100) @(posedge axil_if.aclk);
        axil_write(32'h0020_50f0, 32'h0000_0003);
        axil_write(32'h0020_50f8, 32'h0000_0003);

        axil_write(32'h0020_6030, 32'h0000_0001);  // C5_CHANNEL_CONTROL_REG_RX - assert tx flush
        axil_write(32'h0020_6038, 32'h0000_0001);  // C5_CHANNEL_CONTROL_REG_TX - assert rx flush
        repeat (100) @(posedge axil_if.aclk);
        axil_write(32'h0020_60f0, 32'h0000_0003);  // C5_PORT_CONTROL_REG_RX - assert tx phy reset
        axil_write(32'h0020_60f8, 32'h0000_0003);  // C5_PORT_CONTROL_REG_TX - assert rx phy reset
/*
*/
        $display ("Wait 100 cycles...");
        repeat (100) @(posedge axil_if.aclk);

        // set data rate
        $display ("Set data rate...");
        axil_write(32'h0020_1040, 32'h0008_0215);  // C0_TX_MODE_REG
        axil_write(32'h0020_1044, 32'h0008_1a01);  // C0_RX_MODE_REG
//        axil_write(32'h0020_1040, 32'h0005_0014);  // C0_TX_MODE_REG
//        axil_write(32'h0020_1044, 32'h0005_0a00);  // C0_RX_MODE_REG
/*
        axil_write(32'h0020_2040, 32'h0005_0014);
        axil_write(32'h0020_2044, 32'h0005_0a00);
*/
        axil_write(32'h0020_3040, 32'h0008_0215);
        axil_write(32'h0020_3044, 32'h0008_1a01);
//        axil_write(32'h0020_3040, 32'h0005_0014);
//        axil_write(32'h0020_3044, 32'h0005_0a00);
/*
        axil_write(32'h0020_4040, 32'h0005_0014);
        axil_write(32'h0020_4044, 32'h0005_0a00);
        axil_write(32'h0020_5040, 32'h0005_0014);
        axil_write(32'h0020_5044, 32'h0005_0a00);
        axil_write(32'h0020_6040, 32'h0005_0014);  // C5_TX_MODE_REG
        axil_write(32'h0020_6044, 32'h0005_0a00);  // C5_RX_MODE_REG
*/
        // release all reset
        $display ("Release all resets...");
        axil_write(32'h0020_00F0, 32'h0000_0000);  // GLOBAL_CONTROL_REG_RX - release resets
        axil_write(32'h0020_10F0, 32'h0000_0000);  // C0_PORT_CONTROL_REG_RX - release tx phy reset
        axil_write(32'h0020_20F0, 32'h0000_0000);
        axil_write(32'h0020_30F0, 32'h0000_0000);
        axil_write(32'h0020_40F0, 32'h0000_0000);
        axil_write(32'h0020_50F0, 32'h0000_0000);
        axil_write(32'h0020_60F0, 32'h0000_0000);  // C5_PORT_CONTROL_REG_RX - release tx phy reset
/*
*/
        axil_write(32'h0020_00F8, 32'h0000_0000);  // GLOBAL_CONTROL_REG_TX - release resets
        axil_write(32'h0020_10F8, 32'h0000_0000);  // C0_PORT_CONTROL_REG_TX - release rx phy reset
        axil_write(32'h0020_20F8, 32'h0000_0000);
        axil_write(32'h0020_30F8, 32'h0000_0000);
        axil_write(32'h0020_40F8, 32'h0000_0000);
        axil_write(32'h0020_50F8, 32'h0000_0000);
        axil_write(32'h0020_60F8, 32'h0000_0000);  // C5_PORT_CONTROL_REG_TX - release rx phy reset
/*
*/
        // client release flush
        $display ("Client release flush...");
        axil_write(32'h0020_10f0, 32'h0000_0000);  // C0_PORT_CONTROL_REG_RX - release tx phy reset
        axil_write(32'h0020_10f8, 32'h0000_0000);  // C0_PORT_CONTROL_REG_TX - release rx phy reset
        repeat (100) @(posedge axil_if.aclk);
        axil_write(32'h0020_1030, 32'h0000_0000);  // C0_CHANNEL_CONTROL_REG_RX - release tx flush
        axil_write(32'h0020_1038, 32'h0000_0000);  // C0_CHANNEL_CONTROL_REG_TX - release rx flush

        axil_write(32'h0020_20f0, 32'h0000_0000);
        axil_write(32'h0020_20f8, 32'h0000_0000);
        repeat (100) @(posedge axil_if.aclk);
        axil_write(32'h0020_2030, 32'h0000_0000);
        axil_write(32'h0020_2038, 32'h0000_0000);

        axil_write(32'h0020_30f0, 32'h0000_0000);
        axil_write(32'h0020_30f8, 32'h0000_0000);
        repeat (100) @(posedge axil_if.aclk);
        axil_write(32'h0020_3030, 32'h0000_0000);
        axil_write(32'h0020_3038, 32'h0000_0000);

        axil_write(32'h0020_40f0, 32'h0000_0000);
        axil_write(32'h0020_40f8, 32'h0000_0000);
        repeat (100) @(posedge axil_if.aclk);
        axil_write(32'h0020_4030, 32'h0000_0000);
        axil_write(32'h0020_4038, 32'h0000_0000);

        axil_write(32'h0020_50f0, 32'h0000_0000);
        axil_write(32'h0020_50f8, 32'h0000_0000);
        repeat (100) @(posedge axil_if.aclk);
        axil_write(32'h0020_5030, 32'h0000_0000);
        axil_write(32'h0020_5038, 32'h0000_0000);

        axil_write(32'h0020_60f0, 32'h0000_0000);
        axil_write(32'h0020_60f8, 32'h0000_0000);
        repeat (100) @(posedge axil_if.aclk);
        axil_write(32'h0020_6030, 32'h0000_0000);  // C5_CHANNEL_CONTROL_REG_RX - release tx flush
        axil_write(32'h0020_6038, 32'h0000_0000);  // C5_CHANNEL_CONTROL_REG_TX - release rx flush
/*
*/
        // latch all
        $display ("Latch all...");
        axil_write(32'h0020_10f4, 32'h0000_0001);  // C0_PORT_TICK_REG_RX
        axil_write(32'h0020_10fc, 32'h0000_0001);  // C0_PORT_TICK_REG_TX
        axil_write(32'h0020_30f4, 32'h0000_0001);  // C2_PORT_TICK_REG_RX
        axil_write(32'h0020_30fc, 32'h0000_0001);  // C2_PORT_TICK_REG_TX

//        $display ("Wait 500 cycles...");
//        repeat (500) @(posedge axil_if.aclk);
//        repeat (100) @(posedge axil_if.aclk);

        $display ("Test for alignment...");
        aligned = 1'b0;
        while (!aligned) begin
            axil_write(32'h0020_1C00, 32'hFFFF_FFFF);  // C0_STAT_PORT_RX_PHY_STATUS_REG - clear rx phy status
            axil_read (32'h0020_1C00, rdata);          // C0_STAT_PORT_RX_PHY_STATUS_REG - poll  rx phy status
            $display ("%t: Polling C0 for alignment...rdata: %h", $time, rdata);

            aligned = (rdata[2] && rdata[0]);

            axil_write(32'h0020_2C00, 32'hFFFF_FFFF);  // C1_STAT_PORT_RX_PHY_STATUS_REG - clear rx phy status
            axil_read (32'h0020_2C00, rdata);          // C1_STAT_PORT_RX_PHY_STATUS_REG - poll  rx phy status
            $display ("%t: Polling C1 for alignment...rdata: %h", $time, rdata);
            aligned = aligned && (rdata[2] && rdata[0]);
        end
        $display ("%t: Alignment achieved!", $time);

        repeat (100) @(posedge axil_if.aclk);
    endtask

    task automatic pkt_to_playback (int id=0, len=$urandom_range(64, 512), port_t tid='0, tdest='0, bit tuser='0);
        TRANSACTION_IN_T transaction;

	transaction = new($sformatf("pkt_%0d", id), len);
        transaction.randomize();
        transaction.set_tid(tid);
        transaction.set_tdest(tdest);
        transaction.set_tuser(tuser);

        pkt_playback_driver.inbox.put(transaction);
    endtask

    // =========================================================================
    // Tests
    // =========================================================================
    localparam type PKT_PLAYBACK_META_T = struct packed {port_t tid; port_t tdest; bit tuser;};

    `SVUNIT_TESTS_BEGIN
/*
        // Verify the id register returns the 'CORE' sentinel value.
        `SVTEST(id_read)
            //bit [31:0] rdata;
            axil_read(ADDR_ID, rdata);
            `FAIL_UNLESS_EQUAL(rdata, ID_EXPECTED);
        `SVTEST_END

        `SVTEST(info)
            int got_int;
            // Check packet memory size
            pkt_playback_driver.agent.read_mem_size(got_int);
            `FAIL_UNLESS_EQUAL(got_int, 16384);

	    // Check metadata width
            pkt_playback_driver.agent.read_meta_width(got_int);
            `FAIL_UNLESS_EQUAL(got_int, $bits(PKT_PLAYBACK_META_T));
        `SVTEST_END
*/
        `SVTEST(pkt_playback)
            int got_int;
            int len = 200; //$urandom_range(64, 512);
            pkt_playback_driver.agent.read_mem_size(got_int);
            pkt_playback_driver.agent.read_meta_width(got_int);

            $display("%t: sending pkt1", $time);
//            pkt_to_playback(.len(100), .id(0), .tid(PF0), .tdest(PHY0));
            pkt_to_playback(.len(128), .id(0), .tid(PF0), .tdest(PHY0));
            #25us;

            $display("%t: sending pkt2", $time);
//            pkt_to_playback(.len(127), .id(0), .tid(PF0), .tdest(PHY0));
            pkt_to_playback(.len(128), .id(0), .tid(PF0), .tdest(PHY0));
            #25us;

            $display("%t: sending pkt3", $time);
//            pkt_to_playback(.len(140), .id(0), .tid(PF0), .tdest(PHY0));
            pkt_to_playback(.len(128), .id(0), .tid(PF0), .tdest(PHY0));
            #25us;

         `SVTEST_END
/*
        // Verify the scratchpad register round-trips a written value.
        `SVTEST(scratchpad_write_read)
            //bit [31:0] rdata;
            axil_write(ADDR_SCRATCHPAD, 32'hDEAD_BEEF);
            axil_read(ADDR_SCRATCHPAD, rdata);
            `FAIL_UNLESS_EQUAL(rdata, 32'hDEAD_BEEF);
        `SVTEST_END

        // Back-to-back reads through the shell management path.
        `SVTEST(back_to_back_reads)
            //bit [31:0] rdata;
            axil_write(ADDR_SCRATCHPAD, 32'hA5A5_A5A5);
            repeat (4) begin
                axil_read(ADDR_ID, rdata);
                `FAIL_UNLESS_EQUAL(rdata, ID_EXPECTED);
                axil_read(ADDR_SCRATCHPAD, rdata);
                `FAIL_UNLESS_EQUAL(rdata, 32'hA5A5_A5A5);
            end
        `SVTEST_END
*/
    `SVUNIT_TESTS_END

endmodule
