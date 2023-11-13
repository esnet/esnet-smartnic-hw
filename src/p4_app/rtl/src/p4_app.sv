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
   import p4_app_pkg::*;
   import axi4s_pkg::*;

   // ----------------------------------------------------------------
   //  Register map block and decoder instantiations
   // ----------------------------------------------------------------

   axi4l_intf  axil_to_p4_app ();
   axi4l_intf  axil_to_p4_app__core_clk ();
   
   p4_app_reg_intf  p4_app_regs [2] ();

   // p4_app register decoder
   p4_app_decoder p4_app_decoder (
      .axil_if          (axil_if),
      .p4_app_axil_if   (axil_to_p4_app)
   );

   
   // Pass AXI-L interface from aclk (AXI-L clock) to core clk domain
   axi4l_intf_cdc i_axil_intf_cdc (
       .axi4l_if_from_controller   ( axil_to_p4_app ),
       .clk_to_peripheral          ( core_clk ),
       .axi4l_if_to_peripheral     ( axil_to_p4_app__core_clk )
   );

   // p4_app register block
   p4_app_reg_blk p4_app_reg_blk 
   (
    .axil_if    (axil_to_p4_app__core_clk),
    .reg_blk_if (p4_app_regs[0])
   );

   // p4_app register pipeline stages
   always @(posedge core_clk) begin
      p4_app_regs[1].trunc_config <= p4_app_regs[0].trunc_config;
      p4_app_regs[1].rss_config   <= p4_app_regs[0].rss_config;
   end

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

   // metadata type definitions (from xilinx_ip/<app_name>/sdnet_0/src/verilog/sdnet_0_pkg.sv).
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

   assign axis_to_switch_0_tuser.pid         = user_metadata_out_valid ? user_metadata_out.pid[15:0]   : user_metadata_out_latch.pid[15:0];

   assign axis_to_switch_0_tuser.trunc_enable = p4_app_regs[1].trunc_config.enable ? p4_app_regs[1].trunc_config.trunc_enable :
                                               (user_metadata_out_valid ? user_metadata_out.truncate_enable : user_metadata_out_latch.truncate_enable);

   assign axis_to_switch_0_tuser.trunc_length = p4_app_regs[1].trunc_config.enable ? p4_app_regs[1].trunc_config.trunc_length :
                                               (user_metadata_out_valid ? user_metadata_out.truncate_length : user_metadata_out_latch.truncate_length);

   assign axis_to_switch_0_tuser.rss_enable  = p4_app_regs[1].rss_config.enable ? p4_app_regs[1].rss_config.rss_enable :
                                               (user_metadata_out_valid ? user_metadata_out.rss_enable  : user_metadata_out_latch.rss_enable);

   assign axis_to_switch_0_tuser.rss_entropy = p4_app_regs[1].rss_config.enable ? p4_app_regs[1].rss_config.rss_entropy :
                                               (user_metadata_out_valid ? user_metadata_out.rss_entropy : user_metadata_out_latch.rss_entropy);


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

   assign axis_to_switch_0.aclk = core_clk;
   assign axis_to_switch_0.aresetn = core_rstn;
   assign axis_to_switch_0.tid = '0;

endmodule: p4_app
