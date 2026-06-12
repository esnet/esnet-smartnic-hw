// =========================================================================
// Application core (ESnet SmartNIC)
//
// Wraps SmartNIC platform logic as a standard ESnet core.
// =========================================================================
module core
    import shell_pkg::*;
(
    shell_intf.core shell_if
);

    // Signals
    axi4l_intf axil_if ();

    axi4s_intf #(.DATA_BYTE_WID(shell_if.PORT_DATA_BYTE_WID), .TID_WID(PORT_AXIS_TID_WID), .TDEST_WID(PORT_AXIS_TDEST_WID), .TUSER_WID(PORT_AXIS_TUSER_WID)) axis_port_rx [shell_if.NUM_PORTS] (.aclk(shell_if.port_clk[0]));
    axi4s_intf #(.DATA_BYTE_WID(shell_if.PORT_DATA_BYTE_WID), .TID_WID(PORT_AXIS_TID_WID), .TDEST_WID(PORT_AXIS_TDEST_WID), .TUSER_WID(PORT_AXIS_TUSER_WID)) axis_port_tx [shell_if.NUM_PORTS] (.aclk(shell_if.port_clk[0]));

    axi4s_intf #(.DATA_BYTE_WID(shell_if.DMA_ST_DATA_BYTE_WID), .TID_WID(DMA_ST_AXIS_TID_WID), .TDEST_WID(DMA_ST_AXIS_TDEST_WID), .TUSER_WID(DMA_ST_AXIS_TUSER_WID)) axis_h2c (.aclk(shell_if.port_clk[0]));
    axi4s_intf #(.DATA_BYTE_WID(shell_if.DMA_ST_DATA_BYTE_WID), .TID_WID(DMA_ST_AXIS_TID_WID), .TDEST_WID(DMA_ST_AXIS_TDEST_WID), .TUSER_WID(DMA_ST_AXIS_TUSER_WID)) axis_c2h (.aclk(shell_if.port_clk[0]));

    // Convert shell_intf to SV interfaces
    shell_adapter__core i_shell_adapter__core (
        .shell_if,
        .axil_if,
        .axis_port_rx,
        .axis_port_tx,
        .axis_h2c,
        .axis_c2h
    );

    // Instantiate SmartNIC logic
    smartnic_wrapper #(
        .NUM_PORTS ( shell_if.NUM_PORTS )
    ) i_smartnic_wrapper (
        .clk  ( shell_if.clk ),
        .srst ( shell_if.srst ),
        .axil_if,
        .axis_port_rx,
        .axis_port_tx,
        .axis_h2c,
        .axis_c2h
    );

endmodule : core

// =========================================================================
// Wrapper around existing SmartNIC instance (with ONS connectivity).
//
// Could eventually be made obsolete by adopting a generic (and interface-based)
// port interface for the smartnic module.
// =========================================================================
module smartnic_wrapper
    import shell_pkg::*;
