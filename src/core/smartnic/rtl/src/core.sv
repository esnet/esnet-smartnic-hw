// =========================================================================
// Application core (ESnet SmartNIC)
//
// Wraps SmartNIC platform logic as a standard ESnet core.
// =========================================================================
module core 
    import shell_pkg::*;
(
    // Clock/reset
    input  wire logic clk,
    input  wire logic srst,

    input  wire logic mgmt_clk,
    input  wire logic mgmt_srst,

    input  wire logic clk_100mhz,

    // Shell interface
    input  wire logic [SHELL_TO_CORE_WID-1:0] shell_to_core,
    output wire logic [CORE_TO_SHELL_WID-1:0] core_to_shell
);

    // Signals
    axi4l_intf axil_if ();

    axi4s_intf #(.DATA_BYTE_WID(CMAC_DATA_BYTE_WID), .TID_WID(CMAC_AXIS_TID_WID), .TDEST_WID(CMAC_AXIS_TDEST_WID), .TUSER_WID(CMAC_AXIS_TUSER_WID)) axis_cmac_rx [NUM_CMAC] (.aclk(clk), .aresetn(!srst));
    axi4s_intf #(.DATA_BYTE_WID(CMAC_DATA_BYTE_WID), .TID_WID(CMAC_AXIS_TID_WID), .TDEST_WID(CMAC_AXIS_TDEST_WID), .TUSER_WID(CMAC_AXIS_TUSER_WID)) axis_cmac_tx [NUM_CMAC] (.aclk(clk), .aresetn(!srst));

    axi4s_intf #(.DATA_BYTE_WID(DMA_ST_DATA_BYTE_WID), .TID_WID(DMA_ST_AXIS_TID_WID), .TDEST_WID(DMA_ST_AXIS_TDEST_WID), .TUSER_WID(DMA_ST_AXIS_TUSER_WID)) axis_h2c (.aclk(clk), .aresetn(!srst));
    axi4s_intf #(.DATA_BYTE_WID(DMA_ST_DATA_BYTE_WID), .TID_WID(DMA_ST_AXIS_TID_WID), .TDEST_WID(DMA_ST_AXIS_TDEST_WID), .TUSER_WID(DMA_ST_AXIS_TUSER_WID)) axis_c2h (.aclk(clk), .aresetn(!srst));

    // Convert flat signal representation to interfaces
    shell_adapter__core i_shell_adapter__core (.*);

    // Instantiate SmartNIC logic
    smartnic_wrapper  i_smartnic_wrapper (.*);

endmodule : core

// =========================================================================
// Wrapper around existing SmartNIC instance (with ONS connectivity).
//
// Could eventually be made obsolete by adopting a generic (and interface-based)
// port interface for the smartnic module.
// =========================================================================
module smartnic_wrapper
    import shell_pkg::*;
