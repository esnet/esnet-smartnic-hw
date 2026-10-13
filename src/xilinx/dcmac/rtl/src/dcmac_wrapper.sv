// DCMAC Wrapper
//
// Integrates xilinx_dcmac_wrapper with GT clocking (IBUFDS_GTME5, BUFG_GT,
// MBUFG_GT), xilinx_dcmac_0_clk_wiz_0, and xilinx_dcmac_0_gtwiz_versal_0.
// Based on xilinx_dcmac_0_exdes.sv example design (single 400GE channel, QUAD0 only).

module dcmac_wrapper (
    // GT reference clock (differential)
    input logic  gt_ref_clk0_p,
    input logic  gt_ref_clk0_n,

    // GT serial I/O (4 lanes)
    input  logic [1:0][3:0] gt_rxp_in,
    input  logic [1:0][3:0] gt_rxn_in,
    output logic [1:0][3:0] gt_txp_out,
    output logic [1:0][3:0] gt_txn_out,

    // Free-running clock for GT wizard (e.g. 100 MHz system clock)
    input logic	 init_clk,

    // GT reset / control
    input  logic gt_reset_all_in,
    input  logic gt_reset_tx_datapath_in,
    input  logic gt_reset_rx_datapath_in,

    output logic [1:0] gt_tx_reset_done,
    output logic [1:0] gt_rx_reset_done,
    output logic [1:0] gtpowergood,
    output logic       clk_wiz_locked,

    // GT equalizer / loopback controls
    input logic [2:0] gt_loopback,
    input logic [7:0] gt_line_rate,
    input logic [5:0] gt_txprecursor,
    input logic [5:0] gt_txpostcursor,
    input logic [6:0] gt_txmaincursor,
    input logic       gt_rxcdrhold,

    input logic       dcmac_lpbk_en,

    // Clock outputs
    output logic axis_clk_out,

    // AXI-S interfaces
    axi4s_intf.tx axis_rx [2],
    axi4s_intf.rx axis_tx [2],

    // AXI-L interfaces
    axi4l_intf.peripheral axil_dcmac,
    axi4l_intf.peripheral axil_gt [2]
);

    // =========================================================================
    // GT refclk and BUFG_GT → clk_wiz input
    // =========================================================================
    logic gt_refclk0;
    logic bufds_odiv2;

    IBUFDS_GTME5 #(
        .REFCLK_EN_TX_PATH  (1'b0),
        .REFCLK_HROW_CK_SEL (0),
        .REFCLK_ICNTL_RX    (0)
    ) i_ibufds_gtme5 (
        .I      (gt_ref_clk0_p),
        .IB     (gt_ref_clk0_n),
        .CEB    (1'b0),
        .ODIV2  (bufds_odiv2),
        .O      (gt_refclk0)
    );

    logic clk_wiz_in;

    BUFG_GT #(
        .SIM_DEVICE ("VERSAL_HBM")
    ) i_bufg_gt (
        .O       (clk_wiz_in),
        .CE      (1'b1),
        .CEMASK  (1'b0),
        .CLR     (1'b0),
        .CLRMASK (1'b0),
        .DIV     (3'd0),
        .I       (bufds_odiv2)
    );


    // =========================================================================
    // Clock wizard: clk_wiz_in → core_clk (~781 MHz), axis_clk (~390 MHz),
    //                            ts_clk_0 (~300 MHz)
    // =========================================================================
    logic core_clk;
    logic axis_clk;
    logic ts_clk_0;
    xilinx_dcmac_0_clk_wiz_0 i_clk_wiz (
        .reset   (1'b0),
        .clk_in1 (clk_wiz_in),
        .locked  (clk_wiz_locked),
        .clk_out1 (core_clk),
        .clk_out2 (axis_clk),
        .clk_out3 (ts_clk_0)
    );

    assign axis_clk_out  = axis_clk;


    // =========================================================================
    // GT wizard reset / done
    // =========================================================================
    logic [7:0] gt_reset_ctr = '1;
    always_ff @(posedge init_clk) if (clk_wiz_locked && gt_reset_ctr != '0) gt_reset_ctr <= gt_reset_ctr-1;

    logic  _gt_reset_all_in;
    assign _gt_reset_all_in = gt_reset_all_in | ((gt_reset_ctr != '0) && (gt_reset_ctr != '1));

    logic [1:0] rst_tx_done;
    logic [1:0] rst_rx_done;

    assign gt_tx_reset_done = rst_tx_done;
    assign gt_rx_reset_done = rst_rx_done;

    logic _gt_tx_reset_done;
    logic _gt_rx_reset_done;

    assign _gt_tx_reset_done = &gt_tx_reset_done;
    assign _gt_rx_reset_done = &gt_rx_reset_done;


    // =========================================================================
    // GT user clocks via MBUFG_GT (TX and RX, channel 0 only)
    // =========================================================================
    logic [1:0] tx_usrclk;
    logic [1:0] tx_usrclk2;
    logic [1:0] tx_clr_out;
    logic [1:0] tx_clrb_leaf_out;
    logic [1:0] ch0_txoutclk;

    logic [1:0] rx_usrclk;
    logic [1:0] rx_usrclk2;
    logic [1:0] rx_clr_out;
    logic [1:0] rx_clrb_leaf_out;
    logic [1:0] ch0_rxoutclk;

    // GT data buses
    logic [1:0][3:0][255:0] rxdata_in;
    logic [1:0][3:0][255:0] rxdata_in_mux;
    logic [1:0][3:0][255:0] txdata_out;

   
    // tx_usrclk  (O1) =     serdes_clk (full-rate, used as rx/tx_serdes_clk)
    // tx_usrclk2 (O2) = alt_serdes_clk (half-rate, used as rx/tx_alt_serdes_clk)
    generate
        for (genvar i = 0; i < 2; i++) begin : g_gt

            MBUFG_GT #(
                .MODE ("PERFORMANCE")
            ) i_mbufg_gt_tx (
                .O1      (tx_usrclk[i]),   // ~664 MHz
                .O2      (tx_usrclk2[i]),  // ~332 MHz
                .O3      (),
                .O4      (),
                .CE      (1'b1),
                .CEMASK  (1'b0),
                .CLR     (tx_clr_out[i]),
                .CLRB_LEAF (tx_clrb_leaf_out[i]),
                .CLRMASK (1'b0),
                .DIV     (3'd0),
                .I       (ch0_txoutclk[i])
            );

            MBUFG_GT #(
                .MODE ("PERFORMANCE")
            ) i_mbufg_gt_rx (
                .O1      (rx_usrclk[i]),
                .O2      (rx_usrclk2[i]),
                .O3      (),
                .O4      (),
                .CE      (1'b1),
                .CEMASK  (1'b0),
                .CLR     (rx_clr_out[i]),
                .CLRB_LEAF (rx_clrb_leaf_out[i]),
                .CLRMASK (1'b0),
                .DIV     (3'd0),
                .I       (ch0_rxoutclk[i])
            );

            // =========================================================================
            // GT wrapper instance.
            // =========================================================================
            xilinx_gt_wrapper i_xilinx_gt_wrapper (
                .gtwiz_freerun_clk              (init_clk),
                .QUAD0_GTREFCLK0                (gt_refclk0),

                // Recovered clocks → MBUFG_GT
                .QUAD0_TX0_outclk               (ch0_txoutclk[i]),
                .QUAD0_RX0_outclk               (ch0_rxoutclk[i]),

                // User clocks from MBUFG_GT (all four lanes share channel 0 clocks)
                .gt_tx_usrclk                   (tx_usrclk2[i]),
                .gt_rx_usrclk                   (rx_usrclk2[i]),

                // INTF0 reset control
                .INTF0_TX_clr_out               (tx_clr_out[i]),
                .INTF0_TX_clrb_leaf_out         (tx_clrb_leaf_out[i]),
                .INTF0_RX_clr_out               (rx_clr_out[i]),
                .INTF0_RX_clrb_leaf_out         (rx_clrb_leaf_out[i]),
                .INTF0_rst_all_in               (_gt_reset_all_in),
                .INTF0_rst_tx_datapath_in       (gt_reset_tx_datapath_in),
                .INTF0_rst_tx_done_out          (rst_tx_done[i]),
                .INTF0_rst_rx_datapath_in       (gt_reset_rx_datapath_in),
                .INTF0_rst_rx_done_out          (rst_rx_done[i]),

                // GT configuration
                .gt_loopback                    (gt_loopback),
                .gt_txrate                      (gt_line_rate),
                .gt_txprecursor                 (gt_txprecursor),
                .gt_txpostcursor                (gt_txpostcursor),
                .gt_txmaincursor                (gt_txmaincursor),
                .gt_rxrate                      (gt_line_rate),
                .gt_rxcdrhold                   (gt_rxcdrhold),

                .gtpowergood                    (gtpowergood[i]),

                // Serial IO connections
                .QUAD0_rxp                      (gt_rxp_in[i]),
                .QUAD0_rxn                      (gt_rxn_in[i]),
                .QUAD0_txp                      (gt_txp_out[i]),
                .QUAD0_txn                      (gt_txn_out[i]),

                // Internal bus connections
                .gt_txdata                      (txdata_out[i]),
                .gt_rxdata                      (rxdata_in[i]),

                // QUAD0 AXI-Lite
                .axil_if                        (axil_gt[i])
            );

        end : g_gt
    endgenerate


    // =========================================================================
    // DCMAC wrapper instance.
    // =========================================================================
    logic [5:0] tx_serdes_reset;
    logic [5:0] rx_serdes_reset;

    assign tx_serdes_reset[0]   = tx_clr_out[0];
    assign tx_serdes_reset[1]   = tx_clr_out[0];
    assign tx_serdes_reset[2]   = tx_clr_out[1];
    assign tx_serdes_reset[3]   = tx_clr_out[1];
    assign tx_serdes_reset[5:4] = '1;
    assign rx_serdes_reset[0]   = rx_clr_out[0];
    assign rx_serdes_reset[1]   = rx_clr_out[0];
    assign rx_serdes_reset[2]   = rx_clr_out[1];
    assign rx_serdes_reset[3]   = rx_clr_out[1];
    assign rx_serdes_reset[5:4] = '1;

    // Synchronise reset-done to core_clk domain for DCMAC resets
    logic rx_core_reset;
    logic tx_core_reset;

    sync_areset #(.INPUT_ACTIVE_HIGH(0), .OUTPUT_ACTIVE_LOW(0)) sync_rx_core_reset (
        .rst_in  (_gt_rx_reset_done),
        .clk_out (core_clk),
        .rst_out (rx_core_reset)
    );

    sync_areset #(.INPUT_ACTIVE_HIGH(0), .OUTPUT_ACTIVE_LOW(0)) sync_tx_core_reset (
        .rst_in  (_gt_tx_reset_done),
        .clk_out (core_clk),
        .rst_out (tx_core_reset)
    );

//    assign rxdata_in_mux = dcmac_lpbk_en ? txdata_out : rxdata_in;
    assign rxdata_in_mux = rxdata_in;

    logic [1:0][3:0][255:0] rxdata_in_mux_q;
    always_ff @(posedge rx_usrclk2[0]) rxdata_in_mux_q[0] <= rxdata_in_mux[0];
    always_ff @(posedge rx_usrclk2[1]) rxdata_in_mux_q[1] <= rxdata_in_mux[1];
/*
    assign _rxdata_in[0][0] = txdata_out[0][0];
    assign _rxdata_in[0][1] = txdata_out[0][1];
    assign _rxdata_in[0][2] = txdata_out[1][0];
    assign _rxdata_in[0][3] = txdata_out[1][1];

    assign _rxdata_in[1][0] = txdata_out[0][2];
    assign _rxdata_in[1][1] = txdata_out[0][3];
    assign _rxdata_in[1][2] = txdata_out[1][2];
    assign _rxdata_in[1][3] = txdata_out[1][3];
*/
    xilinx_dcmac_wrapper i_xilinx_dcmac_wrapper (
        .tx_usrclk      (tx_usrclk),
        .rx_usrclk      (rx_usrclk),
        .tx_usrclk2     (tx_usrclk2),
        .rx_usrclk2     (rx_usrclk2),
        .core_clk       (core_clk),
        .ts_clk_0       (ts_clk_0),
        .tx_serdes_reset (tx_serdes_reset),
        .rx_serdes_reset (rx_serdes_reset),
        .tx_core_reset  (tx_core_reset),
        .rx_core_reset  (rx_core_reset),
//        .rxdata_in      (rxdata_in_mux_q),
        .rxdata_in      (rxdata_in_mux),
        .txdata_out     (txdata_out),
        .axis_rx        (axis_rx),
        .axis_tx        (axis_tx),
        .axil_if        (axil_dcmac)
    );
/*
    axi4s_intf_connector axis_connector (
        .from_tx(axis_tx),
        .to_rx(axis_rx)
    );
*/
endmodule : dcmac_wrapper
