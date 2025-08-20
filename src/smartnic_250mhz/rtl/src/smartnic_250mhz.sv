module smartnic_250mhz #(
    parameter int NUM_INTF = 1
) (
    input                     s_axil_awvalid,
    input              [31:0] s_axil_awaddr,
    output                    s_axil_awready,
    input                     s_axil_wvalid,
    input              [31:0] s_axil_wdata,
    output                    s_axil_wready,
    output                    s_axil_bvalid,
    output              [1:0] s_axil_bresp,
    input                     s_axil_bready,
    input                     s_axil_arvalid,
    input              [31:0] s_axil_araddr,
    output                    s_axil_arready,
    output                    s_axil_rvalid,
    output             [31:0] s_axil_rdata,
    output              [1:0] s_axil_rresp,
    input                     s_axil_rready,

    input      [NUM_INTF-1:0] s_axis_qdma_h2c_tvalid,
    input  [512*NUM_INTF-1:0] s_axis_qdma_h2c_tdata,
    input   [64*NUM_INTF-1:0] s_axis_qdma_h2c_tkeep,
    input      [NUM_INTF-1:0] s_axis_qdma_h2c_tlast,
    input   [16*NUM_INTF-1:0] s_axis_qdma_h2c_tuser_size,
    input   [16*NUM_INTF-1:0] s_axis_qdma_h2c_tuser_src,
    input   [16*NUM_INTF-1:0] s_axis_qdma_h2c_tuser_dst,
    output     [NUM_INTF-1:0] s_axis_qdma_h2c_tready,

    output     [NUM_INTF-1:0] m_axis_qdma_c2h_tvalid,
    output [512*NUM_INTF-1:0] m_axis_qdma_c2h_tdata,
    output  [64*NUM_INTF-1:0] m_axis_qdma_c2h_tkeep,
    output     [NUM_INTF-1:0] m_axis_qdma_c2h_tlast,
    output  [16*NUM_INTF-1:0] m_axis_qdma_c2h_tuser_size,
    output  [16*NUM_INTF-1:0] m_axis_qdma_c2h_tuser_src,
    output  [16*NUM_INTF-1:0] m_axis_qdma_c2h_tuser_dst,
    output     [NUM_INTF-1:0] m_axis_qdma_c2h_tuser_rss_hash_valid,
    output  [12*NUM_INTF-1:0] m_axis_qdma_c2h_tuser_rss_hash,
    input      [NUM_INTF-1:0] m_axis_qdma_c2h_tready,

    output     [NUM_INTF-1:0] m_axis_adap_tx_250mhz_tvalid,
    output [512*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tdata,
    output  [64*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tkeep,
    output     [NUM_INTF-1:0] m_axis_adap_tx_250mhz_tlast,
    output  [16*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tuser_size,
    output  [16*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tuser_src,
    output  [16*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tuser_dst,
    input      [NUM_INTF-1:0] m_axis_adap_tx_250mhz_tready,

    input      [NUM_INTF-1:0] s_axis_adap_rx_250mhz_tvalid,
    input  [512*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tdata,
    input   [64*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tkeep,
    input      [NUM_INTF-1:0] s_axis_adap_rx_250mhz_tlast,
    input   [16*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_size,
    input   [16*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_src,
    input   [16*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_dst,
    input      [NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_rss_hash_valid,
    input   [12*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_rss_hash,
    output     [NUM_INTF-1:0] s_axis_adap_rx_250mhz_tready,

    input                     mod_rstn,
    output                    mod_rst_done,

    input                     axil_aclk,

    `ifdef __au55n__
      input                     ref_clk_100mhz,
    `elsif __au55c__
      input                     ref_clk_100mhz,
    `elsif __au50__
      input                     ref_clk_100mhz,
    `elsif __au280__
      input                     ref_clk_100mhz,
    `endif
    input                     axis_aclk
);

    // ----------------------------------------------------------------
    //  Imports
    // ----------------------------------------------------------------
    import smartnic_250mhz_pkg::*;

    // ----------------------------------------------------------------
    //  Parameters
    // ----------------------------------------------------------------
    localparam int AXIS_DATA_BYTE_WID = 64;
    localparam int TDATA_WID = AXIS_DATA_BYTE_WID * 8;
    localparam int TKEEP_WID = AXIS_DATA_BYTE_WID;

    // ----------------------------------------------------------------
    //  Signals
    // ----------------------------------------------------------------
    logic axil_aresetn;

    logic core_clk;
    logic core_rstn;

    // ----------------------------------------------------------------
    //  Interfaces
    // ----------------------------------------------------------------
    axi4l_intf axil_if ();
    axi4l_intf axil_to_regs ();
    axi4l_intf axil_to_regs__core_clk ();

    smartnic_250mhz_reg_intf smartnic_250mhz_regs ();

    axi4s_intf #(.DATA_BYTE_WID (AXIS_DATA_BYTE_WID), .TUSER_WID (TUSER_H2C_WID)) axis_if__qdma_h2c [NUM_INTF] (.aclk(core_clk), .aresetn(core_rstn));
    axi4s_intf #(.DATA_BYTE_WID (AXIS_DATA_BYTE_WID), .TUSER_WID (TUSER_H2C_WID)) axis_if__adap_tx_250mhz [NUM_INTF] (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf #(.DATA_BYTE_WID (AXIS_DATA_BYTE_WID), .TUSER_WID (TUSER_C2H_WID)) axis_if__qdma_c2h [NUM_INTF] (.aclk(core_clk), .aresetn(core_rstn));
    axi4s_intf #(.DATA_BYTE_WID (AXIS_DATA_BYTE_WID), .TUSER_WID (TUSER_C2H_WID)) axis_if__adap_rx_250mhz [NUM_INTF] (.aclk(core_clk), .aresetn(core_rstn));

    // ----------------------------------------------------------------
    //  Clocks/Resets
    // ----------------------------------------------------------------
    smartnic_250mhz_reset i_smartnic_250mhz_reset (
        .mod_rstn     ( mod_rstn ),
        .mod_rst_done ( mod_rst_done ),
        .axis_aclk    ( axis_aclk ),
        .axil_aclk    ( axil_aclk ),
        .axil_aresetn ( axil_aresetn ),
        .core_clk     ( core_clk ),
        .core_rstn    ( core_rstn )
    );

    // ----------------------------------------------------------------
    //  AXI-L Control
    // ----------------------------------------------------------------
    // Convert AXI-L signals to interface format
    axi4l_intf_from_signals i_axi4l_intf_from_signals (
        // Signals (from controller)
        .aclk     ( axil_aclk ),
        .aresetn  ( axil_aresetn ),
        .awaddr   ( s_axil_awaddr ),
        .awprot   ( 3'b000 ),
        .awvalid  ( s_axil_awvalid ),
        .awready  ( s_axil_awready ),
        .wdata    ( s_axil_wdata ),
        .wstrb    ( 4'b1111 ),
        .wvalid   ( s_axil_wvalid ),
        .wready   ( s_axil_wready ),
        .bresp    ( s_axil_bresp ),
        .bvalid   ( s_axil_bvalid ),
        .bready   ( s_axil_bready ),
        .araddr   ( s_axil_araddr ),
        .arprot   ( 3'b000 ),
        .arvalid  ( s_axil_arvalid ),
        .arready  ( s_axil_arready ),
        .rdata    ( s_axil_rdata ),
        .rresp    ( s_axil_rresp ),
        .rvalid   ( s_axil_rvalid ),
        .rready   ( s_axil_rready ),

        // Interface (to peripheral)
        .axi4l_if ( axil_if )
    );

    // smartnic_250mhz top-level decoder
    smartnic_250mhz_decoder i_smartnic_250mhz_decoder (
        .axil_if (axil_if),
        .smartnic_250mhz_regs_axil_if ( axil_to_regs )
    );

    // Synchronize AXI-L interface to core clock domain
    axi4l_intf_cdc i_axil_intf_cdc__regs (
        .axi4l_if_from_controller ( axil_to_regs ),
        .clk_to_peripheral        ( core_clk ),
        .axi4l_if_to_peripheral   ( axil_to_regs__core_clk )
    );

    // smartnic_250mhz register block
    smartnic_250mhz_reg_blk i_smartnic_250mhz_reg_blk (
        .axil_if    ( axil_to_regs__core_clk ),
        .reg_blk_if ( smartnic_250mhz_regs )
    );

    // ----------------------------------------------------------------
    //  AXI-S: Convert between signals and interfaces
    // ----------------------------------------------------------------
    // QDMA
    generate
        for (genvar g_if = 0; g_if < NUM_INTF; g_if++) begin : g__qdma
            // (Local) signals
            tuser_h2c_t s_axis_qdma_h2c_tuser;
            tuser_c2h_t m_axis_qdma_c2h_tuser;

            // QDMA H2C: Convert AXI-S signals to interface
            assign s_axis_qdma_h2c_tuser.size = s_axis_qdma_h2c_tuser_size [g_if * 16 +: 16];
            assign s_axis_qdma_h2c_tuser.src  = s_axis_qdma_h2c_tuser_src  [g_if * 16 +: 16];
            assign s_axis_qdma_h2c_tuser.dst  = s_axis_qdma_h2c_tuser_dst  [g_if * 16 +: 16];

            axi4s_intf_from_signals #(
                .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TUSER_WID(TUSER_H2C_WID)
            ) i_axi4s_intf_from_signals__qdma_h2c (
                .tvalid  ( s_axis_qdma_h2c_tvalid [g_if*        1 +:         1] ),
                .tready  ( s_axis_qdma_h2c_tready [g_if*        1 +:         1] ),
                .tdata   ( s_axis_qdma_h2c_tdata  [g_if*TDATA_WID +: TDATA_WID] ),
                .tkeep   ( s_axis_qdma_h2c_tkeep  [g_if*TKEEP_WID +: TKEEP_WID] ),
                .tlast   ( s_axis_qdma_h2c_tlast  [g_if*        1 +:         1] ),
                .tid     ( '0 ),
                .tdest   ( '0 ),
                .tuser   ( s_axis_qdma_h2c_tuser ),
                .axi4s_if( axis_if__qdma_h2c[g_if] )
            );

            // QDMA C2H: Convert AXI-S interface to signals
            axi4s_intf_to_signals #(
                .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TUSER_WID(TUSER_C2H_WID)
            ) i_axi4s_intf_to_signals__qdma_c2h (
                .tvalid  ( m_axis_qdma_c2h_tvalid [g_if*        1 +:         1] ),
                .tready  ( m_axis_qdma_c2h_tready [g_if*        1 +:         1] ),
                .tdata   ( m_axis_qdma_c2h_tdata  [g_if*TDATA_WID +: TDATA_WID] ),
                .tkeep   ( m_axis_qdma_c2h_tkeep  [g_if*TKEEP_WID +: TKEEP_WID] ),
                .tlast   ( m_axis_qdma_c2h_tlast  [g_if*        1 +:         1] ),
                .tid     ( ),
                .tdest   ( ),
                .tuser   ( m_axis_qdma_c2h_tuser ),
                .axi4s_if( axis_if__qdma_c2h[g_if] )
            );
            assign m_axis_qdma_c2h_tuser_size           [g_if * 16 +: 16] = m_axis_qdma_c2h_tuser.size;
            assign m_axis_qdma_c2h_tuser_src            [g_if * 16 +: 16] = m_axis_qdma_c2h_tuser.src;
            assign m_axis_qdma_c2h_tuser_dst            [g_if * 16 +: 16] = 1 << g_if; // ONS port mapping
            assign m_axis_qdma_c2h_tuser_rss_hash_valid [g_if * 1  +:  1] = m_axis_qdma_c2h_tuser.rss_hash_valid;
            assign m_axis_qdma_c2h_tuser_rss_hash       [g_if * 12 +: 12] = m_axis_qdma_c2h_tuser.rss_hash;
        end : g__qdma
    endgenerate

    // Adapter
    generate
        for (genvar g_if = 0; g_if < NUM_INTF; g_if++) begin : g__adap
            // (Local) signals
            tuser_h2c_t m_axis_adap_tx_250mhz_tuser;
            tuser_c2h_t s_axis_adap_rx_250mhz_tuser;

            // ADAP RX: Convert AXI-S interface to signals
            axi4s_intf_to_signals #(
                .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TUSER_WID(TUSER_H2C_WID)
            ) i_axi4s_intf_to_signals__adap_tx (
                .tvalid  ( m_axis_adap_tx_250mhz_tvalid [g_if*        1 +:         1] ),
                .tready  ( m_axis_adap_tx_250mhz_tready [g_if*        1 +:         1] ),
                .tdata   ( m_axis_adap_tx_250mhz_tdata  [g_if*TDATA_WID +: TDATA_WID] ),
                .tkeep   ( m_axis_adap_tx_250mhz_tkeep  [g_if*TKEEP_WID +: TKEEP_WID] ),
                .tlast   ( m_axis_adap_tx_250mhz_tlast  [g_if*        1 +:         1] ),
                .tid     ( ),
                .tdest   ( ),
                .tuser   ( m_axis_adap_tx_250mhz_tuser ),
                .axi4s_if( axis_if__adap_tx_250mhz[g_if] )
            );
            assign m_axis_adap_tx_250mhz_tuser_size           [g_if * 16 +: 16] = m_axis_adap_tx_250mhz_tuser.size;
            assign m_axis_adap_tx_250mhz_tuser_src            [g_if * 16 +: 16] = m_axis_adap_tx_250mhz_tuser.src;
            assign m_axis_adap_tx_250mhz_tuser_dst            [g_if * 16 +: 16] = 1 << (6 + g_if); // ONS port mapping

            // ADAP RX: Convert AXI-S signals to interface
            assign s_axis_adap_rx_250mhz_tuser.size           = s_axis_adap_rx_250mhz_tuser_size           [g_if * 16 +: 16];
            assign s_axis_adap_rx_250mhz_tuser.src            = s_axis_adap_rx_250mhz_tuser_src            [g_if * 16 +: 16];
            assign s_axis_adap_rx_250mhz_tuser.dst            = s_axis_adap_rx_250mhz_tuser_dst            [g_if * 16 +: 16];
            assign s_axis_adap_rx_250mhz_tuser.rss_hash_valid = s_axis_adap_rx_250mhz_tuser_rss_hash_valid [g_if * 1  +:  1];
            assign s_axis_adap_rx_250mhz_tuser.rss_hash       = s_axis_adap_rx_250mhz_tuser_rss_hash       [g_if * 12 +: 12];

            axi4s_intf_from_signals #(
                .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TUSER_WID(TUSER_C2H_WID)
            ) i_axi4s_intf_from_signals__adap_rx (
                .tvalid  ( s_axis_adap_rx_250mhz_tvalid [g_if*        1 +:         1] ),
                .tready  ( s_axis_adap_rx_250mhz_tready [g_if*        1 +:         1] ),
                .tdata   ( s_axis_adap_rx_250mhz_tdata  [g_if*TDATA_WID +: TDATA_WID] ),
                .tkeep   ( s_axis_adap_rx_250mhz_tkeep  [g_if*TKEEP_WID +: TKEEP_WID] ),
                .tlast   ( s_axis_adap_rx_250mhz_tlast  [g_if*        1 +:         1] ),
                .tid     ( '0 ),
                .tdest   ( '0 ),
                .tuser   ( s_axis_adap_rx_250mhz_tuser ),
                .axi4s_if( axis_if__adap_rx_250mhz[g_if] )
            );
        end : g__adap
    endgenerate

    // ----------------------------------------------------------------
    //  Application
    //  (empty for now; includes register slices for crossing between SLRs)
    // ----------------------------------------------------------------

    generate
        for (genvar g_if = 0; g_if < NUM_INTF; g_if++) begin : g__if
            // (Local) interfaces
            axi4s_intf #(.DATA_BYTE_WID (AXIS_DATA_BYTE_WID), .TUSER_WID (TUSER_H2C_WID)) axis_if__h2c (.aclk(core_clk), .aresetn(core_rstn));
            axi4s_intf #(.DATA_BYTE_WID (AXIS_DATA_BYTE_WID), .TUSER_WID (TUSER_C2H_WID)) axis_if__c2h (.aclk(core_clk), .aresetn(core_rstn));

            // H2C register slices (bridge between SLRs)
            xilinx_axi4s_reg_slice #(
                .CONFIG(xilinx_axis_pkg::XILINX_AXIS_REG_SLICE_SLR_CROSSING)
            ) i_xilinx_axi4s_reg_slice__qdma_h2c (
                .from_tx ( axis_if__qdma_h2c[g_if] ),
                .to_rx   ( axis_if__h2c )
            );

            xilinx_axi4s_reg_slice #(
            `ifdef __au280__
                .CONFIG(xilinx_axis_pkg::XILINX_AXIS_REG_SLICE_SLR_CROSSING)
            `else
                .CONFIG(xilinx_axis_pkg::XILINX_AXIS_REG_SLICE_BYPASS)
            `endif
            ) i_xilinx_axi4s_reg_slice__adap_tx (
                .from_tx ( axis_if__h2c ),
                .to_rx   ( axis_if__adap_tx_250mhz[g_if] )
            );

            // C2H register slices (bridge between SLRs)
            xilinx_axi4s_reg_slice #(
            `ifdef __au280__
                .CONFIG(xilinx_axis_pkg::XILINX_AXIS_REG_SLICE_SLR_CROSSING)
            `else
                .CONFIG(xilinx_axis_pkg::XILINX_AXIS_REG_SLICE_BYPASS)
            `endif
            ) i_xilinx_axi4s_reg_slice__adap_rx (
                .from_tx ( axis_if__adap_rx_250mhz[g_if] ),
                .to_rx   ( axis_if__c2h )
            );

            xilinx_axi4s_reg_slice #(
                .CONFIG(xilinx_axis_pkg::XILINX_AXIS_REG_SLICE_SLR_CROSSING)
            ) i_xilinx_axi4s_reg_slice__qdma_c2h (
                .from_tx ( axis_if__c2h ),
                .to_rx   ( axis_if__qdma_c2h[g_if] )
            );
        end : g__if
    endgenerate

endmodule: smartnic_250mhz
