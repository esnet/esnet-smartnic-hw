// =============================================================================
//  NOTICE: This computer software was prepared by The Regents of the
//  University of California through Lawrence Berkeley National Laboratory
//  and Yatish Kumar  hereinafter the Contractor, under Contract No.
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
module smartnic_322mhz_reset #(
  parameter int NUM_CMAC = 1
) (
  // Generic signal pair for reset
  input 		mod_rstn,
  output reg 		mod_rst_done,

  output 		axil_aresetn,
  output [NUM_CMAC-1:0] cmac_rstn,
  input 		axil_aclk,
  input [NUM_CMAC-1:0] 	cmac_clk,

  output 		core_rstn,
  output 		core_clk        // we synthesize this clock in this block
   
);

  localparam C_RESET_DURATION = 100;

  wire       rstn;
  reg        reset_in_progress = 1'b0;
  reg [15:0] reset_timer = 0;

  // Local reset `rstn` will be asserted for at least 2 cycles asynchronously,
  // and deasserted synchronously with the clock
  xpm_cdc_async_rst #(
    .DEST_SYNC_FF    (2),
    .INIT_SYNC_FF    (0),
    .RST_ACTIVE_HIGH (0)
  ) axil_rst_inst (
    .src_arst  (mod_rstn),
    .dest_arst (rstn),
    .dest_clk  (axil_aclk)
  );

  initial mod_rst_done = 1'b0;
  always @(posedge axil_aclk) begin
    if (~reset_in_progress && ~rstn) begin
      reset_in_progress <= 1'b1;
      mod_rst_done      <= 1'b0;
    end
    else if (reset_in_progress && (reset_timer >= C_RESET_DURATION)) begin
      reset_in_progress <= 1'b0;
      mod_rst_done      <= 1'b1;
    end
  end

  always @(posedge axil_aclk) begin
    if (reset_in_progress) begin
      reset_timer <= reset_timer + 1;
    end
    else begin
      reset_timer <= 0;
    end
  end

  assign axil_aresetn = ~reset_in_progress;

  // CMAC domain resets are generated from the locally generated AXI-lite reset
  generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin
    xpm_cdc_async_rst #(
      .DEST_SYNC_FF    (2),
      .INIT_SYNC_FF    (0),
      .RST_ACTIVE_HIGH (0)
    ) cmac_rst_inst (
      .src_arst  (axil_aresetn),
      .dest_arst (cmac_rstn[i]),
      .dest_clk  (cmac_clk[i])
    );
  end
  endgenerate


 // core clock domain resets are generated from the locally generated AXI-lite reset
 // core clock domain is asynnchronous wrt. CMAC domains, and is derived from AXI-lite via a PLL
   
  xpm_cdc_async_rst #(
    .DEST_SYNC_FF    (2),
    .INIT_SYNC_FF    (0),
    .RST_ACTIVE_HIGH (0)
  ) core_rst_inst (
    .src_arst  (axil_aresetn),
    .dest_arst (core_rstn),
    .dest_clk  (core_clk)
  );

   clk_wiz_0 axi_to_core_clk(
			      .clk_in1     ( axil_aclk ),
			      .clk_out1    ( core_clk )
			      );

endmodule: smartnic_322mhz_reset