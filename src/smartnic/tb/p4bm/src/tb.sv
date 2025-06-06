module tb;
    import tb_pkg::*;
    import smartnic_pkg::*;
    import pcap_pkg::*;

    // (Local) parameters
    localparam int NUM_CMAC = 2;

    localparam int AXIS_DATA_WID = 512;
    localparam int AXIS_DATA_BYTE_WID = AXIS_DATA_WID/8;

    //===================================
    // (Common) test environment
    //===================================
    tb_env #(.NUM_CMAC(NUM_CMAC)) env;

    //===================================
    // Device Under Test
    //===================================

    // Signals
    logic        s_axil_awvalid;
    logic [31:0] s_axil_awaddr;
    logic        s_axil_awready;
    logic        s_axil_wvalid;
    logic [31:0] s_axil_wdata;
    logic        s_axil_wready;
    logic        s_axil_bvalid;
    logic  [1:0] s_axil_bresp;
    logic        s_axil_bready;
    logic        s_axil_arvalid;
    logic [31:0] s_axil_araddr;
    logic        s_axil_arready;
    logic        s_axil_rvalid;
    logic [31:0] s_axil_rdata;
    logic  [1:0] s_axil_rresp;
    logic        s_axil_rready;

    logic       [NUM_CMAC-1:0] s_axis_adpt_tx_322mhz_tvalid;
    logic [(512*NUM_CMAC)-1:0] s_axis_adpt_tx_322mhz_tdata;
    logic  [(64*NUM_CMAC)-1:0] s_axis_adpt_tx_322mhz_tkeep;
    logic       [NUM_CMAC-1:0] s_axis_adpt_tx_322mhz_tlast;
    logic    [16*NUM_CMAC-1:0] s_axis_adpt_tx_322mhz_tid;
    logic     [2*NUM_CMAC-1:0] s_axis_adpt_tx_322mhz_tdest;
    logic       [NUM_CMAC-1:0] s_axis_adpt_tx_322mhz_tuser_err;
    logic       [NUM_CMAC-1:0] s_axis_adpt_tx_322mhz_tready;

    logic       [NUM_CMAC-1:0] m_axis_adpt_rx_322mhz_tvalid;
    logic [(512*NUM_CMAC)-1:0] m_axis_adpt_rx_322mhz_tdata;
    logic  [(64*NUM_CMAC)-1:0] m_axis_adpt_rx_322mhz_tkeep;
    logic       [NUM_CMAC-1:0] m_axis_adpt_rx_322mhz_tlast;
    logic   [(4*NUM_CMAC)-1:0] m_axis_adpt_rx_322mhz_tdest;
    logic       [NUM_CMAC-1:0] m_axis_adpt_rx_322mhz_tuser_err;
    logic       [NUM_CMAC-1:0] m_axis_adpt_rx_322mhz_tuser_rss_enable;
    logic  [(12*NUM_CMAC)-1:0] m_axis_adpt_rx_322mhz_tuser_rss_entropy;
    logic       [NUM_CMAC-1:0] m_axis_adpt_rx_322mhz_tready;

    logic       [NUM_CMAC-1:0] m_axis_cmac_tx_322mhz_tvalid;
    logic [(512*NUM_CMAC)-1:0] m_axis_cmac_tx_322mhz_tdata;
    logic  [(64*NUM_CMAC)-1:0] m_axis_cmac_tx_322mhz_tkeep;
    logic       [NUM_CMAC-1:0] m_axis_cmac_tx_322mhz_tlast;
    logic   [(4*NUM_CMAC)-1:0] m_axis_cmac_tx_322mhz_tdest;
    logic       [NUM_CMAC-1:0] m_axis_cmac_tx_322mhz_tuser_err;
    logic       [NUM_CMAC-1:0] m_axis_cmac_tx_322mhz_tready;

    logic       [NUM_CMAC-1:0] s_axis_cmac_rx_322mhz_tvalid;
    logic [(512*NUM_CMAC)-1:0] s_axis_cmac_rx_322mhz_tdata;
    logic  [(64*NUM_CMAC)-1:0] s_axis_cmac_rx_322mhz_tkeep;
    logic       [NUM_CMAC-1:0] s_axis_cmac_rx_322mhz_tlast;
    logic   [(2*NUM_CMAC)-1:0] s_axis_cmac_rx_322mhz_tdest;
    logic       [NUM_CMAC-1:0] s_axis_cmac_rx_322mhz_tuser_err;
    logic       [NUM_CMAC-1:0] s_axis_cmac_rx_322mhz_tready;

    logic                       mod_rstn;
    logic                       mod_rst_done;

    logic                       axil_aclk;
    logic        [NUM_CMAC-1:0] cmac_clk;

    // DUT instance
    smartnic #(.NUM_CMAC(NUM_CMAC)) DUT(.*);

    //===================================
    // Local signals
    //===================================
    logic clk;
    logic rst;

    logic axis_sample_clk;
    logic axis_sample_aresetn;

    // Interfaces
    std_reset_intf #() reset_if (.clk(clk));
    std_reset_intf #(.ACTIVE_LOW(1)) mgmt_reset_if (.clk(axil_aclk));

    axi4l_intf axil_if ();

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(adpt_tx_tid_t), .TDEST_T(igr_tdest_t)) axis_cmac_igr [NUM_CMAC] ();
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t),        .TDEST_T(port_t))      axis_cmac_egr [NUM_CMAC] ();

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(adpt_tx_tid_t), .TDEST_T(igr_tdest_t)) axis_h2c      [NUM_CMAC] ();
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t),        .TDEST_T(port_t))      axis_c2h      [NUM_CMAC] ();

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(igr_tdest_t)) axis_sample_if ();

    // Generate datapath clock (322MHz)
    initial clk = 1'b0;
    always #1553ps clk = ~clk; // 322MHz

    // Assign reset interfaces
    assign rst = reset_if.reset;
    assign reset_if.ready = mod_rst_done;

    assign mod_rstn = ~rst;

    // Generate AXI management clock (125MHz)
    initial axil_if.aclk = 1'b0;
    always #4ns axil_if.aclk = ~axil_if.aclk;

    assign axil_aclk = axil_if.aclk;

    // Assign AXI management reset
    assign axil_if.aresetn = mgmt_reset_if.reset;
    assign mgmt_reset_if.ready = mod_rst_done;

    // Assign CMAC clocks/resets
    generate
        for (genvar g_cmac=0; g_cmac < NUM_CMAC; g_cmac++) begin : g__cmac_clk
            assign      cmac_clk[g_cmac]         =  clk;
            assign      axis_h2c[g_cmac].aclk    =  clk;
            assign      axis_h2c[g_cmac].aresetn = ~rst;
            assign axis_cmac_igr[g_cmac].aclk    =  clk;
            assign axis_cmac_igr[g_cmac].aresetn = ~rst;
        end : g__cmac_clk
    endgenerate

    // AXI-S sample interface
    assign axis_sample_if.aclk = axis_sample_clk;
    assign axis_sample_if.aresetn = axis_sample_aresetn;

    // Assign AXI-L control interface
    assign s_axil_awvalid = axil_if.awvalid;
    assign s_axil_awaddr = axil_if.awaddr;
    assign s_axil_wvalid = axil_if.wvalid;
    assign s_axil_wdata = axil_if.wdata;
    assign s_axil_bready = axil_if.bready;
    assign s_axil_arvalid = axil_if.arvalid;
    assign s_axil_araddr = axil_if.araddr;
    assign s_axil_rready = axil_if.rready;
    assign axil_if.awready = s_axil_awready;
    assign axil_if.wready = s_axil_wready;
    assign axil_if.bvalid = s_axil_bvalid;
    assign axil_if.bresp = s_axil_bresp;
    assign axil_if.arready = s_axil_arready;
    assign axil_if.rvalid = s_axil_rvalid;
    assign axil_if.rdata = s_axil_rdata;
    assign axil_if.rresp = s_axil_rresp;

    // Assign AXI-S CMAC input interfaces
    assign s_axis_cmac_rx_322mhz_tvalid[0]    = axis_cmac_igr[0].tvalid;
    assign s_axis_cmac_rx_322mhz_tlast[0]     = axis_cmac_igr[0].tlast;
    assign s_axis_cmac_rx_322mhz_tdest[1:0]   = axis_cmac_igr[0].tdest;
    assign s_axis_cmac_rx_322mhz_tdata[511:0] = axis_cmac_igr[0].tdata;
    assign s_axis_cmac_rx_322mhz_tkeep[63:0]  = axis_cmac_igr[0].tkeep;
    assign s_axis_cmac_rx_322mhz_tuser_err[0] = axis_cmac_igr[0].tuser;
    assign axis_cmac_igr[0].tready = s_axis_cmac_rx_322mhz_tready[0];

    assign s_axis_cmac_rx_322mhz_tvalid[1]    = axis_cmac_igr[1].tvalid;
    assign s_axis_cmac_rx_322mhz_tlast[1]     = axis_cmac_igr[1].tlast;
    assign s_axis_cmac_rx_322mhz_tdest[3:2]   = axis_cmac_igr[1].tdest;
    assign s_axis_cmac_rx_322mhz_tdata[1023:512] = axis_cmac_igr[1].tdata;
    assign s_axis_cmac_rx_322mhz_tkeep[127:64]  = axis_cmac_igr[1].tkeep;
    assign s_axis_cmac_rx_322mhz_tuser_err[1] = axis_cmac_igr[1].tuser;
    assign axis_cmac_igr[1].tready = s_axis_cmac_rx_322mhz_tready[1];

    // Assign AXI-S CMAC output interfaces
    assign axis_cmac_egr[0].aclk   = clk;
    assign axis_cmac_egr[0].aresetn= ~rst;
    assign axis_cmac_egr[0].tvalid = m_axis_cmac_tx_322mhz_tvalid[0];
    assign axis_cmac_egr[0].tlast  = m_axis_cmac_tx_322mhz_tlast[0];
    assign axis_cmac_egr[0].tdest  = m_axis_cmac_tx_322mhz_tdest[3:0];
    assign axis_cmac_egr[0].tdata  = m_axis_cmac_tx_322mhz_tdata[511:0];
    assign axis_cmac_egr[0].tkeep  = m_axis_cmac_tx_322mhz_tkeep[63:0];
    assign axis_cmac_egr[0].tuser  = m_axis_cmac_tx_322mhz_tuser_err[0];
    assign m_axis_cmac_tx_322mhz_tready[0] = axis_cmac_egr[0].tready;

    assign axis_cmac_egr[1].aclk   = clk;
    assign axis_cmac_egr[1].aresetn= ~rst;
    assign axis_cmac_egr[1].tvalid = m_axis_cmac_tx_322mhz_tvalid[1];
    assign axis_cmac_egr[1].tlast  = m_axis_cmac_tx_322mhz_tlast[1];
    assign axis_cmac_egr[1].tdest  = m_axis_cmac_tx_322mhz_tdest[7:4];
    assign axis_cmac_egr[1].tdata  = m_axis_cmac_tx_322mhz_tdata[1023:512];
    assign axis_cmac_egr[1].tkeep  = m_axis_cmac_tx_322mhz_tkeep[127:64];
    assign axis_cmac_egr[1].tuser  = m_axis_cmac_tx_322mhz_tuser_err[1];
    assign m_axis_cmac_tx_322mhz_tready[1] = axis_cmac_egr[1].tready;

    // Assign AXI-S ADPT input interfaces
    assign s_axis_adpt_tx_322mhz_tvalid[0]    = axis_h2c[0].tvalid;
    assign s_axis_adpt_tx_322mhz_tlast[0]     = axis_h2c[0].tlast;
    assign s_axis_adpt_tx_322mhz_tid[15:0]    = axis_h2c[0].tid;
    assign s_axis_adpt_tx_322mhz_tdest[1:0]   = axis_h2c[0].tdest;
    assign s_axis_adpt_tx_322mhz_tdata[511:0] = axis_h2c[0].tdata;
    assign s_axis_adpt_tx_322mhz_tkeep[63:0]  = axis_h2c[0].tkeep;
    assign s_axis_adpt_tx_322mhz_tuser_err[0] = axis_h2c[0].tuser;
    assign axis_h2c[0].tready = s_axis_adpt_tx_322mhz_tready[0];

    assign s_axis_adpt_tx_322mhz_tvalid[1]    = axis_h2c[1].tvalid;
    assign s_axis_adpt_tx_322mhz_tlast[1]     = axis_h2c[1].tlast;
    assign s_axis_adpt_tx_322mhz_tid[31:16]   = axis_h2c[1].tid;
    assign s_axis_adpt_tx_322mhz_tdest[3:2]   = axis_h2c[1].tdest;
    assign s_axis_adpt_tx_322mhz_tdata[1023:512] = axis_h2c[1].tdata;
    assign s_axis_adpt_tx_322mhz_tkeep[127:64]  = axis_h2c[1].tkeep;
    assign s_axis_adpt_tx_322mhz_tuser_err[1] = axis_h2c[1].tuser;
    assign axis_h2c[1].tready = s_axis_adpt_tx_322mhz_tready[1];

    // Assign AXI-S ADPT output interfaces
    assign axis_c2h[0].aclk   = clk;
    assign axis_c2h[0].aresetn= ~rst;
    assign axis_c2h[0].tvalid = m_axis_adpt_rx_322mhz_tvalid[0];
    assign axis_c2h[0].tlast  = m_axis_adpt_rx_322mhz_tlast[0];
    assign axis_c2h[0].tdest  = m_axis_adpt_rx_322mhz_tdest[3:0];
    assign axis_c2h[0].tdata  = m_axis_adpt_rx_322mhz_tdata[511:0];
    assign axis_c2h[0].tkeep  = m_axis_adpt_rx_322mhz_tkeep[63:0];
    assign axis_c2h[0].tuser  = m_axis_adpt_rx_322mhz_tuser_err[0];
    assign m_axis_adpt_rx_322mhz_tready[0] = axis_c2h[0].tready;

    assign axis_c2h[1].aclk   = clk;
    assign axis_c2h[1].aresetn= ~rst;
    assign axis_c2h[1].tvalid = m_axis_adpt_rx_322mhz_tvalid[1];
    assign axis_c2h[1].tlast  = m_axis_adpt_rx_322mhz_tlast[1];
    assign axis_c2h[1].tdest  = m_axis_adpt_rx_322mhz_tdest[7:4];
    assign axis_c2h[1].tdata  = m_axis_adpt_rx_322mhz_tdata[1023:512];
    assign axis_c2h[1].tkeep  = m_axis_adpt_rx_322mhz_tkeep[127:64];
    assign axis_c2h[1].tuser  = m_axis_adpt_rx_322mhz_tuser_err[1];
    assign m_axis_adpt_rx_322mhz_tready[1] = axis_c2h[1].tready;

    // axis_out tvalid monitors
    always @(negedge axis_cmac_egr[0].tvalid) if (axis_cmac_egr[0].tready && !axis_cmac_egr[0].sop) $display ("Port0: tvalid gap.  May lead to ONS underflow!");
    always @(negedge axis_cmac_egr[1].tvalid) if (axis_cmac_egr[1].tready && !axis_cmac_egr[1].sop) $display ("Port1: tvalid gap.  May lead to ONS underflow!");
    always @(negedge      axis_c2h[0].tvalid) if (axis_c2h[0].tready && !axis_c2h[0].sop)           $display ("Port2: tvalid gap.  May lead to ONS underflow!");
    always @(negedge      axis_c2h[1].tvalid) if (axis_c2h[1].tready && !axis_c2h[1].sop)           $display ("Port3: tvalid gap.  May lead to ONS underflow!");

    //===================================
    // Build
    //===================================
    function void build();

        if (env == null) begin
            // Instantiate environment
            env = new("tb_env",0);   // bigendian=0 matches cmac's little endian axis

            // Connect
            env.reset_vif = reset_if;
            env.mgmt_reset_vif = mgmt_reset_if;
            env.axil_vif = axil_if;

            env.axis_cmac_igr_vif[0] = axis_cmac_igr[0];
            env.axis_cmac_igr_vif[1] = axis_cmac_igr[1];
            env.axis_h2c_vif[0]      = axis_h2c[0];
            env.axis_h2c_vif[1]      = axis_h2c[1];
            env.axis_cmac_egr_vif[0] = axis_cmac_egr[0];
            env.axis_cmac_egr_vif[1] = axis_cmac_egr[1];
            env.axis_c2h_vif[0]      = axis_c2h[0];
            env.axis_c2h_vif[1]      = axis_c2h[1];

            // temporarily replaced (dynamic) vif for loops below with (static) assignments above, due to errors.
            // for (int i=0; i < NUM_CMAC; i++) env.axis_cmac_igr_vif[i] = axis_cmac_igr[i];
            // for (int i=0; i < NUM_CMAC; i++) env.axis_cmac_egr_vif[i] = axis_cmac_egr[i];

            env.axis_sample_vif = axis_sample_if;

            env.connect();

        end
    endfunction

    // Monitor sample interface - count and display packets.
    int sample_pkt_cnt;
    byte sample_data[$];
    always begin
       env.axis_sample.capture_pkt_data(sample_data);
       sample_pkt_cnt++;
       $display($sformatf("Sample packet # %0d", sample_pkt_cnt));
       pcap_pkg::print_pkt_data(sample_data);
    end

    // Export AXI-L accessors to VitisNetP4 shared library
    export "DPI-C" task axi_lite_wr;
    task axi_lite_wr(input int address, input int data);
        env.vitisnetp4_write(address, data);
    endtask

    export "DPI-C" task axi_lite_rd;
    task axi_lite_rd(input int address, inout int data);
        env.vitisnetp4_read(address, data);
    endtask

endmodule : tb
