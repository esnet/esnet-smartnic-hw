module p4_app
   import smartnic_322mhz_pkg::*;
#(
   parameter int N = 2  // Number of processor ports.
) (
   input logic        core_clk,
   input logic        core_rstn,
   input timestamp_t  timestamp,

   axi4l_intf.peripheral axil_if,
   axi4l_intf.peripheral axil_to_sdnet,

   axi4s_intf.tx axis_to_switch[N],
   axi4s_intf.rx axis_from_switch[N],

   axi3_intf.controller  axi_to_hbm[16]
);

   // ----------------------------------------------------------------------
   //  axil register map. axil intf, regio block and decoder instantiations.
   // ----------------------------------------------------------------------
   axi4l_intf  axil_to_p4_app ();
   axi4l_intf  axil_to_p4_app__core_clk ();
   axi4l_intf  axil_to_p4_proc ();

   p4_app_reg_intf  p4_app_regs ();

   // p4_app register decoder
   p4_app_decoder p4_app_decoder (
      .axil_if          (axil_if),
      .p4_app_axil_if   (axil_to_p4_app),
      .p4_proc_axil_if  (axil_to_p4_proc)
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
    .reg_blk_if (p4_app_regs)
   );


   // ----------------------------------------------------------------------
   // p4 processor complex instantiation.
   // ----------------------------------------------------------------------
   p4_proc #(.N(N)) p4_proc_0 (
      .core_clk         (core_clk),
      .core_rstn        (core_rstn),
      .timestamp        (timestamp),

      .axil_if          (axil_to_p4_proc),
      .axil_to_sdnet    (axil_to_sdnet),

      .axis_to_switch   (axis_to_switch),
      .axis_from_switch (axis_from_switch),

      .axi_to_hbm       (axi_to_hbm)
   );

endmodule: p4_app
