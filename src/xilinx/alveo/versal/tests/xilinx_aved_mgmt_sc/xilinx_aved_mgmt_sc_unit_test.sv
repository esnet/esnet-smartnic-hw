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
import xilinx_aved_mgmt_sc_axi_vip_s4_0_pkg::*;

module xilinx_aved_mgmt_sc_unit_test;
    import svunit_pkg::svunit_testcase;

    string name = "xilinx_aved_mgmt_sc_ut";
    svunit_testcase svunit_ut;

    `define SVUNIT_TIMEOUT 1ms

    // =========================================================================
    // DUT signals
    // =========================================================================
    logic aclk;
    logic aresetn;

    // =========================================================================
    // DUT instantiation
    // =========================================================================
    xilinx_aved_mgmt_sc DUT (.*);

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
    xilinx_aved_mgmt_sc_axi_vip_s4_0_slv_mem_t slave_agent_4;

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
        slave_agent_4 = new("slave_agent_4", DUT.axi_vip_s4.inst.IF);
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
            slave_agent_4.start_slave();
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
        // Verify address routing: each management endpoint receives
        // a transaction addressed to it without a decode error.
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

        `SVTEST(route_usr_mgmt_base)
            // M04: usr_mgmt base @ 0x020101800000 (first word of 8 MB window)
            axil_write(64'h020101800000, 32'hA5A5_A5A5);
        `SVTEST_END

        `SVTEST(route_usr_mgmt_top)
            // M04: usr_mgmt top @ 0x0201_01FF_FFFC (last aligned word in 8 MB window)
            axil_write(64'h020101FFFFFC, 32'h5A5A_5A5A);
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
