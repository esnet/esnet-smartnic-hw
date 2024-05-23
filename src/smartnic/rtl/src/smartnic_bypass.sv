module smartnic_bypass #(
    parameter int  MAX_PKT_LEN = 9100
) (
    input logic    core_clk,
    input logic    core_rstn,

    axi4s_intf.rx  axis_core_to_bypass,
    axi4s_intf.tx  axis_bypass_to_core,

    axi4l_intf.peripheral   axil_to_drops_from_igr_sw,
    axi4l_intf.peripheral   axil_to_probe_to_bypass,
    axi4l_intf.peripheral   axil_to_drops_from_bypass,

    smartnic_reg_intf.peripheral   smartnic_regs
);
    import smartnic_pkg::*;

    // ----------------------------------------------------------------
    //  axi4l and axi4s interface instantiations
    // ----------------------------------------------------------------
    axi4l_intf  axil_to_ovfl_to_bypass ();
    axi4l_intf  axil_to_fifo_to_bypass ();

    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  axis_igr_sw_drop ();
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  axis_to_bypass_fifo ();
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  axis_from_bypass_fifo ();
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  axis_from_bypass_fifo_p ();
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  axis_to_bypass_drop ();


    // ingress switch drop pkt logic.  deletes packets that have tdest == 3 (igr_sw DROP code point).
    logic  igr_sw_drop_pkt;
    assign igr_sw_drop_pkt = axis_core_to_bypass.tvalid && axis_core_to_bypass.sop &&
                             axis_core_to_bypass.tdest.raw == 2'h3;

    // igr_sw_drop axi4s_drop instantiation.
    axi4s_drop igr_sw_drop_0 (
       .axi4s_in    (axis_core_to_bypass),
       .axi4s_out   (axis_igr_sw_drop),
       .axil_if     (axil_to_drops_from_igr_sw),
       .drop_pkt    (igr_sw_drop_pkt)
    );

    axi4s_intf_pipe axis_to_bypass_pipe_0 (.axi4s_if_from_tx(axis_igr_sw_drop), .axi4s_if_to_rx(axis_to_bypass_fifo));

    axi4s_pkt_fifo_sync #(
       .FIFO_DEPTH     (256),
       .MAX_PKT_LEN    (MAX_PKT_LEN)
    ) bypass_fifo (
       .srst           (1'b0),
       .axi4s_in       (axis_to_bypass_fifo),
       .axi4s_out      (axis_from_bypass_fifo),
       .axil_to_probe  (axil_to_probe_to_bypass),
       .axil_to_ovfl   (axil_to_ovfl_to_bypass),
       .axil_if        (axil_to_fifo_to_bypass)
    );

    axi4l_intf_controller_term axi4l_to_ovfl_to_bypass_term  (.axi4l_if (axil_to_ovfl_to_bypass));
    axi4l_intf_controller_term axi4l_to_fifo_to_bypass_term  (.axi4l_if (axil_to_fifo_to_bypass));

    axi4s_intf_pipe from_bypass_pipe_0 (.axi4s_if_from_tx(axis_from_bypass_fifo), .axi4s_if_to_rx(axis_from_bypass_fifo_p));

    // Bypass path assignments.
    assign axis_from_bypass_fifo_p.tready = axis_to_bypass_drop.tready;

    assign axis_to_bypass_drop.aclk    = axis_from_bypass_fifo_p.aclk;
    assign axis_to_bypass_drop.aresetn = axis_from_bypass_fifo_p.aresetn;
    assign axis_to_bypass_drop.tvalid  = axis_from_bypass_fifo_p.tvalid;
    assign axis_to_bypass_drop.tdata   = axis_from_bypass_fifo_p.tdata;
    assign axis_to_bypass_drop.tkeep   = axis_from_bypass_fifo_p.tkeep;
    assign axis_to_bypass_drop.tlast   = axis_from_bypass_fifo_p.tlast;
    assign axis_to_bypass_drop.tid     = axis_from_bypass_fifo_p.tid;
    assign axis_to_bypass_drop.tuser   = axis_from_bypass_fifo_p.tuser;

    // muxing logic for bypass tid-to-tdest mapping.
    always @(posedge core_clk) begin
        if (axis_from_bypass_fifo.tready && axis_from_bypass_fifo.tvalid && axis_from_bypass_fifo.sop) begin
            case (axis_from_bypass_fifo.tid)
                CMAC_PORT0 : axis_to_bypass_drop.tdest <= smartnic_regs.bypass_tdest[0];
                CMAC_PORT1 : axis_to_bypass_drop.tdest <= smartnic_regs.bypass_tdest[1];
                HOST_PORT0 : axis_to_bypass_drop.tdest <= smartnic_regs.bypass_tdest[2];
                HOST_PORT1 : axis_to_bypass_drop.tdest <= smartnic_regs.bypass_tdest[3];
            endcase
        end
    end

    // bypass packet drop logic.  deletes packets that have tdest == tid (to prevent switching loops).
    logic  bypass_drop_pkt;
    assign bypass_drop_pkt = smartnic_regs.switch_config.drop_pkt_loop &&
                             axis_to_bypass_drop.tvalid && axis_to_bypass_drop.sop &&
                             axis_to_bypass_drop.tdest == axis_to_bypass_drop.tid;

    // bypass packet drop instantiation.
    axi4s_drop bypass_drop_0 (
        .axi4s_in    (axis_to_bypass_drop),
        .axi4s_out   (axis_bypass_to_core),
        .axil_if     (axil_to_drops_from_bypass),
        .drop_pkt    (bypass_drop_pkt)
    );

endmodule // smartnic_bypass
