// =============================================================================
// Versal AVED AXI-L debug core
//
// Sits between xilinx_aved_adapter and xilinx_aved_shell_adapter.
// Purely combinational on the data path — zero added latency.
//
// ILA: captures all AXI4-Lite channel signals as individual probes.
//
// VIO (read-only probes):
//   aresetn        — current reset state
//   clk_toggle     — free-running 1-bit toggle; confirms clk is live
//   rd_count       — AR transactions accepted (arvalid && arready)
//   wr_count       — AW transactions accepted (awvalid && awready)
//   rd_resp_count  — R responses completed  (rvalid  && rready)
//   wr_resp_count  — B responses completed  (bvalid  && bready)
//   rd_last_addr   — araddr of the most recent AR transaction
//   wr_last_addr   — awaddr of the most recent AW transaction
//   rd_last_data   — rdata  of the most recent R response
//   wr_last_data   — wdata  of the most recent W transaction
//   rd_last_resp   — rresp  of the most recent R response
//   wr_last_resp   — bresp  of the most recent B response
// =============================================================================
module xilinx_aved_debug (
    axi4l_intf.peripheral axil_if_from_adapter,
    axi4l_intf.controller axil_if_to_shell
);
    // =========================================================================
    // Pass-through — zero latency
    // =========================================================================
    axi4l_intf_connector i_connector (
        .axi4l_if_from_controller ( axil_if_from_adapter ),
        .axi4l_if_to_peripheral   ( axil_if_to_shell     )
    );

    // =========================================================================
    // Clocks / reset (sourced from the interface)
    // =========================================================================
    wire clk    = axil_if_from_adapter.aclk;
    wire aresetn = axil_if_from_adapter.aresetn;

    // =========================================================================
    // ILA — AXI4-Lite channel signals (individual probes)
    // =========================================================================
    xilinx_aved_axil_ila i_ila (
        .clk      ( clk ),
        // Read address channel
        .probe0   ( axil_if_from_adapter.araddr  ),
        .probe1   ( axil_if_from_adapter.arprot  ),
        .probe2   ( axil_if_from_adapter.arvalid ),
        .probe3   ( axil_if_from_adapter.arready ),
        // Write address channel
        .probe4   ( axil_if_from_adapter.awaddr  ),
        .probe5   ( axil_if_from_adapter.awprot  ),
        .probe6   ( axil_if_from_adapter.awvalid ),
        .probe7   ( axil_if_from_adapter.awready ),
        // Write data channel
        .probe8   ( axil_if_from_adapter.wdata   ),
        .probe9   ( axil_if_from_adapter.wstrb   ),
        .probe10  ( axil_if_from_adapter.wvalid  ),
        .probe11  ( axil_if_from_adapter.wready  ),
        // Read data channel
        .probe12  ( axil_if_from_adapter.rdata   ),
        .probe13  ( axil_if_from_adapter.rresp   ),
        .probe14  ( axil_if_from_adapter.rvalid  ),
        .probe15  ( axil_if_from_adapter.rready  ),
        // Write response channel
        .probe16  ( axil_if_from_adapter.bresp   ),
        .probe17  ( axil_if_from_adapter.bvalid  ),
        .probe18  ( axil_if_from_adapter.bready  )
    );

    // =========================================================================
    // VIO diagnostic counters / registers
    // =========================================================================
    logic        clk_toggle;
    logic [31:0] rd_count;
    logic [31:0] wr_count;
    logic [31:0] rd_resp_count;
    logic [31:0] wr_resp_count;
    logic [31:0] rd_last_addr;
    logic [31:0] wr_last_addr;
    logic [31:0] rd_last_data;
    logic [31:0] wr_last_data;
    logic  [1:0] rd_last_resp;
    logic  [1:0] wr_last_resp;

    always_ff @(posedge clk) begin
        clk_toggle <= ~clk_toggle;

        if (!aresetn) begin
            rd_count       <= '0;
            wr_count       <= '0;
            rd_resp_count  <= '0;
            wr_resp_count  <= '0;
            rd_last_addr   <= '0;
            wr_last_addr   <= '0;
            rd_last_data   <= '0;
            wr_last_data   <= '0;
            rd_last_resp   <= '0;
            wr_last_resp   <= '0;
        end else begin
            if (axil_if_from_adapter.arvalid && axil_if_from_adapter.arready) begin
                rd_count     <= rd_count + 1;
                rd_last_addr <= axil_if_from_adapter.araddr;
            end
            if (axil_if_from_adapter.awvalid && axil_if_from_adapter.awready) begin
                wr_count     <= wr_count + 1;
                wr_last_addr <= axil_if_from_adapter.awaddr;
            end
            if (axil_if_from_adapter.wvalid && axil_if_from_adapter.wready)
                wr_last_data <= axil_if_from_adapter.wdata;
            if (axil_if_from_adapter.rvalid && axil_if_from_adapter.rready) begin
                rd_resp_count <= rd_resp_count + 1;
                rd_last_data  <= axil_if_from_adapter.rdata;
                rd_last_resp  <= axil_if_from_adapter.rresp;
            end
            if (axil_if_from_adapter.bvalid && axil_if_from_adapter.bready) begin
                wr_resp_count <= wr_resp_count + 1;
                wr_last_resp  <= axil_if_from_adapter.bresp;
            end
        end
    end

    xilinx_aved_debug_vio i_vio (
        .clk         ( clk           ),
        .probe_in0   ( aresetn        ),
        .probe_in1   ( clk_toggle     ),
        .probe_in2   ( rd_count       ),
        .probe_in3   ( wr_count       ),
        .probe_in4   ( rd_resp_count  ),
        .probe_in5   ( wr_resp_count  ),
        .probe_in6   ( rd_last_addr   ),
        .probe_in7   ( wr_last_addr   ),
        .probe_in8   ( rd_last_data   ),
        .probe_in9   ( wr_last_data   ),
        .probe_in10  ( rd_last_resp   ),
        .probe_in11  ( wr_last_resp   )
    );

endmodule : xilinx_aved_debug
