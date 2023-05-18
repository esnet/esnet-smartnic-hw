module tb;
    import tb_pkg::*;
    import smartnic_250mhz_pkg::*;

    //===================================
    // Parameters
    //===================================
    localparam int NUM_INTF = 2;

    localparam int AXIS_DATA_BYTE_WID = 64;
    localparam int TKEEP_WID = AXIS_DATA_BYTE_WID;
    localparam int TDATA_WID = AXIS_DATA_BYTE_WID*8;

    //===================================
    // Typedefs
    //===================================
  
    //===================================
    // (Common) test environment
    //===================================
    tb_env #(.NUM_INTF(NUM_INTF)) env;

    //===================================
    // Device Under Test
    //===================================
    logic                    s_axil_awvalid;
    logic             [31:0] s_axil_awaddr;
    logic                    s_axil_awready;
    logic                    s_axil_wvalid;
    logic             [31:0] s_axil_wdata;
    logic                    s_axil_wready;
    logic                    s_axil_bvalid;
    logic              [1:0] s_axil_bresp;
    logic                    s_axil_bready;
    logic                    s_axil_arvalid;
    logic             [31:0] s_axil_araddr;
    logic                    s_axil_arready;
    logic                    s_axil_rvalid;
    logic             [31:0] s_axil_rdata;
    logic              [1:0] s_axil_rresp;
    logic                    s_axil_rready;

    logic      [NUM_INTF-1:0] s_axis_qdma_h2c_tvalid;
    logic  [512*NUM_INTF-1:0] s_axis_qdma_h2c_tdata;
    logic   [64*NUM_INTF-1:0] s_axis_qdma_h2c_tkeep;
    logic      [NUM_INTF-1:0] s_axis_qdma_h2c_tlast;
    logic   [16*NUM_INTF-1:0] s_axis_qdma_h2c_tuser_size;
    logic   [16*NUM_INTF-1:0] s_axis_qdma_h2c_tuser_src;
    logic   [16*NUM_INTF-1:0] s_axis_qdma_h2c_tuser_dst;
    logic      [NUM_INTF-1:0] s_axis_qdma_h2c_tready;

    logic     [NUM_INTF-1:0] m_axis_qdma_c2h_tvalid;
    logic [512*NUM_INTF-1:0] m_axis_qdma_c2h_tdata;
    logic  [64*NUM_INTF-1:0] m_axis_qdma_c2h_tkeep;
    logic     [NUM_INTF-1:0] m_axis_qdma_c2h_tlast;
    logic  [16*NUM_INTF-1:0] m_axis_qdma_c2h_tuser_size;
    logic  [16*NUM_INTF-1:0] m_axis_qdma_c2h_tuser_src;
    logic  [16*NUM_INTF-1:0] m_axis_qdma_c2h_tuser_dst;
    logic     [NUM_INTF-1:0] m_axis_qdma_c2h_tuser_rss_hash_valid;
    logic  [12*NUM_INTF-1:0] m_axis_qdma_c2h_tuser_rss_hash;
    logic     [NUM_INTF-1:0] m_axis_qdma_c2h_tready;

    logic     [NUM_INTF-1:0] m_axis_adap_tx_250mhz_tvalid;
    logic [512*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tdata;
    logic  [64*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tkeep;
    logic     [NUM_INTF-1:0] m_axis_adap_tx_250mhz_tlast;
    logic  [16*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tuser_size;
    logic  [16*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tuser_src;
    logic  [16*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tuser_dst;
    logic     [NUM_INTF-1:0] m_axis_adap_tx_250mhz_tready;

    logic      [NUM_INTF-1:0] s_axis_adap_rx_250mhz_tvalid;
    logic  [512*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tdata;
    logic   [64*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tkeep;
    logic      [NUM_INTF-1:0] s_axis_adap_rx_250mhz_tlast;
    logic   [16*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_size;
    logic   [16*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_src;
    logic   [16*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_dst;
    logic      [NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_rss_hash_valid;
    logic   [12*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_rss_hash;
    logic      [NUM_INTF-1:0] s_axis_adap_rx_250mhz_tready;

    logic                     mod_rstn;
    logic                     mod_rst_done;

    logic                     axil_aclk;

    logic                     ref_clk_100mhz;
    logic                     axis_aclk;

    // DUT instance
    smartnic_250mhz #(.NUM_INTF(NUM_INTF)) DUT(.*);

    //===================================
    // Local signals
    //===================================
    logic clk;
    logic rst;

    // Interfaces
    std_reset_intf #() reset_if (.clk(axil_aclk));

    axi4l_intf axil_if ();

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TUSER_T(tuser_c2h_t)) axis_c2h_in_if  [NUM_INTF] ();
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TUSER_T(tuser_c2h_t)) axis_c2h_out_if [NUM_INTF] ();

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TUSER_T(tuser_h2c_t)) axis_h2c_in_if  [NUM_INTF] ();
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TUSER_T(tuser_h2c_t)) axis_h2c_out_if [NUM_INTF] ();

    // Generate datapath clock (250MHz)
    initial clk = 1'b0;
    always #2000ps clk = ~clk;

    assign axis_aclk = clk;

    // Assign reset interfaces
    assign rst = reset_if.reset;
    assign reset_if.ready = mod_rst_done;

    assign mod_rstn = ~rst;

    // Generate AXI management clock (125MHz)
    initial axil_if.aclk = 1'b0;
    always #4ns axil_if.aclk = ~axil_if.aclk;

    assign axil_aclk = axil_if.aclk;

    // Assign AXI management reset
    assign axil_if.aresetn = ~rst;

    // Generate 100MHz clock
    initial ref_clk_100mhz = 1'b0;
    always #5ns ref_clk_100mhz = ~ref_clk_100mhz;

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

    // Assign AXI-S interfaces
    generate
        for (genvar g_if = 0; g_if < NUM_INTF; g_if++) begin : g__if
            // (Local) Signals
            tuser_h2c_t axis_h2c_in_if_tuser;
            tuser_c2h_t axis_c2h_in_if_tuser;
            tuser_h2c_t m_axis_adap_tx_250mhz_tuser;
            tuser_c2h_t m_axis_qdma_c2h_tuser;

            // H2C (In)
            assign s_axis_qdma_h2c_tvalid[g_if * 1 +: 1]                 = axis_h2c_in_if[g_if].tvalid;
            assign s_axis_qdma_h2c_tlast [g_if * 1 +: 1]                 = axis_h2c_in_if[g_if].tlast;
            assign s_axis_qdma_h2c_tkeep [g_if * TKEEP_WID +: TKEEP_WID] = axis_h2c_in_if[g_if].tkeep;
            assign s_axis_qdma_h2c_tdata [g_if * TDATA_WID +: TDATA_WID] = axis_h2c_in_if[g_if].tdata;

            assign axis_h2c_in_if_tuser = axis_h2c_in_if[g_if].tuser;
            assign s_axis_qdma_h2c_tuser_size [g_if * 16 +: 16] = axis_h2c_in_if_tuser.size;
            assign s_axis_qdma_h2c_tuser_src  [g_if * 16 +: 16] = axis_h2c_in_if_tuser.src;
            assign s_axis_qdma_h2c_tuser_dst  [g_if * 16 +: 16] = axis_h2c_in_if_tuser.dst;

            assign axis_h2c_in_if[g_if].tready = s_axis_qdma_h2c_tready [g_if*1 +: 1];

            assign axis_h2c_in_if[g_if].aclk = axis_aclk;
            assign axis_h2c_in_if[g_if].aresetn = mod_rstn;

            // C2H (In)
            assign s_axis_adap_rx_250mhz_tvalid[g_if * 1 +: 1]                 = axis_c2h_in_if[g_if].tvalid;
            assign s_axis_adap_rx_250mhz_tlast [g_if * 1 +: 1]                 = axis_c2h_in_if[g_if].tlast;
            assign s_axis_adap_rx_250mhz_tkeep [g_if * TKEEP_WID +: TKEEP_WID] = axis_c2h_in_if[g_if].tkeep;
            assign s_axis_adap_rx_250mhz_tdata [g_if * TDATA_WID +: TDATA_WID] = axis_c2h_in_if[g_if].tdata;

            assign axis_c2h_in_if_tuser = axis_c2h_in_if[g_if].tuser;
            assign s_axis_adap_rx_250mhz_tuser_size [g_if * 16 +: 16] = axis_c2h_in_if_tuser.size;
            assign s_axis_adap_rx_250mhz_tuser_src  [g_if * 16 +: 16] = axis_c2h_in_if_tuser.src;
            assign s_axis_adap_rx_250mhz_tuser_dst  [g_if * 16 +: 16] = axis_c2h_in_if_tuser.dst;
            assign s_axis_adap_rx_250mhz_tuser_rss_hash_valid [g_if *  1 +:  1] = axis_c2h_in_if_tuser.rss_hash_valid;
            assign s_axis_adap_rx_250mhz_tuser_rss_hash       [g_if * 12 +: 12] = axis_c2h_in_if_tuser.rss_hash;

            assign axis_c2h_in_if[g_if].tready = s_axis_adap_rx_250mhz_tready [g_if*1 +: 1];

            assign axis_c2h_in_if[g_if].aclk = axis_aclk;
            assign axis_c2h_in_if[g_if].aresetn = mod_rstn;

            // H2C (Out)
            assign axis_h2c_out_if[g_if].tvalid = m_axis_adap_tx_250mhz_tvalid[g_if * 1 +: 1];
            assign axis_h2c_out_if[g_if].tlast  = m_axis_adap_tx_250mhz_tlast [g_if * 1 +: 1];
            assign axis_h2c_out_if[g_if].tkeep  = m_axis_adap_tx_250mhz_tkeep [g_if * TKEEP_WID +: TKEEP_WID];
            assign axis_h2c_out_if[g_if].tdata  = m_axis_adap_tx_250mhz_tdata [g_if * TDATA_WID +: TDATA_WID];

            assign m_axis_adap_tx_250mhz_tuser.size = m_axis_adap_tx_250mhz_tuser_size [g_if * 16 +: 16];
            assign m_axis_adap_tx_250mhz_tuser.src  = m_axis_adap_tx_250mhz_tuser_src  [g_if * 16 +: 16];
            assign m_axis_adap_tx_250mhz_tuser.dst  = m_axis_adap_tx_250mhz_tuser_dst  [g_if * 16 +: 16];
            assign axis_h2c_out_if[g_if].tuser = m_axis_adap_tx_250mhz_tuser;

            assign m_axis_adap_tx_250mhz_tready [g_if*1 +: 1] = axis_h2c_out_if[g_if].tready;

            assign axis_h2c_out_if[g_if].aclk = axis_aclk;
            assign axis_h2c_out_if[g_if].aresetn = mod_rstn;

            // C2H (Out)
            assign axis_c2h_out_if[g_if].tvalid = m_axis_qdma_c2h_tvalid[g_if * 1 +: 1];
            assign axis_c2h_out_if[g_if].tlast  = m_axis_qdma_c2h_tlast [g_if * 1 +: 1];
            assign axis_c2h_out_if[g_if].tkeep  = m_axis_qdma_c2h_tkeep [g_if * TKEEP_WID +: TKEEP_WID];
            assign axis_c2h_out_if[g_if].tdata  = m_axis_qdma_c2h_tdata [g_if * TDATA_WID +: TDATA_WID];

            assign m_axis_qdma_c2h_tuser.size = m_axis_qdma_c2h_tuser_size [g_if * 16 +: 16];
            assign m_axis_qdma_c2h_tuser.src  = m_axis_qdma_c2h_tuser_src  [g_if * 16 +: 16];
            assign m_axis_qdma_c2h_tuser.dst  = m_axis_qdma_c2h_tuser_dst  [g_if * 16 +: 16];
            assign m_axis_qdma_c2h_tuser.rss_hash_valid = m_axis_qdma_c2h_tuser_rss_hash_valid [g_if * 1  +:  1];
            assign m_axis_qdma_c2h_tuser.rss_hash       = m_axis_qdma_c2h_tuser_rss_hash       [g_if * 12 +: 12];
            assign axis_c2h_out_if[g_if].tuser = m_axis_qdma_c2h_tuser;

            assign m_axis_qdma_c2h_tready [g_if*1 +: 1] = axis_c2h_out_if[g_if].tready;

            assign axis_c2h_out_if[g_if].aclk = axis_aclk;
            assign axis_c2h_out_if[g_if].aresetn = mod_rstn;

        end : g__if
    endgenerate
   
    //===================================
    // Build
    //===================================
    function void build();

        if (env == null) begin
            // Instantiate environment
            env = new("tb_env",0);   // bigendian=0 matches cmac's little endian axis

            // Connect
            env.reset_vif = reset_if;
            env.axil_vif = axil_if;

            // IF0
            env.axis_h2c_in_vif[0] = axis_h2c_in_if[0];
            env.axis_c2h_in_vif[0] = axis_c2h_in_if[0];
            env.axis_h2c_out_vif[0] = axis_h2c_out_if[0];
            env.axis_c2h_out_vif[0] = axis_c2h_out_if[0];

            // IF1
            env.axis_h2c_in_vif[1] = axis_h2c_in_if[1];
            env.axis_c2h_in_vif[1] = axis_c2h_in_if[1];
            env.axis_h2c_out_vif[1] = axis_h2c_out_if[1];
            env.axis_c2h_out_vif[1] = axis_c2h_out_if[1];

            env.connect();

        end
    endfunction

endmodule : tb