(
    input wire logic      clk,
    input wire logic      srst,
    axi4l_intf.peripheral axil_if,
    axi4s_intf.rx         axis_cmac_rx [NUM_CMAC],
    axi4s_intf.tx         axis_cmac_tx [NUM_CMAC],
    axi4s_intf.rx         axis_h2c,
    axi4s_intf.tx         axis_c2h
);
    // =========================================================================
    // Signals
    // =========================================================================
    wire logic [NUM_CMAC-1:0]       s_axis_adpt_tx_322mhz_tvalid;
    wire logic [(512*NUM_CMAC)-1:0] s_axis_adpt_tx_322mhz_tdata;
    wire logic [(64*NUM_CMAC)-1:0]  s_axis_adpt_tx_322mhz_tkeep;
    wire logic [NUM_CMAC-1:0]       s_axis_adpt_tx_322mhz_tlast;
    wire logic [(16*NUM_CMAC)-1:0]  s_axis_adpt_tx_322mhz_tid;
    wire logic [(4*NUM_CMAC)-1:0]   s_axis_adpt_tx_322mhz_tdest;
    wire logic [NUM_CMAC-1:0]       s_axis_adpt_tx_322mhz_tuser_err;
    wire logic [NUM_CMAC-1:0]       s_axis_adpt_tx_322mhz_tready;

    wire logic [NUM_CMAC-1:0]       m_axis_adpt_rx_322mhz_tvalid;
    wire logic [(512*NUM_CMAC)-1:0] m_axis_adpt_rx_322mhz_tdata;
    wire logic [(64*NUM_CMAC)-1:0]  m_axis_adpt_rx_322mhz_tkeep;
    wire logic [NUM_CMAC-1:0]       m_axis_adpt_rx_322mhz_tlast;
    wire logic [(4*NUM_CMAC)-1:0]   m_axis_adpt_rx_322mhz_tdest;
    wire logic [NUM_CMAC-1:0]       m_axis_adpt_rx_322mhz_tuser_err;
    wire logic [NUM_CMAC-1:0]       m_axis_adpt_rx_322mhz_tuser_rss_enable;
    wire logic [(12*NUM_CMAC)-1:0]  m_axis_adpt_rx_322mhz_tuser_rss_entropy;
    wire logic [NUM_CMAC-1:0]       m_axis_adpt_rx_322mhz_tready;

    wire logic [NUM_CMAC-1:0]       m_axis_cmac_tx_322mhz_tvalid;
    wire logic [(512*NUM_CMAC)-1:0] m_axis_cmac_tx_322mhz_tdata;
    wire logic [(64*NUM_CMAC)-1:0]  m_axis_cmac_tx_322mhz_tkeep;
    wire logic [NUM_CMAC-1:0]       m_axis_cmac_tx_322mhz_tlast;
    wire logic [(4*NUM_CMAC)-1:0]   m_axis_cmac_tx_322mhz_tdest;
    wire logic [NUM_CMAC-1:0]       m_axis_cmac_tx_322mhz_tuser_err;
    wire logic [NUM_CMAC-1:0]       m_axis_cmac_tx_322mhz_tready;

    wire logic [NUM_CMAC-1:0]       s_axis_cmac_rx_322mhz_tvalid;
    wire logic [(512*NUM_CMAC)-1:0] s_axis_cmac_rx_322mhz_tdata;
    wire logic [(64*NUM_CMAC)-1:0]  s_axis_cmac_rx_322mhz_tkeep;
    wire logic [NUM_CMAC-1:0]       s_axis_cmac_rx_322mhz_tlast;
    wire logic [(4*NUM_CMAC)-1:0]   s_axis_cmac_rx_322mhz_tdest;
    wire logic [NUM_CMAC-1:0]       s_axis_cmac_rx_322mhz_tuser_err;
    wire logic [NUM_CMAC-1:0]       s_axis_cmac_rx_322mhz_tready;

    wire logic [NUM_CMAC-1:0]       cmac_clk;

    dma_st_axis_tuser_t axis_h2c_tuser;
    dma_st_axis_tid_t   axis_h2c_tid;
    dma_st_axis_tuser_t axis_c2h_tuser;
    dma_st_axis_tid_t   axis_c2h_tid;

    // =========================================================================
    // Smartnic instance
    // =========================================================================
    smartnic        #(
        .NUM_CMAC    ( NUM_CMAC ),
        .MAX_PKT_LEN ( 9600 )
    ) smartnic (
        .s_axil_awvalid ( axil_if.awvalid ),
        .s_axil_awaddr  ( axil_if.awaddr ),
        .s_axil_awready ( axil_if.awready ),
        .s_axil_wvalid  ( axil_if.wvalid ),
        .s_axil_wdata   ( axil_if.wdata ),
        .s_axil_wready  ( axil_if.wready ),
        .s_axil_bvalid  ( axil_if.bvalid ),
        .s_axil_bresp   ( axil_if.bresp.raw ),
        .s_axil_bready  ( axil_if.bready ),
        .s_axil_arvalid ( axil_if.arvalid ),
        .s_axil_araddr  ( axil_if.araddr ),
        .s_axil_arready ( axil_if.arready ),
        .s_axil_rvalid  ( axil_if.rvalid ),
        .s_axil_rdata   ( axil_if.rdata ),
        .s_axil_rresp   ( axil_if.rresp ),
        .s_axil_rready  ( axil_if.rready ),

        .mod_rstn ( !srst ),
        .mod_rst_done ( ),

        .axil_aclk ( axil_if.aclk ),

        .*
    );

    generate
        for (genvar g_cmac = 0; g_cmac < NUM_CMAC; g_cmac++) begin : g__cmac
            // (Local) signals
            cmac_axis_tuser_t axis_cmac_rx_tuser;
            cmac_axis_tuser_t axis_cmac_tx_tuser;

            // CMAC Rx
            assign s_axis_cmac_rx_322mhz_tvalid[g_cmac]            = axis_cmac_rx[g_cmac].tvalid;
            assign s_axis_cmac_rx_322mhz_tdata [g_cmac*512 +: 512] = axis_cmac_rx[g_cmac].tdata;
            assign s_axis_cmac_rx_322mhz_tkeep [g_cmac*64  +: 64]  = axis_cmac_rx[g_cmac].tkeep;
            assign s_axis_cmac_rx_322mhz_tlast [g_cmac]            = axis_cmac_rx[g_cmac].tlast;
            assign s_axis_cmac_rx_322mhz_tdest [g_cmac*4   +: 4]   = '0;
            assign axis_cmac_rx_tuser = axis_cmac_rx[g_cmac].tuser;
            assign s_axis_cmac_rx_322mhz_tuser_err [g_cmac] = axis_cmac_rx_tuser.err;
            assign axis_cmac_rx[g_cmac].tready = s_axis_cmac_rx_322mhz_tready[g_cmac];
            assign cmac_clk[g_cmac] = axis_cmac_rx[g_cmac].aclk;

            // CMAC Tx
            assign axis_cmac_tx[g_cmac].tvalid = m_axis_cmac_tx_322mhz_tvalid[g_cmac];
            assign axis_cmac_tx[g_cmac].tdata  = m_axis_cmac_tx_322mhz_tdata [g_cmac*512 +: 512];
            assign axis_cmac_tx[g_cmac].tkeep  = m_axis_cmac_tx_322mhz_tkeep [g_cmac*64  +: 64];
            assign axis_cmac_tx[g_cmac].tlast  = m_axis_cmac_tx_322mhz_tlast [g_cmac];
            assign axis_cmac_tx[g_cmac].tid = '0;
            assign axis_cmac_tx[g_cmac].tdest = '0;
            assign axis_cmac_tx_tuser.err = m_axis_cmac_tx_322mhz_tuser_err[g_cmac];
            assign axis_cmac_tx[g_cmac].tuser  = axis_cmac_tx_tuser;
            assign m_axis_cmac_tx_322mhz_tready[g_cmac] = axis_cmac_tx[g_cmac].tready;
        end : g__cmac
    endgenerate

    // H2C
    assign s_axis_adpt_tx_322mhz_tvalid[0]            = axis_h2c.tvalid;
    assign s_axis_adpt_tx_322mhz_tdata [0*512 +: 512] = axis_h2c.tdata;
    assign s_axis_adpt_tx_322mhz_tkeep [0*64  +: 64]  = axis_h2c.tkeep;
    assign s_axis_adpt_tx_322mhz_tlast [0]            = axis_h2c.tlast;
    assign s_axis_adpt_tx_322mhz_tdest [0*4   +: 4]   = '0;
    assign axis_h2c_tuser = axis_h2c.tuser;
    assign s_axis_adpt_tx_322mhz_tuser_err [0] = axis_h2c_tuser.err;
    assign axis_h2c_tid = axis_h2c.tid;
    assign s_axis_adpt_tx_322mhz_tid [0] = {'0, axis_h2c_tid.qid};
    assign axis_h2c.tready = s_axis_adpt_tx_322mhz_tready[0];

    // C2H
    assign axis_c2h.tvalid = m_axis_adpt_rx_322mhz_tvalid[0];
    assign axis_c2h.tdata  = m_axis_adpt_rx_322mhz_tdata [0*512 +: 512];
    assign axis_c2h.tkeep  = m_axis_adpt_rx_322mhz_tkeep [0*64  +: 64];
    assign axis_c2h.tlast  = m_axis_adpt_rx_322mhz_tlast [0];
    assign axis_c2h_tid.qid = m_axis_adpt_rx_322mhz_tuser_rss_entropy[0*12 +: DMA_ST_QID_WID];
    assign axis_c2h.tid = axis_c2h_tid;
    assign axis_c2h.tdest = '0;
    assign axis_c2h_tuser.err = m_axis_adpt_rx_322mhz_tuser_err[0];
    assign axis_c2h.tuser  = axis_c2h_tuser;
    assign m_axis_adpt_rx_322mhz_tready[0] = axis_c2h.tready;
    assign axis_c2h.aclk = clk;
    assign axis_c2h.aresetn = !srst;

    // Tie off redunandant SmartNIC QDMA channel(s)
    generate
        for (genvar g_ch = 1; g_ch < NUM_CMAC; g_ch++) begin : g__ch
            assign s_axis_adpt_tx_322mhz_tvalid[g_ch]            = 1'b0;
            assign s_axis_adpt_tx_322mhz_tdata [g_ch*512 +: 512] = '0;
            assign s_axis_adpt_tx_322mhz_tkeep [g_ch*64  +: 64]  = '0;
            assign s_axis_adpt_tx_322mhz_tlast [g_ch]            = 1'b0;
            assign s_axis_adpt_tx_322mhz_tid   [g_ch*16  +: 16]  = '0;
            assign s_axis_adpt_tx_322mhz_tdest [g_ch*4   +:  4]  = '0;
            assign s_axis_adpt_tx_322mhz_tuser_err [g_ch] = 1'b0;

            assign m_axis_adpt_rx_322mhz_tready[g_ch] = 1'b0;
        end : g__ch
    endgenerate

endmodule : smartnic_wrapper
