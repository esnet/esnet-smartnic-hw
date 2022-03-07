// =============================================================================
//  NOTICE: This computer software was prepared by The Regents of the
//  University of California through Lawrence Berkeley National Laboratory
//  and Peter Bengough hereinafter the Contractor, under Contract No.
//  DE-AC02-05CH11231 with the Department of Energy (DOE). All rights in the
//  computer software are reserved by DOE on behalf of the United States
//  Government and the Contractor as provided in the Contract. You are
//  authorized to use this computer software for Governmental purposes but it
//  is not to be released or distributed to the public.
//
//  NEITHER THE GOVERNMENT NOR THE CONTRACTOR MAKES ANY WARRANTY, EXPRESS OR
//  IMPLIED, OR ASSUMES ANY LIABILITY FOR THE USE OF THIS SOFTWARE.
//
//  This notice including this sentence must appear on any copies of this
//  computer software.
// =============================================================================

`timescale 1ns/1ps

import p4_app_pkg::*;

module p4_app #(
) (
   input logic        core_clk,
   input logic        core_rstn,
   input timestamp_t  timestamp,

   axi4l_intf.peripheral axil_if,
   axi4l_intf.peripheral axil_to_sdnet,

   axi4s_intf.tx axis_core_to_switch,
   axi4s_intf.rx axis_switch_to_core,
   axi4s_intf.tx axis_to_host_0,
   axi4s_intf.rx axis_from_host_0   
);

   // ----------------------------------------------------------------
   //  Register map block and decoder instantiations
   // ----------------------------------------------------------------

   axi4l_intf  axil_to_p4_app ();
   
   p4_app_reg_intf  p4_app_regs();

   // p4_app register decoder
   p4_app_decoder p4_app_decoder (
      .axil_if           (axil_if),					  
      .p4_app_axil_if   (axil_to_p4_app)
   );
   
   // p4_app register block
   p4_app_reg_blk p4_app_reg_blk 
   (
    .axil_if    (axil_to_p4_app),
    .reg_blk_if (p4_app_regs)                 
   );


   // ----------------------------------------------------------------
   //  Datpath pass-through connections (hard-wired bypass)
   // ----------------------------------------------------------------
/*   
   assign axis_core_to_switch.aclk   = axis_switch_to_core.aclk;
   assign axis_core_to_switch.aresetn= axis_switch_to_core.aresetn;
   assign axis_core_to_switch.tvalid = axis_switch_to_core.tvalid && !p4_app_regs.tpause;
   assign axis_core_to_switch.tdata  = axis_switch_to_core.tdata;
   assign axis_core_to_switch.tkeep  = axis_switch_to_core.tkeep;
   assign axis_core_to_switch.tlast  = axis_switch_to_core.tlast;
   assign axis_core_to_switch.tid    = axis_switch_to_core.tid;
   assign axis_core_to_switch.tdest  = axis_switch_to_core.tdest;

   assign axis_switch_to_core.tready = axis_core_to_switch.tready && !p4_app_regs.tpause;
*/

   assign axis_to_host_0.aclk   = axis_from_host_0.aclk;
   assign axis_to_host_0.aresetn= axis_from_host_0.aresetn;
   assign axis_to_host_0.tvalid = axis_from_host_0.tvalid;
   assign axis_to_host_0.tdata  = axis_from_host_0.tdata;
   assign axis_to_host_0.tkeep  = axis_from_host_0.tkeep;
   assign axis_to_host_0.tlast  = axis_from_host_0.tlast;
   assign axis_to_host_0.tid    = axis_from_host_0.tid;
   assign axis_to_host_0.tdest  = axis_from_host_0.tdest;

   assign axis_from_host_0.tready = axis_to_host_0.tready;


   // ----------------------------------------------------------------
   // The SDnet block
   // ----------------------------------------------------------------
   // Metadata - type definitions are maintained in `ht_app_pkg`

   // --- metadata_in ---
   user_metadata_t user_metadata_in;
   logic           user_metadata_in_valid;
   
   always_comb begin
      user_metadata_in.ingress_global_timestamp = timestamp;
      user_metadata_in.dest_port                = axis_switch_to_core.tid;
      user_metadata_in.truncate_enable          = 0;
      user_metadata_in.packet_length            = 0;
      user_metadata_in.rss_override_enable      = 0;
      user_metadata_in.rss_override             = 0;

      user_metadata_in_valid = axis_switch_to_core.tvalid;
   end

   
   // --- metadata_out ---
   user_metadata_t user_metadata_out, user_metadata_out_latch;
   logic           user_metadata_out_valid;

   always @(posedge core_clk) begin
      if (user_metadata_out_valid) user_metadata_out_latch <= user_metadata_out;
   end
   
   assign axis_core_to_switch.tdest = user_metadata_out_valid ? user_metadata_out.dest_port[1:0] : user_metadata_out_latch.dest_port[1:0];   


   // --- sdnet_0 instance (p4_app) ---
   sdnet_0 sdnet_0_p4_app
   (
    // Clocks & Resets
    .s_axis_aclk             (core_clk),
    .s_axis_aresetn          (core_rstn),
    .s_axi_aclk              (axil_to_sdnet.aclk),
    .s_axi_aresetn           (axil_to_sdnet.aresetn),
    .cam_mem_aclk            (core_clk),
    .cam_mem_aresetn         (core_rstn),

    // Metadata
    .user_metadata_in        (user_metadata_in),         
    .user_metadata_in_valid  (user_metadata_in_valid),   
    .user_metadata_out       (user_metadata_out),
    .user_metadata_out_valid (user_metadata_out_valid),  
    
    // Slave AXI-lite interface
    .s_axi_awaddr  (axil_to_sdnet.awaddr),
    .s_axi_awvalid (axil_to_sdnet.awvalid),
    .s_axi_awready (axil_to_sdnet.awready),
    .s_axi_wdata   (axil_to_sdnet.wdata),
    .s_axi_wstrb   (axil_to_sdnet.wstrb),
    .s_axi_wvalid  (axil_to_sdnet.wvalid),
    .s_axi_wready  (axil_to_sdnet.wready),
    .s_axi_bresp   (axil_to_sdnet.bresp),
    .s_axi_bvalid  (axil_to_sdnet.bvalid),
    .s_axi_bready  (axil_to_sdnet.bready),
    .s_axi_araddr  (axil_to_sdnet.araddr),
    .s_axi_arvalid (axil_to_sdnet.arvalid),
    .s_axi_arready (axil_to_sdnet.arready),
    .s_axi_rdata   (axil_to_sdnet.rdata),
    .s_axi_rvalid  (axil_to_sdnet.rvalid),
    .s_axi_rready  (axil_to_sdnet.rready),
    .s_axi_rresp   (axil_to_sdnet.rresp),
    
    // AXI Master port
    .m_axis_tdata  (axis_core_to_switch.tdata),
    .m_axis_tkeep  (axis_core_to_switch.tkeep),
    .m_axis_tvalid (axis_core_to_switch.tvalid),
    .m_axis_tlast  (axis_core_to_switch.tlast),
    .m_axis_tready (axis_core_to_switch.tready),

    // AXI Slave port
    .s_axis_tdata  (axis_switch_to_core.tdata),
    .s_axis_tkeep  (axis_switch_to_core.tkeep),
    .s_axis_tvalid (axis_switch_to_core.tvalid),
    .s_axis_tlast  (axis_switch_to_core.tlast),
    .s_axis_tready (axis_switch_to_core.tready)
    );

    assign axis_core_to_switch.aclk = core_clk;
    assign axis_core_to_switch.aresetn = core_rstn;

endmodule: p4_app