#(
    parameter int NUM_PORTS = 2
) (
    input wire logic      clk,
    input wire logic      srst,
    axi4l_intf.peripheral axil_if,
    axi4s_intf.rx         axis_port_rx [NUM_PORTS],
    axi4s_intf.tx         axis_port_tx [NUM_PORTS],
    axi4s_intf.rx         axis_h2c,
    axi4s_intf.tx         axis_c2h
);
    // =========================================================================
    // Signals
    // =========================================================================
    wire logic [NUM_PORTS-1:0]       s_axis_adpt_tx_322mhz_tvalid;
    wire logic [(512*NUM_PORTS)-1:0] s_axis_adpt_tx_322mhz_tdata;
    wire logic [(64*NUM_PORTS)-1:0]  s_axis_adpt_tx_322mhz_tkeep;
    wire logic [NUM_PORTS-1:0]       s_axis_adpt_tx_322mhz_tlast;
    wire logic [(16*NUM_PORTS)-1:0]  s_axis_adpt_tx_322mhz_tid;
    wire logic [(4*NUM_PORTS)-1:0]   s_axis_adpt_tx_322mhz_tdest;
    wire logic [NUM_PORTS-1:0]       s_axis_adpt_tx_322mhz_tuser_err;
    wire logic [NUM_PORTS-1:0]       s_axis_adpt_tx_322mhz_tready;

    wire logic [NUM_PORTS-1:0]       m_axis_adpt_rx_322mhz_tvalid;
    wire logic [(512*NUM_PORTS)-1:0] m_axis_adpt_rx_322mhz_tdata;
    wire logic [(64*NUM_PORTS)-1:0]  m_axis_adpt_rx_322mhz_tkeep;
    wire logic [NUM_PORTS-1:0]       m_axis_adpt_rx_322mhz_tlast;
    wire logic [(4*NUM_PORTS)-1:0]   m_axis_adpt_rx_322mhz_tdest;
    wire logic [NUM_PORTS-1:0]       m_axis_adpt_rx_322mhz_tuser_err;
    wire logic [NUM_PORTS-1:0]       m_axis_adpt_rx_322mhz_tuser_rss_enable;
    wire logic [(12*NUM_PORTS)-1:0]  m_axis_adpt_rx_322mhz_tuser_rss_entropy;
    wire logic [NUM_PORTS-1:0]       m_axis_adpt_rx_322mhz_tready;

    wire logic [NUM_PORTS-1:0]       m_axis_cmac_tx_322mhz_tvalid;
    wire logic [(512*NUM_PORTS)-1:0] m_axis_cmac_tx_322mhz_tdata;
    wire logic [(64*NUM_PORTS)-1:0]  m_axis_cmac_tx_322mhz_tkeep;
    wire logic [NUM_PORTS-1:0]       m_axis_cmac_tx_322mhz_tlast;
    wire logic [(4*NUM_PORTS)-1:0]   m_axis_cmac_tx_322mhz_tdest;
    wire logic [NUM_PORTS-1:0]       m_axis_cmac_tx_322mhz_tuser_err;
    wire logic [NUM_PORTS-1:0]       m_axis_cmac_tx_322mhz_tready;

    wire logic [NUM_PORTS-1:0]       s_axis_cmac_rx_322mhz_tvalid;
    wire logic [(512*NUM_PORTS)-1:0] s_axis_cmac_rx_322mhz_tdata;
    wire logic [(64*NUM_PORTS)-1:0]  s_axis_cmac_rx_322mhz_tkeep;
    wire logic [NUM_PORTS-1:0]       s_axis_cmac_rx_322mhz_tlast;
    wire logic [(4*NUM_PORTS)-1:0]   s_axis_cmac_rx_322mhz_tdest;
    wire logic [NUM_PORTS-1:0]       s_axis_cmac_rx_322mhz_tuser_err;
    wire logic [NUM_PORTS-1:0]       s_axis_cmac_rx_322mhz_tready;

    wire logic [NUM_PORTS-1:0]       cmac_clk;
    wire logic                       core_clk;

    dma_st_axis_tuser_t axis_h2c_tuser;
    dma_st_axis_tid_t   axis_h2c_tid;
    dma_st_axis_tuser_t axis_c2h_tuser;
    dma_st_axis_tid_t   axis_c2h_tid;

    // =========================================================================
    // Smartnic instance
    // =========================================================================
    smartnic        #(
        .NUM_CMAC    ( NUM_PORTS ),
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
        for (genvar g_port = 0; g_port < NUM_PORTS; g_port++) begin : g__port
            // (Local) signals
            port_axis_tuser_t axis_port_rx_tuser;
            port_axis_tuser_t axis_port_tx_tuser;

            // temporarily connect cmac clocks to core_clk (prior to DCMAC instantiations).
            assign cmac_clk[g_port] = core_clk; // axis_port_rx[g_port].aclk;

            // CMAC Rx
            assign s_axis_cmac_rx_322mhz_tvalid[g_port]            = axis_port_rx[g_port].tvalid;
            assign s_axis_cmac_rx_322mhz_tdata [g_port*512 +: 512] = axis_port_rx[g_port].tdata;
            assign s_axis_cmac_rx_322mhz_tkeep [g_port*64  +: 64]  = axis_port_rx[g_port].tkeep;
            assign s_axis_cmac_rx_322mhz_tlast [g_port]            = axis_port_rx[g_port].tlast;
            assign s_axis_cmac_rx_322mhz_tdest [g_port*4   +: 4]   = '0;
            assign axis_port_rx_tuser = axis_port_rx[g_port].tuser;
            assign s_axis_cmac_rx_322mhz_tuser_err [g_port] = axis_port_rx_tuser.err;
            assign axis_port_rx[g_port].tready = s_axis_cmac_rx_322mhz_tready[g_port];

            // CMAC Tx
            assign axis_port_tx[g_port].tvalid = m_axis_cmac_tx_322mhz_tvalid[g_port];
            assign axis_port_tx[g_port].tdata  = m_axis_cmac_tx_322mhz_tdata [g_port*512 +: 512];
            assign axis_port_tx[g_port].tkeep  = m_axis_cmac_tx_322mhz_tkeep [g_port*64  +: 64];
            assign axis_port_tx[g_port].tlast  = m_axis_cmac_tx_322mhz_tlast [g_port];
            assign axis_port_tx[g_port].tid = '0;
            assign axis_port_tx[g_port].tdest = '0;
            assign axis_port_tx_tuser.err = m_axis_cmac_tx_322mhz_tuser_err[g_port];
            assign axis_port_tx[g_port].tuser  = axis_port_tx_tuser;
            assign m_axis_cmac_tx_322mhz_tready[g_port] = axis_port_tx[g_port].tready;
        end : g__port
    endgenerate

    // H2C
    assign s_axis_adpt_tx_322mhz_tvalid[0]            = axis_h2c.tvalid;
    assign s_axis_adpt_tx_322mhz_tdata [0*512 +: 512] = axis_h2c.tdata;
    assign s_axis_adpt_tx_322mhz_tkeep [0*64  +: 64]  = axis_h2c.tkeep;
    assign s_axis_adpt_tx_322mhz_tlast [0]            = axis_h2c.tlast;
    assign s_axis_adpt_tx_322mhz_tdest [0*4   +: 4]   = '0;
    assign s_axis_adpt_tx_322mhz_tuser_err [0]        = axis_h2c.tuser;
    assign axis_h2c_tid = axis_h2c.tid;
    assign s_axis_adpt_tx_322mhz_tid [0*16 +: 16]     = {'0, axis_h2c_tid};
    assign axis_h2c.tready = s_axis_adpt_tx_322mhz_tready[0];

    // C2H
    assign axis_c2h.tvalid = m_axis_adpt_rx_322mhz_tvalid[0];
    assign axis_c2h.tdata  = m_axis_adpt_rx_322mhz_tdata [0*512 +: 512];
    assign axis_c2h.tkeep  = m_axis_adpt_rx_322mhz_tkeep [0*64  +: 64];
    assign axis_c2h.tlast  = m_axis_adpt_rx_322mhz_tlast [0];
    // assign axis_c2h_tid.qid = m_axis_adpt_rx_322mhz_tuser_rss_entropy[0*12 +: DMA_ST_QID_WID];
    // assign axis_c2h.tid = axis_c2h_tid;
    assign axis_c2h.tid    = '0;
    assign axis_c2h.tdest  = '0;
    assign axis_c2h_tuser.rss_enable  = m_axis_adpt_rx_322mhz_tuser_rss_enable[0];
    assign axis_c2h_tuser.rss_entropy = m_axis_adpt_rx_322mhz_tuser_rss_entropy[11:0];
    assign axis_c2h.tuser  = axis_c2h_tuser;
    assign m_axis_adpt_rx_322mhz_tready[0] = axis_c2h.tready;

    // Tie off redundant SmartNIC QDMA channel(s)
    generate
        for (genvar g_ch = 1; g_ch < NUM_PORTS; g_ch++) begin : g__ch
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
