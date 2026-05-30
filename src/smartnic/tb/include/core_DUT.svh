    // Local parameters
    localparam int NUM_CMAC = 2;
    localparam int AXIS_DATA_WID = 512;
    localparam int AXIS_DATA_BYTE_WID = AXIS_DATA_WID/8;

    //===================================
    // Device Under Test
    //===================================

    // Signals
    logic mod_rstn;
    logic mod_rst_done = 1'b0;
    logic axil_aclk;

    logic [NUM_CMAC-1:0] cmac_clk;

    // Shell interface
    shell_intf #(
        .NUM_PORTS          ( NUM_CMAC           ),
        .PORT_DATA_BYTE_WID ( AXIS_DATA_BYTE_WID )
    ) shell_if ();

    // DUT instance
    core DUT (.shell_if);

    //===================================
    // Local signals
    //===================================

    logic start_rx = 1'b1;
    logic axis_clk;

    // Interfaces
    axi4l_intf axil_if ();

    assign axil_if.aclk = axil_aclk;

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_WID(ADPT_TX_TID_WID), .TDEST_WID(PORT_WID)) axis_cmac_igr [NUM_CMAC] (.aclk(axis_clk));
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID))                                                  axis_cmac_egr [NUM_CMAC] (.aclk(axis_clk));
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_WID(ADPT_TX_TID_WID), .TDEST_WID(PORT_WID)) axis_h2c      [NUM_CMAC] (.aclk(axis_clk));
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TUSER_WID(TUSER_SMARTNIC_META_WID))             axis_c2h      [NUM_CMAC] (.aclk(axis_clk));

    tuser_smartnic_meta_t axis_c2h_tuser [NUM_CMAC];

    // Clocks and resets
    assign shell_if.clk        = axis_clk;
    assign shell_if.srst       = ~mod_rstn;
    assign shell_if.mgmt_clk   = axil_aclk;
    assign shell_if.mgmt_srst  = ~mod_rstn;
    assign shell_if.clk_100mhz = 1'b0;

    always @(posedge mod_rstn or negedge mod_rstn) begin
        if (!mod_rstn) mod_rst_done = 1'b0;
        else #(1us) mod_rst_done = mod_rstn;
    end

    generate
        for (genvar i = 0; i < NUM_CMAC; i++) begin : g__port_clk
            assign shell_if.port_clk [i] = cmac_clk[i];
            assign shell_if.port_srst[i] = ~mod_rstn;
        end
    endgenerate

    // AXI-L control interface
    assign shell_if.axil_awvalid = axil_if.awvalid;
    assign shell_if.axil_awaddr  = axil_if.awaddr;
    assign shell_if.axil_awprot  = '0;
    assign shell_if.axil_wvalid  = axil_if.wvalid;
    assign shell_if.axil_wdata   = axil_if.wdata;
    assign shell_if.axil_wstrb   = '1;
    assign shell_if.axil_bready  = axil_if.bready;
    assign shell_if.axil_arvalid = axil_if.arvalid;
    assign shell_if.axil_araddr  = axil_if.araddr;
    assign shell_if.axil_arprot  = '0;
    assign shell_if.axil_rready  = axil_if.rready;

    assign axil_if.awready = shell_if.axil_awready;
    assign axil_if.wready  = shell_if.axil_wready;
    assign axil_if.bvalid  = shell_if.axil_bvalid;
    assign axil_if.bresp   = shell_if.axil_bresp;
    assign axil_if.arready = shell_if.axil_arready;
    assign axil_if.rvalid  = shell_if.axil_rvalid;
    assign axil_if.rdata   = shell_if.axil_rdata;
    assign axil_if.rresp   = shell_if.axil_rresp;

    // CMAC Rx (axis_cmac_igr -> shell_if.port_rx)
    generate
        for (genvar i = 0; i < NUM_CMAC; i++) begin : g__port_rx
            assign shell_if.port_rx_tvalid[i] = axis_cmac_igr[i].tvalid;
            assign shell_if.port_rx_tdata [i] = axis_cmac_igr[i].tdata;
            assign shell_if.port_rx_tkeep [i] = axis_cmac_igr[i].tkeep;
            assign shell_if.port_rx_tlast [i] = axis_cmac_igr[i].tlast;
            assign shell_if.port_rx_tid   [i] = '0;
            assign shell_if.port_rx_tdest [i] = '0;
            assign shell_if.port_rx_tuser [i] = axis_cmac_igr[i].tuser;
            assign axis_cmac_igr[i].tready    = shell_if.port_rx_tready[i];
        end
    endgenerate

    // CMAC Tx (shell_if.port_tx -> axis_cmac_egr)
    generate
        for (genvar i = 0; i < NUM_CMAC; i++) begin : g__port_tx
            assign axis_cmac_egr[i].tvalid    = shell_if.port_tx_tvalid[i] && start_rx;
            assign axis_cmac_egr[i].tdata     = shell_if.port_tx_tdata [i];
            assign axis_cmac_egr[i].tkeep     = shell_if.port_tx_tkeep [i];
            assign axis_cmac_egr[i].tlast     = shell_if.port_tx_tlast [i];
            assign axis_cmac_egr[i].tid       = '0;
            assign axis_cmac_egr[i].tdest     = '0;
            assign axis_cmac_egr[i].tuser     = shell_if.port_tx_tuser [i];
            assign shell_if.port_tx_tready[i] = axis_cmac_egr[i].tready && start_rx;
        end
    endgenerate

    // H2C channel 0 (axis_h2c[0] -> shell_if.h2c)
    assign shell_if.h2c_tvalid = axis_h2c[0].tvalid;
    assign shell_if.h2c_tdata  = axis_h2c[0].tdata;
    assign shell_if.h2c_tkeep  = axis_h2c[0].tkeep;
    assign shell_if.h2c_tlast  = axis_h2c[0].tlast;
    assign shell_if.h2c_tid    = axis_h2c[0].tid;
    assign shell_if.h2c_tdest  = '0;
    assign shell_if.h2c_tuser  = axis_h2c[0].tuser;
    assign axis_h2c[0].tready  = shell_if.h2c_tready;

    // H2C channel 1 — tied off (core has one H2C channel)
    assign axis_h2c[1].tready  = 1'b0;

    // C2H channel 0 (shell_if.c2h -> axis_c2h[0])
    assign axis_c2h[0].tvalid            = shell_if.c2h_tvalid && start_rx;
    assign axis_c2h[0].tdata             = shell_if.c2h_tdata;
    assign axis_c2h[0].tkeep             = shell_if.c2h_tkeep;
    assign axis_c2h[0].tlast             = shell_if.c2h_tlast;
    assign axis_c2h[0].tid               = '0;
    assign axis_c2h[0].tdest             = '0;
    assign axis_c2h[0].tuser             = shell_if.c2h_tuser;
    assign shell_if.c2h_tready           = axis_c2h[0].tready && start_rx;

    // C2H channel 1 — tied off
    assign axis_c2h[1].tvalid = 1'b0;
    assign axis_c2h[1].tlast  = 1'b0;
    assign axis_c2h[1].tdata  = '0;
    assign axis_c2h[1].tkeep  = '0;
    assign axis_c2h[1].tid    = '0;
    assign axis_c2h[1].tdest  = '0;
    assign axis_c2h[1].tuser  = '0;
