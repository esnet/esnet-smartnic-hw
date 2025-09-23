module p2p #(
) (
    input logic           core_clk,
    input logic           core_rstn,

    axi4l_intf.peripheral axil_if,

    axi4s_intf.rx         axis_in,
    axi4s_intf.tx         axis_out
);

    // ----------------------------------------------------------------
    //  Register map block instantiations
    // ----------------------------------------------------------------
    p2p_reg_intf  p2p_regs ();

    logic tpause;

    // p2p register block
    p2p_reg_blk p2p_reg_blk (
        .axil_if    ( axil_if ),
        .reg_blk_if ( p2p_regs )
    );

   // Synchronize tpause
   sync_level #(
       .RST_VALUE ( 1'b0 )
   ) i_sync_level__tpause (
       .clk_in  (axil_if.aclk),
       .rst_in  (!axil_if.aresetn),
       .rdy_in  ( ),
       .lvl_in  (p2p_regs.tpause),
       .clk_out (core_clk),
       .rst_out (!core_rstn),
       .lvl_out (tpause)
   );

   // ----------------------------------------------------------------
   //  Datpath pass-through connections (hard-wired bypass)
   // ----------------------------------------------------------------
   assign axis_out.tvalid = axis_in.tvalid && !tpause;
   assign axis_out.tdata  = axis_in.tdata;
   assign axis_out.tkeep  = axis_in.tkeep;
   assign axis_out.tlast  = axis_in.tlast;
   assign axis_out.tid    = axis_in.tid;
   assign axis_out.tdest  = axis_in.tdest;
   assign axis_out.tuser  = axis_in.tuser;

   assign axis_in.tready = axis_out.tready && !tpause;

endmodule: p2p
