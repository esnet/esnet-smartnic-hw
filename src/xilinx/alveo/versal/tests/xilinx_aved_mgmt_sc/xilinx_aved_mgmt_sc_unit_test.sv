// Xilinx AXI VIP procedural API packages are generated when Vivado produces
// simulation output products for the xilinx_aved_mgmt_sc BD.
// Package naming convention: <bd_name>_<cell_name>_0_pkg
`include "svunit_defines.svh"

import axi_vip_pkg::*;
import xilinx_aved_mgmt_sc_axi_vip_m_0_pkg::*;
import xilinx_aved_mgmt_sc_axi_vip_s0_0_pkg::*;
import xilinx_aved_mgmt_sc_axi_vip_s1_0_pkg::*;
import xilinx_aved_mgmt_sc_axi_vip_s2_0_pkg::*;
import xilinx_aved_mgmt_sc_axi_vip_s3_0_pkg::*;

module xilinx_aved_mgmt_sc_unit_test;
    import svunit_pkg::svunit_testcase;
    import axi4l_pkg::*;

    string name = "xilinx_aved_mgmt_sc_ut";
    svunit_testcase svunit_ut;

    `define SVUNIT_TIMEOUT 1ms

    // =========================================================================
    // Register offsets (core.stub.regio/core.yaml)
    // =========================================================================
    localparam bit [31:0] ID_EXPECTED = 32'h434F5245;  // 'CORE'

    // =========================================================================
    // DUT signals
    // =========================================================================
    logic aclk;
    logic aresetn;

    // =========================================================================
    // M04 boundary port wires
    //   Mode Master on the BD means these drive out from the BD and are inputs
    //   to xilinx_aved_adapter (which is a slave of the management bus).
    // =========================================================================
    wire [31:0] m_axi_usr_mgmt_awaddr;
    wire [2:0]  m_axi_usr_mgmt_awprot;
    wire        m_axi_usr_mgmt_awvalid;
    wire        m_axi_usr_mgmt_awready;
    wire [31:0] m_axi_usr_mgmt_wdata;
    wire [3:0]  m_axi_usr_mgmt_wstrb;
    wire        m_axi_usr_mgmt_wvalid;
    wire        m_axi_usr_mgmt_wready;
    wire [1:0]  m_axi_usr_mgmt_bresp;
    wire        m_axi_usr_mgmt_bvalid;
    wire        m_axi_usr_mgmt_bready;
    wire [31:0] m_axi_usr_mgmt_araddr;
    wire [2:0]  m_axi_usr_mgmt_arprot;
    wire        m_axi_usr_mgmt_arvalid;
    wire        m_axi_usr_mgmt_arready;
    wire [31:0] m_axi_usr_mgmt_rdata;
    wire [1:0]  m_axi_usr_mgmt_rresp;
    wire        m_axi_usr_mgmt_rvalid;
    wire        m_axi_usr_mgmt_rready;

    // =========================================================================
    // DUT instantiation
    // =========================================================================
    xilinx_aved_mgmt_sc DUT (.*);

    // =========================================================================
    // M04 adapter chain: boundary port -> xilinx_aved_adapter
    //                    -> xilinx_aved_shell_adapter -> core
    // =========================================================================
    axi4l_intf axil_app_if ();
    shell_intf  shell_if    ();

    xilinx_aved_adapter i_xilinx_aved_adapter (
        .clk_pl                    ( aclk    ),
        .resetn_pl_periph          ( aresetn ),
        .m_axi_usr_mgmt_awaddr,
        .m_axi_usr_mgmt_awprot,
        .m_axi_usr_mgmt_awvalid,
        .m_axi_usr_mgmt_awready,
        .m_axi_usr_mgmt_wdata,
        .m_axi_usr_mgmt_wstrb,
        .m_axi_usr_mgmt_wvalid,
        .m_axi_usr_mgmt_wready,
        .m_axi_usr_mgmt_bresp,
        .m_axi_usr_mgmt_bvalid,
        .m_axi_usr_mgmt_bready,
        .m_axi_usr_mgmt_araddr,
        .m_axi_usr_mgmt_arprot,
        .m_axi_usr_mgmt_arvalid,
        .m_axi_usr_mgmt_arready,
        .m_axi_usr_mgmt_rdata,
        .m_axi_usr_mgmt_rresp,
        .m_axi_usr_mgmt_rvalid,
        .m_axi_usr_mgmt_rready,
        .axil_if ( axil_app_if )
    );

    xilinx_aved_shell_adapter i_xilinx_aved_shell_adapter (
        .axil_if  ( axil_app_if ),
        .shell_if
    );

    core i_core (
        .shell_if
    );

    // =========================================================================
    // Clock
    // =========================================================================
    `SVUNIT_CLK_GEN(aclk, 5ns);   // 100 MHz

    // =========================================================================
    // AXI VIP agents
    // Use the mem-model slave type so BVALID is generated automatically
    // without user-driven reactive loops.
    // =========================================================================
    xilinx_aved_mgmt_sc_axi_vip_m_0_mst_t      master_agent;
    xilinx_aved_mgmt_sc_axi_vip_s0_0_slv_mem_t slave_agent_0;
    xilinx_aved_mgmt_sc_axi_vip_s1_0_slv_mem_t slave_agent_1;
    xilinx_aved_mgmt_sc_axi_vip_s2_0_slv_mem_t slave_agent_2;
    xilinx_aved_mgmt_sc_axi_vip_s3_0_slv_mem_t slave_agent_3;

    // Xilinx VIP agents cannot be stopped and restarted — start once only.
    // Reset is also applied only once: each test completes its transaction
    // before returning, so the DUT is already idle for the next test.
    bit initialized = 0;

    // =========================================================================
    // Build
    // =========================================================================
    function void build();
        svunit_ut = new(name);
        master_agent  = new("master_agent",  DUT.axi_vip_m.inst.IF);
        slave_agent_0 = new("slave_agent_0", DUT.axi_vip_s0.inst.IF);
        slave_agent_1 = new("slave_agent_1", DUT.axi_vip_s1.inst.IF);
        slave_agent_2 = new("slave_agent_2", DUT.axi_vip_s2.inst.IF);
        slave_agent_3 = new("slave_agent_3", DUT.axi_vip_s3.inst.IF);
    endfunction

    // =========================================================================
    // Setup / teardown
    // =========================================================================
    task setup();
        svunit_ut.setup();
        if (!initialized) begin
            aresetn = 1'b0;
            master_agent.start_master();
            slave_agent_0.start_slave();
            slave_agent_1.start_slave();
            slave_agent_2.start_slave();
            slave_agent_3.start_slave();
            repeat (20) @(posedge aclk);  // >= 16 cycles required by Xilinx VIP
            aresetn = 1'b1;
            repeat (4) @(posedge aclk);
            initialized = 1;
        end
    endtask

    task teardown();
        svunit_ut.teardown();
    endtask

    // =========================================================================
    // Helpers
    // =========================================================================
    // Issue an AXI4-Lite write and check for OKAY response.
    task automatic axil_write(input xil_axi_ulong addr, input logic [31:0] data);
        xil_axi_resp_t bresp;
        master_agent.AXI4LITE_WRITE_BURST(addr, 0, data, bresp);
        `FAIL_UNLESS_EQUAL(bresp, XIL_AXI_RESP_OKAY);
    endtask

    // Issue an AXI4-Lite read and check for OKAY response.
    task automatic axil_read(
        input  xil_axi_ulong addr,
        output logic [31:0]  data
    );
        xil_axi_resp_t rresp;
        master_agent.AXI4LITE_READ_BURST(addr, 0, data, rresp);
        `FAIL_UNLESS_EQUAL(rresp, XIL_AXI_RESP_OKAY);
    endtask

    // =========================================================================
    // Tests
    // =========================================================================
    `SVUNIT_TESTS_BEGIN

        // ------------------------------------------------------------------
        // M00-M03: verify address routing — each management endpoint
        // receives a transaction without a decode error.
        //
        // Absolute addresses match xilinx_aved.tcl (BAR0-relative
        // after NoC maps BAR0 to base 0x0201_0000_0000).
        // ------------------------------------------------------------------

        `SVTEST(route_hw_discovery)
            // M00: hw_discovery @ 0x020101000000, 4 KB
            axil_write(64'h020101000000, 32'hDEAD_BEEF);
        `SVTEST_END

        `SVTEST(route_uuid_rom)
            // M01: uuid_rom @ 0x020101001000, 4 KB
            axil_write(64'h020101001000, 32'hCAFE_BABE);
        `SVTEST_END

        `SVTEST(route_gcq_m2r)
            // M02: gcq_m2r @ 0x020101010000, 4 KB
            axil_write(64'h020101010000, 32'h1234_5678);
        `SVTEST_END

        `SVTEST(route_pdi_reset_gpio)
            // M03: pcie_mgmt_pdi_reset_gpio @ 0x020101040000, 4 KB
            axil_write(64'h020101040000, 32'h0000_0001);
        `SVTEST_END

        // ------------------------------------------------------------------
        // M04: usr_mgmt — exercises the real register block end-to-end.
        //
        // The SmartConnect delivers offset-relative addresses to the 32-bit
        // slave port, so core.stub.regio registers appear at:
        //   id         = base + 0x0
        //   scratchpad = base + 0x4
        // ------------------------------------------------------------------

        `SVTEST(usr_mgmt_id_read)
            logic [31:0] rdata;
            axil_read(64'h020101800000, rdata);
            `FAIL_UNLESS_EQUAL(rdata, ID_EXPECTED);
        `SVTEST_END

        `SVTEST(usr_mgmt_scratchpad_write_read)
            logic [31:0] rdata;
            axil_write(64'h020101800004, 32'hDEAD_BEEF);
            axil_read(64'h020101800004, rdata);
            `FAIL_UNLESS_EQUAL(rdata, 32'hDEAD_BEEF);
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
