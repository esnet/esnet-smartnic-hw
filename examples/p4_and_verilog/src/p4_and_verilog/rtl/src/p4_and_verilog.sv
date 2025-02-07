module p4_and_verilog
   import smartnic_pkg::*;
(
   input logic        core_clk,
   input logic        core_rstn,
   input timestamp_t  timestamp,

   axi4l_intf.peripheral axil_if,
   axi4l_intf.peripheral axil_to_vitisnetp4,

   axi4s_intf.tx axis_to_switch_0,
   axi4s_intf.rx axis_from_switch_0,
   axi4s_intf.tx axis_to_switch_1,
   axi4s_intf.rx axis_from_switch_1
);

   // ----------------------------------------------------------------
   //  Imports
   // ----------------------------------------------------------------
   import p4_and_verilog_pkg::*;
   import axi4s_pkg::*;

   // ----------------------------------------------------------------
   //  Register map block and decoder instantiations
   // ----------------------------------------------------------------

   axi4l_intf  axil_to_p4_and_verilog ();
   
   p4_and_verilog_reg_intf  p4_and_verilog_regs();

   // p4_and_verilog register decoder
   p4_and_verilog_decoder p4_and_verilog_decoder (
      .axil_if           (axil_if),					  
      .p4_and_verilog_axil_if   (axil_to_p4_and_verilog)
   );
   
   // p4_and_verilog register block
   p4_and_verilog_reg_blk p4_and_verilog_reg_blk 
   (
    .axil_if    (axil_to_p4_and_verilog),
    .reg_blk_if (p4_and_verilog_regs)                 
   );


   // ----------------------------------------------------------------
   //  Datpath pass-through connections (hard-wired bypass)
   // ----------------------------------------------------------------
   assign axis_to_switch_1.aclk   = axis_from_switch_1.aclk;
   assign axis_to_switch_1.aresetn= axis_from_switch_1.aresetn;
   assign axis_to_switch_1.tvalid = axis_from_switch_1.tvalid;
   assign axis_to_switch_1.tdata  = axis_from_switch_1.tdata;
   assign axis_to_switch_1.tkeep  = axis_from_switch_1.tkeep;
   assign axis_to_switch_1.tlast  = axis_from_switch_1.tlast;
   assign axis_to_switch_1.tid    = axis_from_switch_1.tid;
   assign axis_to_switch_1.tdest  = {'0, axis_from_switch_1.tdest};
   assign axis_to_switch_1.tuser  = axis_from_switch_1.tuser;

   assign axis_from_switch_1.tready = axis_to_switch_1.tready;


   // ----------------------------------------------------------------
   // The SDnet block
   // ----------------------------------------------------------------

   tuser_smartnic_meta_t  axis_from_switch_0_tuser;
   assign axis_from_switch_0_tuser = axis_from_switch_0.tuser;

   tuser_smartnic_meta_t  axis_to_switch_0_tuser;
   assign axis_to_switch_0.tuser = axis_to_switch_0_tuser;

   // --- metadata_in ---
   user_metadata_t user_metadata_in;
   logic           user_metadata_in_valid;
   
   always_comb begin
      user_metadata_in.timestamp_ns      = timestamp;
      user_metadata_in.pid               = axis_from_switch_0_tuser.pid;
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
                                   user_metadata_out.egress_port : user_metadata_out_latch.egress_port;

   assign axis_to_switch_0_tuser.pid         = user_metadata_out_valid ?
                                               user_metadata_out.pid[15:0] : user_metadata_out_latch.pid[15:0];

   assign axis_to_switch_0_tuser.trunc_enable = user_metadata_out_valid ?
                                                user_metadata_out.truncate_enable : user_metadata_out_latch.truncate_enable;

   assign axis_to_switch_0_tuser.trunc_length = user_metadata_out_valid ?
                                                user_metadata_out.truncate_length : user_metadata_out_latch.truncate_length;

   assign axis_to_switch_0_tuser.rss_enable  = user_metadata_out_valid ?
                                               user_metadata_out.rss_enable  : user_metadata_out_latch.rss_enable;

   assign axis_to_switch_0_tuser.rss_entropy = user_metadata_out_valid ?
                                               user_metadata_out.rss_entropy : user_metadata_out_latch.rss_entropy;


   // --- vitisnetp4_igr instance (p4_and_verilog) ---
   vitisnetp4_igr vitisnetp4_igr_p4_and_verilog
   (
    // Clocks & Resets
    .s_axis_aclk             (core_clk),
    .s_axis_aresetn          (core_rstn),
    .s_axi_aclk              (axil_to_vitisnetp4.aclk), 
    .s_axi_aresetn           (axil_to_vitisnetp4.aresetn),
    .cam_mem_aclk            (core_clk),
    .cam_mem_aresetn         (core_rstn),

    // Metadata
    .user_metadata_in        (user_metadata_in),         
    .user_metadata_in_valid  (user_metadata_in_valid),   
    .user_metadata_out       (user_metadata_out),
    .user_metadata_out_valid (user_metadata_out_valid),  
    
    // Slave AXI-lite interface
    .s_axi_awaddr  (axil_to_vitisnetp4.awaddr),
    .s_axi_awvalid (axil_to_vitisnetp4.awvalid),
    .s_axi_awready (axil_to_vitisnetp4.awready),
    .s_axi_wdata   (axil_to_vitisnetp4.wdata),
    .s_axi_wstrb   (axil_to_vitisnetp4.wstrb),
    .s_axi_wvalid  (axil_to_vitisnetp4.wvalid),
    .s_axi_wready  (axil_to_vitisnetp4.wready),
    .s_axi_bresp   (axil_to_vitisnetp4.bresp),
    .s_axi_bvalid  (axil_to_vitisnetp4.bvalid),
    .s_axi_bready  (axil_to_vitisnetp4.bready),
    .s_axi_araddr  (axil_to_vitisnetp4.araddr),
    .s_axi_arvalid (axil_to_vitisnetp4.arvalid),
    .s_axi_arready (axil_to_vitisnetp4.arready),
    .s_axi_rdata   (axil_to_vitisnetp4.rdata),
    .s_axi_rvalid  (axil_to_vitisnetp4.rvalid),
    .s_axi_rready  (axil_to_vitisnetp4.rready),
    .s_axi_rresp   (axil_to_vitisnetp4.rresp),
    
    // AXI Master port
    .m_axis_tdata  (axis_to_switch_0.tdata),
    .m_axis_tkeep  (axis_to_switch_0.tkeep),
    .m_axis_tvalid (axis_to_switch_0.tvalid),
    .m_axis_tlast  (axis_to_switch_0.tlast),
    .m_axis_tready (axis_to_switch_0.tready),

    // AXI Slave port
    .s_axis_tdata  (axis_from_switch_0.tdata),
    .s_axis_tkeep  (axis_from_switch_0.tkeep),
    .s_axis_tvalid (axis_from_switch_0.tvalid),
    .s_axis_tlast  (axis_from_switch_0.tlast),
    .s_axis_tready (axis_from_switch_0.tready)
    );

    assign axis_to_switch_0.aclk = core_clk;
    assign axis_to_switch_0.aresetn = core_rstn;

endmodule: p4_and_verilog
