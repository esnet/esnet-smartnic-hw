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

module p4_app
   import p4_app_pkg::*;
(
   input logic        core_clk,
   input logic        core_rstn,
   input timestamp_t  timestamp,

   axi4l_intf.peripheral axil_if,
   axi4l_intf.peripheral axil_to_sdnet,

   axi4s_intf.tx axis_to_switch_0,
   axi4s_intf.rx axis_from_switch_0,
   axi4s_intf.tx axis_to_switch_1,
   axi4s_intf.rx axis_from_switch_1,

   axi3_intf.controller  axi_to_hbm[16]
);
   import axi4s_pkg::*;


   // ----------------------------------------------------------------
   //  Register map block and decoder instantiations
   // ----------------------------------------------------------------

   axi4l_intf  axil_to_p4_app ();
   
   p4_app_reg_intf  p4_app_regs();

   // p4_app register decoder
   p4_app_decoder p4_app_decoder (
      .axil_if          (axil_if),
      .p4_app_axil_if   (axil_to_p4_app)
   );
   
   // p4_app register block
   p4_app_reg_blk p4_app_reg_blk 
   (
    .axil_if    (axil_to_p4_app),
    .reg_blk_if (p4_app_regs)                 
   );


   // ----------------------------------------------------------------
   //  Datapath pass-through connections (hard-wired bypass)
   // ----------------------------------------------------------------
   assign axis_to_switch_1.aclk   = axis_from_switch_1.aclk;
   assign axis_to_switch_1.aresetn= axis_from_switch_1.aresetn;
   assign axis_to_switch_1.tvalid = axis_from_switch_1.tvalid;
   assign axis_to_switch_1.tdata  = axis_from_switch_1.tdata;
   assign axis_to_switch_1.tkeep  = axis_from_switch_1.tkeep;
   assign axis_to_switch_1.tlast  = axis_from_switch_1.tlast;
   assign axis_to_switch_1.tid    = axis_from_switch_1.tid;
   assign axis_to_switch_1.tdest  = axis_from_switch_1.tdest;
   assign axis_to_switch_1.tuser  = axis_from_switch_1.tuser;

   assign axis_from_switch_1.tready = axis_to_switch_1.tready;


   // ----------------------------------------------------------------
   // The SDnet block
   // ----------------------------------------------------------------
   // tuser mapping (from axi4s_pkg).
   tuser_buffer_context_mode_t   axis_from_switch_0_tuser;
   assign axis_from_switch_0_tuser = axis_from_switch_0.tuser;

   tuser_buffer_context_mode_t   axis_to_switch_0_tuser;
   assign axis_to_switch_0.tuser = axis_to_switch_0_tuser;

   // metadata type definitions (from xilinx_ip/<app_name>/sdnet_0/src/verilog/sdnet_0_pkg.sv).
   // --- metadata_in ---
   user_metadata_t user_metadata_in;
   logic           user_metadata_in_valid;
   
   always_comb begin
      user_metadata_in.timestamp_ns      = timestamp;
      user_metadata_in.pid               = axis_from_switch_0_tuser.wr_ptr;
      user_metadata_in.ingress_port      = {'0, axis_from_switch_0.tid};
      user_metadata_in.egress_port       = {'0, axis_from_switch_0.tid};
      user_metadata_in.truncate_enable   = 0;
      user_metadata_in.truncate_length   = 0;
      user_metadata_in.rss_enable        = 0;
      user_metadata_in.rss_entropy       = 0;
      user_metadata_in.drop_reason       = 0;
      user_metadata_in.scratch           = 0;

      user_metadata_in_valid = axis_from_switch_0.tvalid && axis_from_switch_0.sop;
   end

   // --- metadata_out ---
   user_metadata_t user_metadata_out, user_metadata_out_latch;
   logic           user_metadata_out_valid;

   always @(posedge core_clk) if (user_metadata_out_valid) user_metadata_out_latch <= user_metadata_out;
   
   assign axis_to_switch_0.tdest = user_metadata_out_valid ?
                                   user_metadata_out.egress_port[1:0] : user_metadata_out_latch.egress_port[1:0];

   assign axis_to_switch_0_tuser.wr_ptr = user_metadata_out_valid ?
                                          user_metadata_out.pid[15:0] : user_metadata_out_latch.pid[15:0];

   assign axis_to_switch_0_tuser.hdr_tlast = '0;



   // --- sdnet_0 instance (p4_app) ---
   sdnet_0_wrapper sdnet_0_p4_app
   (
      .core_clk                (core_clk),
      .core_rstn               (core_rstn),
      .axil_if                 (axil_to_sdnet),
      .axis_rx                 (axis_from_switch_0),
      .axis_tx                 (axis_to_switch_0),
      .user_metadata_in_valid  (user_metadata_in_valid),
      .user_metadata_in        (user_metadata_in),
      .user_metadata_out_valid (user_metadata_out_valid),
      .user_metadata_out       (user_metadata_out),
      .axi_to_hbm              (axi_to_hbm)
   );

   // Drive AXI-S outputs
   assign axis_to_switch_0.aclk = core_clk;
   assign axis_to_switch_0.aresetn = core_rstn;
   assign axis_to_switch_0.tid = '0;

endmodule: p4_app
