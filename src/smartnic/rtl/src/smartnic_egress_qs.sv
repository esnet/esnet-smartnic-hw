// SmartNIC Egress Queues
// - implements egress queueing in HBM
// - 2GB total, arranged as 1M 2kB buffers
//
// Destination is carried in AXI-S (in) metadata:
// - TDEST indicates output port (smartnic_pkg::port_t)
// - TUSER indicates output queue (smartnic_pkg::egr_q_t)
//
// No metadata is carried through to output side (ignored by physical ports)
//
module smartnic_egress_qs
    import smartnic_pkg::*;
(
    input  logic          clk,
    input  logic          srst,

    axi4s_intf.rx         axis_in  [PHY_NUM_PORTS],
    axi4s_intf.tx         axis_out [PHY_NUM_PORTS],

    axi4l_intf.peripheral axil_if,

    output logic          init_done
);
    // ----------------------------------------------------------------
    //  Parameters
    // ----------------------------------------------------------------
    localparam xilinx_hbm_pkg::stack_t   HBM_STACK = xilinx_hbm_pkg::STACK_LEFT;
    localparam xilinx_hbm_pkg::density_t HBM_DENSITY = xilinx_hbm_pkg::DENSITY_4G;

    localparam int  HBM_NUM_AXI_CHANNELS = xilinx_hbm_pkg::PSEUDO_CHANNELS_PER_STACK;
    localparam int  HBM_AXI_DATA_BYTE_WID = xilinx_hbm_pkg::AXI_DATA_BYTE_WID;
    localparam int  HBM_AXI_DATA_WID = xilinx_hbm_pkg::AXI_DATA_WID;
    localparam int  HBM_AXI_ADDR_WID = xilinx_hbm_pkg::get_addr_wid(HBM_DENSITY);
    localparam int  HBM_AXI_ID_WID = xilinx_hbm_pkg::AXI_ID_WID;

    localparam int  HBM_NUM_AXI_CHANNELS_PER_PORT = 2; // AXI-S interfaces are 512B wide; AXI-3 interfaces are 256B wide.

    localparam longint QMEM_CAPACITY = HBM_NUM_AXI_CHANNELS_PER_PORT*xilinx_hbm_pkg::get_ps_capacity(HBM_DENSITY);
    localparam int     QMEM_ADDR_WID = $clog2(QMEM_CAPACITY);
    localparam int     QMEM_ROW_ADDR_WID = QMEM_ADDR_WID - $clog2(PHY_DATA_BYTE_WID); // Memory interface uses row addressing

    localparam int  BUFFER_SIZE = 2048;  // In bytes
    localparam int  NUM_BUFFERS = int'(QMEM_CAPACITY / BUFFER_SIZE);
    localparam int  BUFFER_PTR_WID = $clog2(NUM_BUFFERS);

    localparam int  MAX_PKT_SIZE = 9200;

    // ----------------------------------------------------------------
    //  Parameter Checking
    // ----------------------------------------------------------------
    generate
        for (genvar g_port = 0; g_port < PHY_NUM_PORTS; g_port++) begin : g__params_port
            initial begin
                std_pkg::param_check(axis_in[g_port].DATA_BYTE_WID, PHY_DATA_BYTE_WID, $sformatf("axis_in[%0d].DATA_BYTE_WID", g_port));
                std_pkg::param_check(axis_out[g_port].DATA_BYTE_WID, PHY_DATA_BYTE_WID, $sformatf("axis_out[%0d].DATA_BYTE_WID", g_port));
                std_pkg::param_check(axis_in[g_port].TDEST_WID, PORT_WID, $sformatf("axis_in[%0d].TDEST_WID", g_port));
                std_pkg::param_check(axis_in[g_port].TUSER_WID, EGR_Q_WID, $sformatf("axis_in[%0d].TUSER_WID", g_port));
            end
        end : g__params_port
    endgenerate

    // ----------------------------------------------------------------
    //  Typedefs
    // ----------------------------------------------------------------
    typedef struct packed {
        logic [$bits(port_t)-1:0]  egr_port;
        logic [$bits(egr_q_t)-1:0] egr_q;
    } META_T;
    localparam int META_WID = $bits(META_T);

    // ----------------------------------------------------------------
    //  Signals
    // ----------------------------------------------------------------
    logic local_srst;
    logic clk_100mhz;
    logic hbm_ref_clk;
    logic hbm_init_done;

    // ----------------------------------------------------------------
    //  Interfaces
    // ----------------------------------------------------------------
    axi3_intf #(.DATA_BYTE_WID(HBM_AXI_DATA_BYTE_WID), .ADDR_WID(HBM_AXI_ADDR_WID), .ID_WID(HBM_AXI_ID_WID)) axi_if [HBM_NUM_AXI_CHANNELS] (.aclk (clk));

    packet_intf #(.DATA_BYTE_WID(PHY_DATA_BYTE_WID), .META_WID(META_WID)) packet_in_if  [PHY_NUM_PORTS] (.clk);
    packet_intf #(.DATA_BYTE_WID(PHY_DATA_BYTE_WID), .META_WID(META_WID)) packet_out_if [PHY_NUM_PORTS] (.clk);

    packet_descriptor_intf #(.ADDR_WID(BUFFER_PTR_WID), .META_WID(META_WID), .MAX_PKT_SIZE(MAX_PKT_SIZE)) desc_in_if  [PHY_NUM_PORTS] (.clk);
    packet_descriptor_intf #(.ADDR_WID(BUFFER_PTR_WID), .META_WID(META_WID), .MAX_PKT_SIZE(MAX_PKT_SIZE)) desc_out_if [PHY_NUM_PORTS] (.clk);

    mem_wr_intf #(.ADDR_WID(QMEM_ROW_ADDR_WID), .DATA_WID(PHY_DATA_BYTE_WID*8)) mem_wr_if [PHY_NUM_PORTS] (.clk);
    mem_rd_intf #(.ADDR_WID(QMEM_ROW_ADDR_WID), .DATA_WID(PHY_DATA_BYTE_WID*8)) mem_rd_if [PHY_NUM_PORTS] (.clk);

    mem_wr_intf #(.ADDR_WID(BUFFER_PTR_WID), .DATA_WID(HBM_AXI_DATA_WID)) desc_mem_wr_if (.clk);
    mem_rd_intf #(.ADDR_WID(BUFFER_PTR_WID), .DATA_WID(HBM_AXI_DATA_WID)) desc_mem_rd_if (.clk);

    // ----------------------------------------------------------------
    //  Register map block and decoder instantiations
    // ----------------------------------------------------------------
    axi4l_intf axil_to_hbm ();
    axi4l_intf axil_to_regs ();
    axi4l_intf axil_to_alloc ();
    axi4l_intf axil_to_regs__clk ();

    smartnic_qs_reg_intf reg_if();

    smartnic_qs_decoder i_smartnic_qs_decoder (
        .axil_if         ( axil_if ),
        .control_axil_if ( axil_to_regs ),
        .alloc_axil_if   ( axil_to_alloc ),
        .hbm_axil_if     ( axil_to_hbm )
    );

    // Pass AXI-L interface from aclk (AXI-L clock) to clk domain
    axi4l_intf_cdc i_axil_intf_cdc (
        .axi4l_if_from_controller   ( axil_to_regs ),
        .clk_to_peripheral          ( clk ),
        .axi4l_if_to_peripheral     ( axil_to_regs__clk )
    );

    smartnic_qs_reg_blk i_smartnic_qs_reg_blk
    (
        .axil_if    ( axil_to_regs__clk ),
        .reg_blk_if ( reg_if )
    );

    // ----------------------------------------------------------------
    //  Status monitoring
    // ----------------------------------------------------------------
    assign reg_if.status_nxt_v = 1'b1;
    assign reg_if.status_nxt.reset = local_srst;
    assign reg_if.status_nxt.enabled = 1'b1;
    assign reg_if.status_nxt.init_done = init_done;

    // ----------------------------------------------------------------
    //  Reset (including soft reset)
    // ----------------------------------------------------------------
    initial local_srst = 1'b0;
    always @(posedge clk) begin
        if (srst || reg_if.control.reset) local_srst <= 1'b1;
        else                              local_srst <= 1'b0;
    end

    // ----------------------------------------------------------------
    //  HBM controller instantiation
    // ----------------------------------------------------------------
    smartnic_hbm_clk_wiz i_smartnic_hbm_clk_wiz (
        .clk_in1     ( axil_if.aclk ),
        .clk_100mhz  ( clk_100mhz ),
        .hbm_ref_clk ( hbm_ref_clk )
    );

    xilinx_hbm_stack #(
        .STACK   ( HBM_STACK ),
        .DENSITY ( HBM_DENSITY )
    ) i_xilinx_hbm_stack__left (
        .clk,
        .srst        ( local_srst ),
        .hbm_ref_clk ( hbm_ref_clk ),
        .clk_100mhz  ( clk_100mhz ),
        .axil_if     ( axil_to_hbm ),
        .axi_if      ( axi_if ),
        .init_done   ( hbm_init_done )
    );

    // ----------------------------------------------------------------
    //  Queuing Logic
    // ----------------------------------------------------------------
    packet_q_core            #(
        .NUM_INPUT_IFS        ( PHY_NUM_PORTS ),
        .NUM_OUTPUT_IFS       ( PHY_NUM_PORTS ),
        .MIN_PKT_SIZE         ( 40 ),
        .MAX_PKT_SIZE         ( MAX_PKT_SIZE ),
        .NUM_BUFFERS          ( NUM_BUFFERS ),
        .BUFFER_SIZE          ( BUFFER_SIZE ),
        .N_ALLOC              ( 4 ),
        .N_GATHER             ( 4 ),
        .MAX_RD_LATENCY       ( 48 ) // TODO: characterize HBM read latency
    ) i_packet_q_core         (
        .clk,
        .srst ( local_srst ),
        .init_done,
        .packet_in_if,
        .desc_mem_wr_if,
        .mem_wr_if,
        .desc_in_if,
        .desc_out_if,
        .packet_out_if,
        .desc_mem_rd_if,
        .mem_rd_if,
        .mem_init_done  ( hbm_init_done ),
        .axil_if ( axil_to_alloc )
    );

    // Per-port logic
    generate
        for (genvar g_port = 0; g_port < PHY_NUM_PORTS; g_port++) begin : g__port_adapter
            // (Local) interfaces
            axi4s_intf #(.DATA_BYTE_WID(PHY_DATA_BYTE_WID), .TDEST_WID(PORT_WID), .TUSER_WID(EGR_Q_WID)) __axis_to_qs (.aclk(clk));
            axi4s_intf #(.DATA_BYTE_WID(PHY_DATA_BYTE_WID), .TDEST_WID(PORT_WID), .TUSER_WID(EGR_Q_WID)) __axis_from_qs (.aclk(clk));
            axi4s_intf #(.DATA_BYTE_WID(PHY_DATA_BYTE_WID), .TDEST_WID(PORT_WID), .TUSER_WID(EGR_Q_WID)) __axis_out (.aclk(clk));

            mem_wr_intf #(.ADDR_WID(QMEM_ROW_ADDR_WID), .DATA_WID(HBM_AXI_DATA_WID)) __mem_wr_if [HBM_NUM_AXI_CHANNELS_PER_PORT] (.clk);
            mem_rd_intf #(.ADDR_WID(QMEM_ROW_ADDR_WID), .DATA_WID(HBM_AXI_DATA_WID)) __mem_rd_if [HBM_NUM_AXI_CHANNELS_PER_PORT] (.clk);

            // (Local) signals
            logic   bypass_en;
            META_T  meta_in;
            META_T  meta_out;

            // Bypass mux (allow queues to be bypassed under register control)
            assign bypass_en = (reg_if.control.enable == 1'b0);

            axi4s_intf_bypass_mux #(
                .PIPE_STAGES ( 1 )
            ) i_axi4s_intf_bypass_mux (
                .srst       ( local_srst ),
                .from_tx    ( axis_in[g_port] ),
                .to_block   ( __axis_to_qs ),
                .from_block ( __axis_from_qs ),
                .to_rx      ( __axis_out ),
                .bypass     ( bypass_en )
            );

            // Adapt from/to AXI-S
            assign meta_in.egr_port = axis_in[g_port].tdest;
            assign meta_in.egr_q = 0;
            axi4s_to_packet_adapter #(
                .META_WID ( META_WID )
            ) i_axi4s_to_packet_adapter (
                .srst      ( local_srst ),
                .axis_if   ( __axis_to_qs ),
                .packet_if ( packet_in_if[g_port] ),
                .err       ( 1'b0 ),
                .meta      ( meta_in )
            );

            assign meta_out = packet_out_if[g_port].meta;
            axi4s_from_packet_adapter #(
                .TDEST_WID ( PORT_WID ),
                .TUSER_WID ( EGR_Q_WID )
            ) i_axi4s_from_packet_adapter (
                .srst      ( local_srst ),
                .packet_if ( packet_out_if[g_port] ),
                .axis_if   ( __axis_from_qs ),
                .tdest     ( meta_out.egr_port ),
                .tuser     ( meta_out.egr_q )
            );

            // Discard unused metadata at output
            axi4s_intf_set_meta #(
                .TDEST_WID ( PORT_WID ),
                .TUSER_WID ( EGR_Q_WID ) // TEMP: pass to output for now
            ) i_axi4s_intf_set_meta__out (
                .from_tx ( __axis_out ),
                .to_rx   ( axis_out[g_port] ),
                .tdest   ( __axis_out.tdest ),
                .tuser   ( __axis_out.tuser )
            );

            // Adapt from 'wide' packet interface to 'narrow' memory interfaces
            mem_wr_aggregate #(
                .N ( HBM_NUM_AXI_CHANNELS_PER_PORT ),
                .ALIGNMENT_DEPTH ( 8 )
            ) i_mem_wr_aggregate (
                .from_controller ( mem_wr_if [g_port] ),
                .to_peripheral   ( __mem_wr_if )
            );
            mem_rd_aggregate #(
                .N ( HBM_NUM_AXI_CHANNELS_PER_PORT ),
                .ALIGNMENT_DEPTH ( 8 )
            ) i_mem_rd_aggregate (
                .from_controller ( mem_rd_if [g_port] ),
                .to_peripheral   ( __mem_rd_if )
            );

            // Adapt memory interfaces to/from AXI3
            for (genvar g_if = 0; g_if < HBM_NUM_AXI_CHANNELS_PER_PORT; g_if++) begin : g__mem_if
                axi3_from_mem_adapter #(
                    .SIZE ( axi3_pkg::SIZE_32BYTES ),
                    .WR_TIMEOUT ( 0 ),
                    .RD_TIMEOUT ( 0 ),
                    .BURST_SUPPORT ( 1 ),
                    .WR_ID ( g_port * 2 ),
                    .RD_ID ( g_port * 2 + 1)
                ) i_axi3_from_mem_adapter (
                    .clk,
                    .srst      ( local_srst ),
                    .init_done (),
                    .mem_wr_if ( __mem_wr_if [g_if] ),
                    .mem_rd_if ( __mem_rd_if [g_if] ),
                    .axi3_if   ( axi_if[g_port*HBM_NUM_AXI_CHANNELS_PER_PORT + g_if] )
                );
            end : g__mem_if

        end : g__port_adapter
    endgenerate

    // Connect descriptor wr/rd interface
    axi3_from_mem_adapter #(
        .SIZE ( axi3_pkg::SIZE_32BYTES ),
        .WR_TIMEOUT ( 0 ),
        .RD_TIMEOUT ( 0 ),
        .BASE_ADDR  ( QMEM_CAPACITY ),
        .BURST_SUPPORT ( 0 ),
        .WR_ID ( PHY_NUM_PORTS * 2 ),
        .RD_ID ( PHY_NUM_PORTS * 2 )
    ) i_axi3_from_mem_adapter (
        .clk,
        .srst      ( local_srst ),
        .init_done (),
        .mem_wr_if ( desc_mem_wr_if ),
        .mem_rd_if ( desc_mem_rd_if ),
        .axi3_if   ( axi_if[HBM_NUM_AXI_CHANNELS_PER_PORT*PHY_NUM_PORTS] )
    );

    // Tie off unused AXI-3 interfaces
    generate
        for (genvar g_if = HBM_NUM_AXI_CHANNELS_PER_PORT*PHY_NUM_PORTS+1; g_if < HBM_NUM_AXI_CHANNELS; g_if++) begin : g__axi_if_tieoff
            axi3_intf_controller_term i_axi3_intf_controller_term (.to_peripheral ( axi_if[g_if] ));
        end : g__axi_if_tieoff
    endgenerate

    // ----------------------------------------------------------------
    //  Scheduling Logic
    // ----------------------------------------------------------------
    generate
        for (genvar g_port = 0; g_port < PHY_NUM_PORTS; g_port++) begin : g__scheduler
            // TEMP: send packets out on same port on which they were received
            packet_descriptor_fifo #(.DEPTH(512)) i_packet_descriptor_fifo (
                .from_tx      ( desc_in_if[g_port] ),
                .from_tx_srst ( local_srst ),
                .to_rx        ( desc_out_if[g_port] ),
                .to_rx_srst   ( local_srst )
            );
        end : g__scheduler
    endgenerate

endmodule: smartnic_egress_qs
