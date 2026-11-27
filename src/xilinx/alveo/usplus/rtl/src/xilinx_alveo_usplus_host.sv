module xilinx_alveo_usplus_host
#(
    parameter int PCIE_LINK_WID = 16
) (
    // From/to pins
    // -- PCIe
    input  logic                     pcie_rstn,
    input  logic                     pcie_refclk_p,
    input  logic                     pcie_refclk_n,
    input  logic [PCIE_LINK_WID-1:0] pcie_rxp,
    input  logic [PCIE_LINK_WID-1:0] pcie_rxn,
    output logic [PCIE_LINK_WID-1:0] pcie_txp,
    output logic [PCIE_LINK_WID-1:0] pcie_txn,
    // Clocks (output)
    output logic                     clk_125mhz,
    output logic                     clk_250mhz,
    // -- AXI-L (Controller)
    axi4l_intf.controller            axil_if,
    // -- DMA (streaming)
    output logic                     dma_aclk,
    output logic                     dma_aresetn,
    packet_intf.tx                   pkt_h2c_dma,
    packet_intf.rx                   pkt_c2h_dma
);

    // =========================================================================
    // Imports
    // =========================================================================
    import xilinx_qdma_pkg::*;

    // =========================================================================
    // Signals
    // =========================================================================
    logic                axi_aclk;
    logic                axi_aresetn;
    logic [15 : 0]       dsc_crdt_in_crdt;
    logic [10 : 0]       dsc_crdt_in_qid;
    logic                dsc_crdt_in_dir;
    logic                dsc_crdt_in_fence;
    logic                dsc_crdt_in_vld;
    logic                dsc_crdt_in_rdy;
    logic [511 : 0]      m_axis_h2c_tdata;
    logic [31 : 0]       m_axis_h2c_tcrc;
    logic [10 : 0]       m_axis_h2c_tuser_qid;
    logic [2 : 0]        m_axis_h2c_tuser_port_id;
    logic                m_axis_h2c_tuser_err;
    logic [31 : 0]       m_axis_h2c_tuser_mdata;
    logic [5 : 0]        m_axis_h2c_tuser_mty;
    logic                m_axis_h2c_tuser_zero_byte;
    logic                m_axis_h2c_tvalid;
    logic                m_axis_h2c_tlast;
    logic                m_axis_h2c_tready;
    logic [511 : 0]      s_axis_c2h_tdata;
    logic [31 : 0]       s_axis_c2h_tcrc;
    logic                s_axis_c2h_ctrl_marker;
    logic [2 : 0]        s_axis_c2h_ctrl_port_id;
    logic [6 : 0]        s_axis_c2h_ctrl_ecc;
    logic [15 : 0]       s_axis_c2h_ctrl_len;
    logic [10 : 0]       s_axis_c2h_ctrl_qid;
    logic                s_axis_c2h_ctrl_has_cmpt;
    logic [5 : 0]        s_axis_c2h_mty;
    logic                s_axis_c2h_tvalid;
    logic                s_axis_c2h_tlast;
    logic                s_axis_c2h_tready;
    logic [511 : 0]      s_axis_c2h_cmpt_tdata;
    logic [1 : 0]        s_axis_c2h_cmpt_size;
    logic [15 : 0]       s_axis_c2h_cmpt_dpar;
    logic                s_axis_c2h_cmpt_tvalid;
    logic [10 : 0]       s_axis_c2h_cmpt_ctrl_qid;
    logic [1 : 0]        s_axis_c2h_cmpt_ctrl_cmpt_type;
    logic [15 : 0]       s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id;
    logic [2 : 0]        s_axis_c2h_cmpt_ctrl_port_id;
    logic                s_axis_c2h_cmpt_ctrl_marker;
    logic                s_axis_c2h_cmpt_ctrl_user_trig;
    logic [2 : 0]        s_axis_c2h_cmpt_ctrl_col_idx;
    logic [2 : 0]        s_axis_c2h_cmpt_ctrl_err_idx;
    logic                s_axis_c2h_cmpt_tready;
    logic                s_axis_c2h_cmpt_ctrl_no_wrb_marker;

    // =========================================================================
    // Interfaces
    // =========================================================================
    axi4l_intf #() __axil_if__250mhz ();

    // =========================================================================
    // QDMA IP
    // =========================================================================
    xilinx_alveo_usplus_qdma_wrapper #(
        .PCIE_LINK_WID   ( PCIE_LINK_WID )
    ) i_xilinx_alveo_usplus_qdma (
        .pcie_rstn ( pcie_rstn ),
        .pcie_refclk_p,
        .pcie_refclk_n,
        .pcie_rxp,
        .pcie_rxn,
        .pcie_txp,
        .pcie_txn,
        .axil_if ( __axil_if__250mhz ),
        .axi_aclk,
        .axi_aresetn,
        .dsc_crdt_in_crdt,
        .dsc_crdt_in_qid,
        .dsc_crdt_in_dir,
        .dsc_crdt_in_fence,
        .dsc_crdt_in_vld,
        .dsc_crdt_in_rdy,
        .m_axis_h2c_tdata,
        .m_axis_h2c_tcrc,
        .m_axis_h2c_tuser_qid,
        .m_axis_h2c_tuser_port_id,
        .m_axis_h2c_tuser_err,
        .m_axis_h2c_tuser_mdata,
        .m_axis_h2c_tuser_mty,
        .m_axis_h2c_tuser_zero_byte,
        .m_axis_h2c_tvalid,
        .m_axis_h2c_tlast,
        .m_axis_h2c_tready,
        .s_axis_c2h_tdata,
        .s_axis_c2h_tcrc,
        .s_axis_c2h_ctrl_marker,
        .s_axis_c2h_ctrl_port_id,
        .s_axis_c2h_ctrl_ecc,
        .s_axis_c2h_ctrl_len,
        .s_axis_c2h_ctrl_qid,
        .s_axis_c2h_ctrl_has_cmpt,
        .s_axis_c2h_mty,
        .s_axis_c2h_tvalid,
        .s_axis_c2h_tlast,
        .s_axis_c2h_tready,
        .s_axis_c2h_cmpt_tdata,
        .s_axis_c2h_cmpt_size,
        .s_axis_c2h_cmpt_dpar,
        .s_axis_c2h_cmpt_tvalid,
        .s_axis_c2h_cmpt_ctrl_qid,
        .s_axis_c2h_cmpt_ctrl_cmpt_type,
        .s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id,
        .s_axis_c2h_cmpt_ctrl_port_id,
        .s_axis_c2h_cmpt_ctrl_marker,
        .s_axis_c2h_cmpt_ctrl_user_trig,
        .s_axis_c2h_cmpt_ctrl_col_idx,
        .s_axis_c2h_cmpt_ctrl_err_idx,
        .s_axis_c2h_cmpt_tready,
        .s_axis_c2h_cmpt_ctrl_no_wrb_marker
    );
     
    // Native QDMA streams stay in the DMA clock domain until the shared shell.
    xilinx_qdma_st_adapter #(
        .QID_WID ( xilinx_alveo_usplus_pkg::DMA_ST_QID_WID )
    ) i_xilinx_qdma_st_adapter (
        .aclk ( axi_aclk ),
        .aresetn ( axi_aresetn ),
        .h2c_tvalid              ( m_axis_h2c_tvalid ),
        .h2c_tdata               ( m_axis_h2c_tdata ),
        .h2c_tlast               ( m_axis_h2c_tlast ),
        .h2c_tready              ( m_axis_h2c_tready ),
        .h2c_qid                 ( m_axis_h2c_tuser_qid ),
        .h2c_port_id             ( m_axis_h2c_tuser_port_id ),
        .h2c_mdata               ( m_axis_h2c_tuser_mdata ),
        .h2c_mty                 ( m_axis_h2c_tuser_mty ),
        .h2c_tcrc                ( m_axis_h2c_tcrc ),
        .h2c_err                 ( m_axis_h2c_tuser_err ),
        .h2c_zero_byte           ( m_axis_h2c_tuser_zero_byte ),
        .c2h_tvalid              ( s_axis_c2h_tvalid ),
        .c2h_tdata               ( s_axis_c2h_tdata ),
        .c2h_tlast               ( s_axis_c2h_tlast ),
        .c2h_tready              ( s_axis_c2h_tready ),
        .c2h_ctrl_qid            ( s_axis_c2h_ctrl_qid ),
        .c2h_ctrl_len            ( s_axis_c2h_ctrl_len ),
        .c2h_ctrl_port_id        ( s_axis_c2h_ctrl_port_id ),
        .c2h_ctrl_has_cmpt       ( s_axis_c2h_ctrl_has_cmpt ),
        .c2h_ctrl_marker         ( s_axis_c2h_ctrl_marker ),
        .c2h_mty                 ( s_axis_c2h_mty ),
        .c2h_ecc                 ( s_axis_c2h_ctrl_ecc ),
        .c2h_tcrc                ( s_axis_c2h_tcrc ),
        .cmpt_tvalid             ( s_axis_c2h_cmpt_tvalid ),
        .cmpt_data               ( s_axis_c2h_cmpt_tdata ),
        .cmpt_size               ( s_axis_c2h_cmpt_size ),
        .cmpt_qid                ( s_axis_c2h_cmpt_ctrl_qid ),
        .cmpt_port_id            ( s_axis_c2h_cmpt_ctrl_port_id ),
        .cmpt_cmpt_type          ( s_axis_c2h_cmpt_ctrl_cmpt_type ),
        .cmpt_wait_pld_pkt_id    ( s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id ),
        .cmpt_dpar               ( s_axis_c2h_cmpt_dpar ),
        .cmpt_col_idx            ( s_axis_c2h_cmpt_ctrl_col_idx ),
        .cmpt_err_idx            ( s_axis_c2h_cmpt_ctrl_err_idx ),
        .cmpt_user_trig          ( s_axis_c2h_cmpt_ctrl_user_trig ),
        .cmpt_marker             ( s_axis_c2h_cmpt_ctrl_marker ),
        .cmpt_no_wrb_marker      ( s_axis_c2h_cmpt_ctrl_no_wrb_marker ),
        .cmpt_tready             ( s_axis_c2h_cmpt_tready ),
        .dsc_crdt_crdt           ( dsc_crdt_in_crdt ),
        .dsc_crdt_dir            ( dsc_crdt_in_dir ),
        .dsc_crdt_fence          ( dsc_crdt_in_fence ),
        .dsc_crdt_qid            ( dsc_crdt_in_qid ),
        .dsc_crdt_valid          ( dsc_crdt_in_vld ),
        .dsc_crdt_rdy            ( dsc_crdt_in_rdy ),
        .pkt_h2c ( pkt_h2c_dma ),
        .pkt_c2h ( pkt_c2h_dma )
    );

    // =========================================================================
    // AXI-L ILA (250MHz domain)
    // =========================================================================
    xilinx_alveo_usplus_axil_ila i_xilinx_alveo_usplus_axil_ila__250mhz (
        .clk     ( __axil_if__250mhz.aclk ),
        .probe0  ( __axil_if__250mhz.wready ),
        .probe1  ( __axil_if__250mhz.awaddr ),
        .probe2  ( __axil_if__250mhz.bresp ),
        .probe3  ( __axil_if__250mhz.bvalid ),
        .probe4  ( __axil_if__250mhz.bready ),
        .probe5  ( __axil_if__250mhz.araddr ),
        .probe6  ( __axil_if__250mhz.rready ),
        .probe7  ( __axil_if__250mhz.wvalid ),
        .probe8  ( __axil_if__250mhz.arvalid ),
        .probe9  ( __axil_if__250mhz.arready ),
        .probe10 ( __axil_if__250mhz.rdata ),
        .probe11 ( __axil_if__250mhz.awvalid ),
        .probe12 ( __axil_if__250mhz.awready ),
        .probe13 ( __axil_if__250mhz.rresp ),
        .probe14 ( __axil_if__250mhz.wdata ),
        .probe15 ( __axil_if__250mhz.wstrb ),
        .probe16 ( __axil_if__250mhz.rvalid ),
        .probe17 ( __axil_if__250mhz.arprot ),
        .probe18 ( __axil_if__250mhz.awprot )
    );

    // =========================================================================
    // AXI-L clock divider (250MHz to 125MHz)
    // =========================================================================
    assign clk_250mhz = axi_aclk;

    xilinx_alveo_usplus_clk_axil i_xilinx_alveo_usplus_clk_axil (
        .clk_in1  ( clk_250mhz ),
        .clk_out1 ( clk_125mhz )
    );

    assign dma_aclk = axi_aclk;
    assign dma_aresetn = axi_aresetn;

    // =========================================================================
    // AXI-L synchronizer (250Mhz to 125MHz)
    // =========================================================================
    axi4l_intf_cdc i_axi4l_intf_cdc (
        .axi4l_if_from_controller ( __axil_if__250mhz ),
        .clk_to_peripheral        ( clk_125mhz ),
        .axi4l_if_to_peripheral   ( axil_if )
    );

    // =========================================================================
    // AXI-L ILA (125MHz domain)
    // =========================================================================
    xilinx_alveo_usplus_axil_ila i_xilinx_alveo_usplus_axil_ila__125mhz (
        .clk     ( axil_if.aclk ),
        .probe0  ( axil_if.wready ),
        .probe1  ( axil_if.awaddr ),
        .probe2  ( axil_if.bresp ),
        .probe3  ( axil_if.bvalid ),
        .probe4  ( axil_if.bready ),
        .probe5  ( axil_if.araddr ),
        .probe6  ( axil_if.rready ),
        .probe7  ( axil_if.wvalid ),
        .probe8  ( axil_if.arvalid ),
        .probe9  ( axil_if.arready ),
        .probe10 ( axil_if.rdata ),
        .probe11 ( axil_if.awvalid ),
        .probe12 ( axil_if.awready ),
        .probe13 ( axil_if.rresp ),
        .probe14 ( axil_if.wdata ),
        .probe15 ( axil_if.wstrb ),
        .probe16 ( axil_if.rvalid ),
        .probe17 ( axil_if.arprot ),
        .probe18 ( axil_if.awprot )
    );

endmodule : xilinx_alveo_usplus_host
