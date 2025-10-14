    // Local parameters
    localparam int AXIS_DATA_WID = 512;
    localparam int AXIS_DATA_BYTE_WID = AXIS_DATA_WID/8;

    localparam int NUM_HOST_IFS = 3;  // Number of HOST interfaces.
    localparam int NUM_PROC_PORTS = 2;     // Number of processor ports (per vitisnetp4 processor).

    //===================================
    // Device Under Test
    //===================================
    // Signals
    logic        clk;
    logic        rstn;

    logic [63:0] timestamp;

    axi4l_intf axil_if       ();
    axi4l_intf app_axil_if   ();

    axi4s_intf #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_in_if[NUM_PROC_PORTS] (.aclk(clk));
    axi4s_intf #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_out_if[NUM_PROC_PORTS] (.aclk(clk));

    axi4s_intf #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_h2c_if[NUM_HOST_IFS][NUM_PROC_PORTS] (.aclk(clk));
    axi4s_intf #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_c2h_if[NUM_HOST_IFS][NUM_PROC_PORTS] (.aclk(clk));

    logic [NUM_PROC_PORTS-1:0]        axis_app_igr_tvalid;
    logic [NUM_PROC_PORTS-1:0]        axis_app_igr_tready;
    logic [NUM_PROC_PORTS-1:0][511:0] axis_app_igr_tdata;
    logic [NUM_PROC_PORTS-1:0][63:0]  axis_app_igr_tkeep;
    logic [NUM_PROC_PORTS-1:0]        axis_app_igr_tlast;
    logic [NUM_PROC_PORTS-1:0][3:0]   axis_app_igr_tid;
    logic [NUM_PROC_PORTS-1:0][3:0]   axis_app_igr_tdest;
    logic [NUM_PROC_PORTS-1:0][15:0]  axis_app_igr_tuser_pid;

    generate
        for (genvar j = 0; j < NUM_PROC_PORTS; j += 1) begin
            assign axis_app_igr_tvalid[j]    = axis_in_if[j].tvalid; 
            assign axis_in_if[j].tready      = axis_app_igr_tready[j];
            assign axis_app_igr_tdata[j]     = axis_in_if[j].tdata;
            assign axis_app_igr_tkeep[j]     = axis_in_if[j].tkeep;
            assign axis_app_igr_tlast[j]     = axis_in_if[j].tlast;
            assign axis_app_igr_tid[j]       = axis_in_if[j].tid;
            assign axis_app_igr_tdest[j]     = axis_in_if[j].tdest;
        end
    endgenerate

    logic [NUM_PROC_PORTS-1:0]        axis_app_egr_tvalid;
    logic [NUM_PROC_PORTS-1:0]        axis_app_egr_tready;
    logic [NUM_PROC_PORTS-1:0][511:0] axis_app_egr_tdata;
    logic [NUM_PROC_PORTS-1:0][63:0]  axis_app_egr_tkeep;
    logic [NUM_PROC_PORTS-1:0]        axis_app_egr_tlast;
    logic [NUM_PROC_PORTS-1:0][3:0]   axis_app_egr_tid;
    logic [NUM_PROC_PORTS-1:0][3:0]   axis_app_egr_tdest;
    logic [NUM_PROC_PORTS-1:0]        axis_app_egr_tuser_rss_enable;
    logic [NUM_PROC_PORTS-1:0][11:0]  axis_app_egr_tuser_rss_entropy;

    generate
        for (genvar j = 0; j < NUM_PROC_PORTS; j += 1) begin
            tuser_smartnic_meta_t axis_out_if_tuser;
            assign axis_out_if[j].tvalid             = axis_app_egr_tvalid[j];
            assign axis_app_egr_tready[j]            = axis_out_if[j].tready;
            assign axis_out_if[j].tdata              = axis_app_egr_tdata[j];
            assign axis_out_if[j].tkeep              = axis_app_egr_tkeep[j];
            assign axis_out_if[j].tlast              = axis_app_egr_tlast[j];
            assign axis_out_if[j].tid                = axis_app_egr_tid[j];
            assign axis_out_if[j].tdest              = axis_app_egr_tdest[j];
            assign axis_out_if_tuser.rss_enable   = axis_app_egr_tuser_rss_enable[j];
            assign axis_out_if_tuser.rss_entropy  = axis_app_egr_tuser_rss_entropy[j];
            assign axis_out_if[j].tuser = axis_out_if_tuser;
        end
    endgenerate

    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0]        axis_h2c_tvalid;
    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0]        axis_h2c_tready;
    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0][511:0] axis_h2c_tdata;
    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0][63:0]  axis_h2c_tkeep;
    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0]        axis_h2c_tlast;
    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0][3:0]   axis_h2c_tid;
    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0][3:0]   axis_h2c_tdest;

    generate
        for (genvar i = 0; i < NUM_PROC_PORTS; i += 1) begin
            for (genvar j = 0; j < NUM_HOST_IFS; j += 1) begin
                assign axis_h2c_tvalid[j*NUM_PROC_PORTS+i]    = axis_h2c_if[j][i].tvalid;
                assign axis_h2c_tdata[j*NUM_PROC_PORTS+i]     = axis_h2c_if[j][i].tdata;
                assign axis_h2c_tkeep[j*NUM_PROC_PORTS+i]     = axis_h2c_if[j][i].tkeep;
                assign axis_h2c_tlast[j*NUM_PROC_PORTS+i]     = axis_h2c_if[j][i].tlast;
                assign axis_h2c_tid[j*NUM_PROC_PORTS+i]       = axis_h2c_if[j][i].tid;
                assign axis_h2c_tdest[j*NUM_PROC_PORTS+i]     = axis_h2c_if[j][i].tdest;

                assign axis_h2c_if[j][i].tready          = axis_h2c_tready[j*NUM_PROC_PORTS+i];
            end
        end
    endgenerate

    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0]        axis_c2h_tvalid;
    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0]        axis_c2h_tready;
    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0][511:0] axis_c2h_tdata;
    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0][63:0]  axis_c2h_tkeep;
    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0]        axis_c2h_tlast;
    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0][3:0]   axis_c2h_tid;
    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0][3:0]   axis_c2h_tdest;
    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0][15:0]  axis_c2h_tuser_pid;
    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0]        axis_c2h_tuser_trunc_enable;
    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0][15:0]  axis_c2h_tuser_trunc_length;
    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0]        axis_c2h_tuser_rss_enable;
    logic [NUM_PROC_PORTS*NUM_HOST_IFS-1:0][11:0]  axis_c2h_tuser_rss_entropy;

    generate
        for (genvar i = 0; i < NUM_PROC_PORTS; i += 1) begin
            for (genvar j = 0; j < NUM_HOST_IFS; j += 1) begin
                tuser_smartnic_meta_t axis_c2h_if_tuser;
                assign axis_c2h_if[j][i].tvalid             = axis_c2h_tvalid[j*NUM_PROC_PORTS+i];
                assign axis_c2h_if[j][i].tdata              = axis_c2h_tdata[j*NUM_PROC_PORTS+i];
                assign axis_c2h_if[j][i].tkeep              = axis_c2h_tkeep[j*NUM_PROC_PORTS+i];
                assign axis_c2h_if[j][i].tlast              = axis_c2h_tlast[j*NUM_PROC_PORTS+i];
                assign axis_c2h_if[j][i].tid                = axis_c2h_tid[j*NUM_PROC_PORTS+i];
                assign axis_c2h_if[j][i].tdest              = axis_c2h_tdest[j*NUM_PROC_PORTS+i];
                assign axis_c2h_if_tuser.rss_enable   = axis_c2h_tuser_rss_enable[j*NUM_PROC_PORTS+i];
                assign axis_c2h_if_tuser.rss_entropy  = axis_c2h_tuser_rss_entropy[j*NUM_PROC_PORTS+i];
                assign axis_c2h_if[j][i].tuser = axis_c2h_if_tuser;

                assign axis_c2h_tready[j*NUM_PROC_PORTS+i]       = axis_c2h_if[j][i].tready;
            end
        end
    endgenerate

    // DUT instance
    smartnic_app DUT (
        .core_clk                       (clk),
        .core_rstn                      (rstn),
        .timestamp                      (timestamp),
        .axil_aclk                      (axil_if.aclk),
        // P4 AXI-L control interface
        .axil_aresetn                   (axil_if.aresetn),
        .axil_awvalid                   (axil_if.awvalid),
        .axil_awready                   (axil_if.awready),
        .axil_awaddr                    (axil_if.awaddr),
        .axil_awprot                    (axil_if.awprot),
        .axil_wvalid                    (axil_if.wvalid),
        .axil_wready                    (axil_if.wready),
        .axil_wdata                     (axil_if.wdata),
        .axil_wstrb                     (axil_if.wstrb),
        .axil_bvalid                    (axil_if.bvalid),
        .axil_bready                    (axil_if.bready),
        .axil_bresp                     (axil_if.bresp),
        .axil_arvalid                   (axil_if.arvalid),
        .axil_arready                   (axil_if.arready),
        .axil_araddr                    (axil_if.araddr),
        .axil_arprot                    (axil_if.arprot),
        .axil_rvalid                    (axil_if.rvalid),
        .axil_rready                    (axil_if.rready),
        .axil_rdata                     (axil_if.rdata),
        .axil_rresp                     (axil_if.rresp),
        // App AXI-L control interface
        .app_axil_aresetn               (app_axil_if.aresetn),
        .app_axil_awvalid               (app_axil_if.awvalid),
        .app_axil_awready               (app_axil_if.awready),
        .app_axil_awaddr                (app_axil_if.awaddr),
        .app_axil_awprot                (app_axil_if.awprot),
        .app_axil_wvalid                (app_axil_if.wvalid),
        .app_axil_wready                (app_axil_if.wready),
        .app_axil_wdata                 (app_axil_if.wdata),
        .app_axil_wstrb                 (app_axil_if.wstrb),
        .app_axil_bvalid                (app_axil_if.bvalid),
        .app_axil_bready                (app_axil_if.bready),
        .app_axil_bresp                 (app_axil_if.bresp),
        .app_axil_arvalid               (app_axil_if.arvalid),
        .app_axil_arready               (app_axil_if.arready),
        .app_axil_araddr                (app_axil_if.araddr),
        .app_axil_arprot                (app_axil_if.arprot),
        .app_axil_rvalid                (app_axil_if.rvalid),
        .app_axil_rready                (app_axil_if.rready),
        .app_axil_rdata                 (app_axil_if.rdata),
        .app_axil_rresp                 (app_axil_if.rresp),
         // AXI-S data interface (from switch output 0, to app)
        .axis_app_igr_tvalid            ( axis_app_igr_tvalid ),
        .axis_app_igr_tready            ( axis_app_igr_tready ),
        .axis_app_igr_tdata             ( axis_app_igr_tdata ),
        .axis_app_igr_tkeep             ( axis_app_igr_tkeep ),
        .axis_app_igr_tlast             ( axis_app_igr_tlast ),
        .axis_app_igr_tid               ( axis_app_igr_tid ),
        .axis_app_igr_tdest             ( axis_app_igr_tdest ),
        // AXI-S data interface (from app, to switch input 0)
        .axis_app_egr_tvalid            ( axis_app_egr_tvalid ),
        .axis_app_egr_tready            ( axis_app_egr_tready ),
        .axis_app_egr_tdata             ( axis_app_egr_tdata ),
        .axis_app_egr_tkeep             ( axis_app_egr_tkeep ),
        .axis_app_egr_tlast             ( axis_app_egr_tlast ),
        .axis_app_egr_tid               ( axis_app_egr_tid ),
        .axis_app_egr_tdest             ( axis_app_egr_tdest ),
        .axis_app_egr_tuser_rss_enable  ( axis_app_egr_tuser_rss_enable ),
        .axis_app_egr_tuser_rss_entropy ( axis_app_egr_tuser_rss_entropy ),
         // AXI-S data interface (from switch output 0, to app)
        .axis_h2c_tvalid                ( axis_h2c_tvalid ),
        .axis_h2c_tready                ( axis_h2c_tready ),
        .axis_h2c_tdata                 ( axis_h2c_tdata ),
        .axis_h2c_tkeep                 ( axis_h2c_tkeep ),
        .axis_h2c_tlast                 ( axis_h2c_tlast ),
        .axis_h2c_tid                   ( axis_h2c_tid ),
        .axis_h2c_tdest                 ( axis_h2c_tdest ),
        // AXI-S data interface (from app, to switch input 0)
        .axis_c2h_tvalid                ( axis_c2h_tvalid ),
        .axis_c2h_tready                ( axis_c2h_tready ),
        .axis_c2h_tdata                 ( axis_c2h_tdata ),
        .axis_c2h_tkeep                 ( axis_c2h_tkeep ),
        .axis_c2h_tlast                 ( axis_c2h_tlast ),
        .axis_c2h_tid                   ( axis_c2h_tid ),
        .axis_c2h_tdest                 ( axis_c2h_tdest ),
        .axis_c2h_tuser_rss_enable      ( axis_c2h_tuser_rss_enable ),
        .axis_c2h_tuser_rss_entropy     ( axis_c2h_tuser_rss_entropy ),
        // egress flow control interface
        .egr_flow_ctl                   ( '0 )
    );
