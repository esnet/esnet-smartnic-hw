module xilinx_alveo_cmac #(
    parameter int PORT_ID = 0
) (
    // Clock/reset
    input  logic           clk,
    input  logic           srstn,

    // From/to pins
    // -- QSFPs
    input  logic           qsfp_refclk_p,
    input  logic           qsfp_refclk_n,
    input  logic [3:0]     qsfp_rxp,
    input  logic [3:0]     qsfp_rxn,
    output logic [3:0]     qsfp_txp,
    output logic [3:0]     qsfp_txn,
 
    // From/to core   
    // -- AXI-L
    axi4l_intf.peripheral  axil_if,
    // -- AXI-S
    axi4s_intf.tx          axis_rx,
    axi4s_intf.rx_async    axis_tx
);

    // =========================================================================
    // Imports
    // =========================================================================
    import xilinx_cmac_pkg::*;

    // =========================================================================
    // Interfaces
    // =========================================================================
    axi4l_intf #() axil_cmac ();
    axi4s_intf #(.DATA_BYTE_WID (AXIS_DATA_BYTE_WID), .TID_T(axis_tid_t), .TUSER_T(axis_tuser_t)) __axis_rx ();
    axi4s_intf #(.DATA_BYTE_WID (AXIS_DATA_BYTE_WID), .TID_T(axis_tid_t), .TUSER_T(axis_tuser_t)) __axis_tx ();

    // =========================================================================
    // CMAC IP
    // =========================================================================
    xilinx_cmac_wrapper #(
        .PORT_ID ( PORT_ID )
    ) i_xilinx_cmac_wrapper (
        .clk,
        .srstn,
        .qsfp_refclk_p,
        .qsfp_refclk_n,
        .qsfp_rxp,
        .qsfp_rxn,
        .qsfp_txp,
        .qsfp_txn,
        .axis_rx ( __axis_rx ),
        .axis_tx ( __axis_tx ),
        .axil_if ( axil_cmac )
    );

    // =========================================================================
    // Connect interfaces
    // =========================================================================
    // AXI-L
    axi4l_intf_connector i_axi4l_intf_connector (
        .axi4l_if_from_controller ( axil_if ),
        .axi4l_if_to_peripheral   ( axil_cmac )
    );

    // AXI-S
    axi4s_intf_connector i_axi4s_intf_connector__rx (
        .axi4s_from_tx ( __axis_rx ),
        .axi4s_to_rx   ( axis_rx )
    );
    assign axis_tx.aclk = __axis_tx.aclk;
    assign axis_tx.aresetn = __axis_tx.aresetn;
    assign __axis_tx.tvalid = axis_tx.tvalid;
    assign __axis_tx.tlast = axis_tx.tlast;
    assign __axis_tx.tkeep = axis_tx.tkeep;
    assign __axis_tx.tdata = axis_tx.tdata;
    assign __axis_tx.tuser = axis_tx.tuser;
    assign __axis_tx.tid = axis_tx.tid;
    assign __axis_tx.tdest = axis_tx.tdest;

endmodule : xilinx_alveo_cmac
