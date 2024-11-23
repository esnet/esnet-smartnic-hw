module tb;
    import tb_pkg::*;
    import smartnic_pkg::*;

    // (Local) parameters
    localparam int AXIS_DATA_WID = 512;
    localparam int AXIS_DATA_BYTE_WID = AXIS_DATA_WID/8;

    localparam int HOST_NUM_IFS = 3;  // Number of HOST interfaces.
    localparam int NUM_PORTS = 2;     // Number of processor ports (per vitisnetp4 processor).

    //===================================
    // (Common) test environment
    //===================================
    tb_env env;

    //===================================
    // Device Under Test
    //===================================

    // Signals
    logic        clk;
    logic        rstn;

    logic [63:0] timestamp;

    axi4l_intf axil_if       ();
    axi4l_intf app_axil_if   ();

    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_in_if[NUM_PORTS] ();
    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_out_if[NUM_PORTS] ();

    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_h2c_if[HOST_NUM_IFS][NUM_PORTS] ();
    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_c2h_if[HOST_NUM_IFS][NUM_PORTS] ();

    logic [NUM_PORTS-1:0]        axis_app_igr_tvalid;
    logic [NUM_PORTS-1:0]        axis_app_igr_tready;
    logic [NUM_PORTS-1:0][511:0] axis_app_igr_tdata;
    logic [NUM_PORTS-1:0][63:0]  axis_app_igr_tkeep;
    logic [NUM_PORTS-1:0]        axis_app_igr_tlast;
    logic [NUM_PORTS-1:0][3:0]   axis_app_igr_tid;
    logic [NUM_PORTS-1:0][3:0]   axis_app_igr_tdest;
    logic [NUM_PORTS-1:0][15:0]  axis_app_igr_tuser_pid;

    generate
        for (genvar j = 0; j < NUM_PORTS; j += 1) begin
            assign axis_app_igr_tvalid[j]    = axis_in_if[j].tvalid; 
            assign axis_in_if[j].tready      = axis_app_igr_tready[j];
            assign axis_app_igr_tdata[j]     = axis_in_if[j].tdata;
            assign axis_app_igr_tkeep[j]     = axis_in_if[j].tkeep;
            assign axis_app_igr_tlast[j]     = axis_in_if[j].tlast;
            assign axis_app_igr_tid[j]       = axis_in_if[j].tid;
            assign axis_app_igr_tdest[j]     = axis_in_if[j].tdest;
            assign axis_app_igr_tuser_pid[j] = axis_in_if[j].tuser.pid;
        end
    endgenerate

    logic [NUM_PORTS-1:0]        axis_app_egr_tvalid;
    logic [NUM_PORTS-1:0]        axis_app_egr_tready;
    logic [NUM_PORTS-1:0][511:0] axis_app_egr_tdata;
    logic [NUM_PORTS-1:0][63:0]  axis_app_egr_tkeep;
    logic [NUM_PORTS-1:0]        axis_app_egr_tlast;
    logic [NUM_PORTS-1:0][3:0]   axis_app_egr_tid;
    logic [NUM_PORTS-1:0][3:0]   axis_app_egr_tdest;
    logic [NUM_PORTS-1:0][15:0]  axis_app_egr_tuser_pid;
    logic [NUM_PORTS-1:0]        axis_app_egr_tuser_trunc_enable;
    logic [NUM_PORTS-1:0][15:0]  axis_app_egr_tuser_trunc_length;
    logic [NUM_PORTS-1:0]        axis_app_egr_tuser_rss_enable;
    logic [NUM_PORTS-1:0][11:0]  axis_app_egr_tuser_rss_entropy;

    generate
        for (genvar j = 0; j < NUM_PORTS; j += 1) begin
            assign axis_out_if[j].tvalid             = axis_app_egr_tvalid[j];
            assign axis_app_egr_tready[j]            = axis_out_if[j].tready;
            assign axis_out_if[j].tdata              = axis_app_egr_tdata[j];
            assign axis_out_if[j].tkeep              = axis_app_egr_tkeep[j];
            assign axis_out_if[j].tlast              = axis_app_egr_tlast[j];
            assign axis_out_if[j].tid                = axis_app_egr_tid[j];
            assign axis_out_if[j].tdest              = axis_app_egr_tdest[j];
            assign axis_out_if[j].tuser.pid          = axis_app_egr_tuser_pid[j];
            assign axis_out_if[j].tuser.trunc_enable = axis_app_egr_tuser_trunc_enable[j];
            assign axis_out_if[j].tuser.trunc_length = axis_app_egr_tuser_trunc_length[j];
            assign axis_out_if[j].tuser.rss_enable   = axis_app_egr_tuser_rss_enable[j];
            assign axis_out_if[j].tuser.rss_entropy  = axis_app_egr_tuser_rss_entropy[j];
        end
    endgenerate

    logic [NUM_PORTS*HOST_NUM_IFS-1:0]        axis_h2c_tvalid;
    logic [NUM_PORTS*HOST_NUM_IFS-1:0]        axis_h2c_tready;
    logic [NUM_PORTS*HOST_NUM_IFS-1:0][511:0] axis_h2c_tdata;
    logic [NUM_PORTS*HOST_NUM_IFS-1:0][63:0]  axis_h2c_tkeep;
    logic [NUM_PORTS*HOST_NUM_IFS-1:0]        axis_h2c_tlast;
    logic [NUM_PORTS*HOST_NUM_IFS-1:0][3:0]   axis_h2c_tid;
    logic [NUM_PORTS*HOST_NUM_IFS-1:0][3:0]   axis_h2c_tdest;
    logic [NUM_PORTS*HOST_NUM_IFS-1:0][15:0]  axis_h2c_tuser_pid;

    generate
        for (genvar i = 0; i < NUM_PORTS; i += 1) begin
            for (genvar j = 0; j < HOST_NUM_IFS; j += 1) begin
                assign axis_h2c_tvalid[j*NUM_PORTS+i]    = axis_h2c_if[j][i].tvalid;
                assign axis_h2c_tdata[j*NUM_PORTS+i]     = axis_h2c_if[j][i].tdata;
                assign axis_h2c_tkeep[j*NUM_PORTS+i]     = axis_h2c_if[j][i].tkeep;
                assign axis_h2c_tlast[j*NUM_PORTS+i]     = axis_h2c_if[j][i].tlast;
                assign axis_h2c_tid[j*NUM_PORTS+i]       = axis_h2c_if[j][i].tid;
                assign axis_h2c_tdest[j*NUM_PORTS+i]     = axis_h2c_if[j][i].tdest;
                assign axis_h2c_tuser_pid[j*NUM_PORTS+i] = axis_h2c_if[j][i].tuser.pid;

                assign axis_h2c_if[j][i].tready          = axis_h2c_tready[j*NUM_PORTS+i];
            end
        end
    endgenerate

    logic [NUM_PORTS*HOST_NUM_IFS-1:0]        axis_c2h_tvalid;
    logic [NUM_PORTS*HOST_NUM_IFS-1:0]        axis_c2h_tready;
    logic [NUM_PORTS*HOST_NUM_IFS-1:0][511:0] axis_c2h_tdata;
    logic [NUM_PORTS*HOST_NUM_IFS-1:0][63:0]  axis_c2h_tkeep;
    logic [NUM_PORTS*HOST_NUM_IFS-1:0]        axis_c2h_tlast;
    logic [NUM_PORTS*HOST_NUM_IFS-1:0][3:0]   axis_c2h_tid;
    logic [NUM_PORTS*HOST_NUM_IFS-1:0][3:0]   axis_c2h_tdest;
    logic [NUM_PORTS*HOST_NUM_IFS-1:0][15:0]  axis_c2h_tuser_pid;
    logic [NUM_PORTS*HOST_NUM_IFS-1:0]        axis_c2h_tuser_trunc_enable;
    logic [NUM_PORTS*HOST_NUM_IFS-1:0][15:0]  axis_c2h_tuser_trunc_length;
    logic [NUM_PORTS*HOST_NUM_IFS-1:0]        axis_c2h_tuser_rss_enable;
    logic [NUM_PORTS*HOST_NUM_IFS-1:0][11:0]  axis_c2h_tuser_rss_entropy;

    generate
        for (genvar i = 0; i < NUM_PORTS; i += 1) begin
            for (genvar j = 0; j < HOST_NUM_IFS; j += 1) begin
                assign axis_c2h_if[j][i].aclk               = clk;
                assign axis_c2h_if[j][i].aresetn            = rstn;
                assign axis_c2h_if[j][i].tvalid             = axis_c2h_tvalid[j*NUM_PORTS+i];
                assign axis_c2h_if[j][i].tdata              = axis_c2h_tdata[j*NUM_PORTS+i];
                assign axis_c2h_if[j][i].tkeep              = axis_c2h_tkeep[j*NUM_PORTS+i];
                assign axis_c2h_if[j][i].tlast              = axis_c2h_tlast[j*NUM_PORTS+i];
                assign axis_c2h_if[j][i].tid                = axis_c2h_tid[j*NUM_PORTS+i];
                assign axis_c2h_if[j][i].tdest              = axis_c2h_tdest[j*NUM_PORTS+i];
                assign axis_c2h_if[j][i].tuser.pid          = axis_c2h_tuser_pid[j*NUM_PORTS+i];
                assign axis_c2h_if[j][i].tuser.trunc_enable = axis_c2h_tuser_trunc_enable[j*NUM_PORTS+i];
                assign axis_c2h_if[j][i].tuser.trunc_length = axis_c2h_tuser_trunc_length[j*NUM_PORTS+i];
                assign axis_c2h_if[j][i].tuser.rss_enable   = axis_c2h_tuser_rss_enable[j*NUM_PORTS+i];
                assign axis_c2h_if[j][i].tuser.rss_entropy  = axis_c2h_tuser_rss_entropy[j*NUM_PORTS+i];

                assign axis_c2h_tready[j*NUM_PORTS+i]       = axis_c2h_if[j][i].tready;
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
        .axis_app_igr_tuser_pid         ( axis_app_igr_tuser_pid ),
        // AXI-S data interface (from app, to switch input 0)
        .axis_app_egr_tvalid            ( axis_app_egr_tvalid ),
        .axis_app_egr_tready            ( axis_app_egr_tready ),
        .axis_app_egr_tdata             ( axis_app_egr_tdata ),
        .axis_app_egr_tkeep             ( axis_app_egr_tkeep ),
        .axis_app_egr_tlast             ( axis_app_egr_tlast ),
        .axis_app_egr_tid               ( axis_app_egr_tid ),
        .axis_app_egr_tdest             ( axis_app_egr_tdest ),
        .axis_app_egr_tuser_pid         ( axis_app_egr_tuser_pid ),
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
        .axis_h2c_tuser_pid             ( axis_h2c_tuser_pid ),
        // AXI-S data interface (from app, to switch input 0)
        .axis_c2h_tvalid                ( axis_c2h_tvalid ),
        .axis_c2h_tready                ( axis_c2h_tready ),
        .axis_c2h_tdata                 ( axis_c2h_tdata ),
        .axis_c2h_tkeep                 ( axis_c2h_tkeep ),
        .axis_c2h_tlast                 ( axis_c2h_tlast ),
        .axis_c2h_tid                   ( axis_c2h_tid ),
        .axis_c2h_tdest                 ( axis_c2h_tdest ),
        .axis_c2h_tuser_pid             ( axis_c2h_tuser_pid ),
        .axis_c2h_tuser_rss_enable      ( axis_c2h_tuser_rss_enable ),
        .axis_c2h_tuser_rss_entropy     ( axis_c2h_tuser_rss_entropy ),
        // egress flow control interface
        .egr_flow_ctl                   ( '0 )
    );

    //===================================
    // Local signals
    //===================================
    logic rst;

    // Interfaces
    std_reset_intf #(.ACTIVE_LOW(1)) reset_if      (.clk(clk));
    std_reset_intf #(.ACTIVE_LOW(1)) mgmt_reset_if (.clk(axil_if.aclk));

    timestamp_if #() timestamp_if (.clk(clk), .srst(rst));

    // Generate datapath clock
    initial clk = 1'b0;
    always #1455ps clk = ~clk; // 343.75 MHz

    // Generate AXI management clock
    initial axil_if.aclk = 1'b0;
    always  #4ns axil_if.aclk = ~axil_if.aclk; // 125 MHz


    // Assign reset interfaces
    assign rstn = reset_if.reset;
    initial reset_if.ready = 1'b0;
    always @(posedge clk) reset_if.ready <= rstn;

    assign axil_if.aresetn = mgmt_reset_if.reset;
    initial mgmt_reset_if.ready = 1'b0;
    always @(posedge axil_if.aclk) mgmt_reset_if.ready <= axil_if.aresetn;

    assign rst = ~rstn;

    // App AXI-L interface shares common AXI-L clock/reset
    assign app_axil_if.aclk    = axil_if.aclk;
    assign app_axil_if.aresetn = axil_if.aresetn;

    // Timestamp
    assign timestamp = timestamp_if.timestamp;

    // Assign AXI-S input clocks/resets
    generate
        for (genvar i = 0; i < NUM_PORTS; i += 1) begin
            for (genvar j = 0; j < HOST_NUM_IFS; j += 1) begin
                assign axis_h2c_if[j][i].aclk = clk;
                assign axis_h2c_if[j][i].aresetn = rstn;
                assign axis_c2h_if[j][i].aclk = clk;
                assign axis_c2h_if[j][i].aresetn = rstn;
            end
            assign axis_in_if[i].aclk = clk;
            assign axis_in_if[i].aresetn = rstn;
            assign axis_out_if[i].aclk = clk;
            assign axis_out_if[i].aresetn = rstn;
        end
    endgenerate

    //===================================
    // Build
    //===================================
    function void build();
        if (env == null) begin
            // Instantiate environment
            env = new("tb_env",0); // Configure for little-endian

            // Connect
            env.reset_vif            = reset_if;
            env.mgmt_reset_vif       = mgmt_reset_if;
            env.timestamp_vif        = timestamp_if;
            env.app_axil_vif         = app_axil_if;
            env.axil_vif             = axil_if;
            env.axis_in_vif[0]       = axis_in_if[0];
            env.axis_in_vif[1]       = axis_in_if[1];
            env.axis_h2c_vif[PF][0]  = axis_h2c_if[PF][0];
            env.axis_h2c_vif[VF0][0] = axis_h2c_if[VF0][0];
            env.axis_h2c_vif[VF1][0] = axis_h2c_if[VF1][0];
            env.axis_h2c_vif[PF][1]  = axis_h2c_if[PF][1];
            env.axis_h2c_vif[VF0][1] = axis_h2c_if[VF0][1];
            env.axis_h2c_vif[VF1][1] = axis_h2c_if[VF1][1];
            env.axis_out_vif[0]      = axis_out_if[0];
            env.axis_out_vif[1]      = axis_out_if[1];
            env.axis_c2h_vif[PF][0]  = axis_c2h_if[PF][0];
            env.axis_c2h_vif[VF0][0] = axis_c2h_if[VF0][0];
            env.axis_c2h_vif[VF1][0] = axis_c2h_if[VF1][0];
            env.axis_c2h_vif[PF][1]  = axis_c2h_if[PF][1];
            env.axis_c2h_vif[VF0][1] = axis_c2h_if[VF0][1];
            env.axis_c2h_vif[VF1][1] = axis_c2h_if[VF1][1];

            env.connect();
        end
    endfunction

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
