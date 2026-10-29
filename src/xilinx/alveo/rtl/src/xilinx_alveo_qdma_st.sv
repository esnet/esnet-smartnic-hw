// =========================================================================
// xilinx_alveo_qdma_st
//
// Platform-common DMA streaming datapath for Alveo cards.
//
// Sits between a platform-specific QDMA adapter (which presents the DMA
// streams as packet_intf in the QDMA clock domain) and the shell, to which
// it presents shell-typed axi4s_intf in the core clock domain.  Owns:
//
//   - the QDMA-clock <-> core-clock crossing, via a store-and-forward
//     packet_fifo per direction
//   - H2C CRC check (packet_crc_rx) on the QDMA-clock input, before the
//     H2C FIFO; mismatches mark err so DROP_ERRORED discards the packet
//   - C2H CRC generation (packet_crc_tx) on the core-clock side, before
//     the C2H FIFO; the result is packed into the descriptor meta field
//   - a register-controlled loopback that reflects H2C back as C2H
//   - packet debug: a packet_capture tapping the H2C stream from the DMA
//     engine and a packet_playback injecting into the C2H stream toward it,
//     each isolated from the datapath until its register enable is set
//   - the register space: loopback control/status, packet counters on both
//     sides of each FIFO, and the capture/playback blocks
//   - the packet_intf <-> axi4s_intf conversion and the metadata remap
//     between QDMA and shell types
//
// Nothing here is specific to the QDMA IP.  The flat signal mapping, the
// completion write-back and the ECC all stay in the platform adapter
// (xilinx_qdma_st_adapter); this module only sees packet_intf.
//
// meta layouts at the DMA boundary (pkt_*_dma) are defined in
// xilinx_qdma_pkg: pkt_h2c_meta_t {tcrc, qid} and
// pkt_c2h_meta_t {size, tcrc, qid}.  size is packed here at the C2H FIFO
// output, where the store-and-forward length is first available, which
// eliminates the separate pkt_c2h_dma_size port.
// =========================================================================
module xilinx_alveo_qdma_st
    import xilinx_qdma_pkg::*;
#(
    parameter int QID_WID = 11,      // 11 for USPlus discrete QDMA, 12 for CPM5
    parameter int MAX_PKT_LEN = 9100 // Max packet length (bytes) for FIFO sizing
) (
    // QDMA clock and reset — the domain of the pkt_*_dma interfaces
    input  wire        aclk,
    input  wire        aresetn,

    // Core clock and synchronous reset — the domain of the pkt_*_core
    // interfaces and of the loopback switch
    input  wire        core_clk,
    input  wire        core_srst,

    // -----------------------------------------------------------------------
    // Management AXI4-Lite — loopback control and packet counters.
    // Its own clock domain; crossings are made internally.
    // -----------------------------------------------------------------------
    axi4l_intf.peripheral axil_if,

    // -----------------------------------------------------------------------
    // DMA-side packet interfaces (QDMA clock domain), toward the adapter.
    // meta layouts: pkt_h2c_meta_t / pkt_c2h_meta_t (xilinx_qdma_pkg).
    // -----------------------------------------------------------------------
    packet_intf.rx pkt_h2c_dma,  // H2C: from the adapter; META_WID = PKT_H2C_META_WID
    packet_intf.tx pkt_c2h_dma,  // C2H: to the adapter;   META_WID = PKT_C2H_META_WID

    // -----------------------------------------------------------------------
    // Core-side AXI4-S interfaces (core clock domain), toward the shell.
    // Shell-typed: tid carries the queue ID, tdest/tuser are shell_pkg types.
    // Widths are taken from the interfaces themselves.
    // -----------------------------------------------------------------------
    axi4s_intf.tx axis_h2c,  // H2C: drives toward core
    axi4s_intf.rx axis_c2h   // C2H: receives from core
);

    // =========================================================================
    // Packet FIFO sizing
    //
    // Both FIFOs are store-and-forward, so each must hold strictly more than
    // one maximum-length packet (packet_fifo_core checks DEPTH > MAX_PKT_WORDS).
    // 256 words of 64 bytes covers packets up to just under 16 kB, which
    // includes the 9100-byte jumbo default; beyond that, grow to the next power
    // of two that clears the check.
    // =========================================================================
    localparam int MAX_PKT_WORDS  = (MAX_PKT_LEN + AXIS_DATA_BYTE_WID - 1) / AXIS_DATA_BYTE_WID;
    localparam int MIN_FIFO_DEPTH = 2 ** $clog2(MAX_PKT_WORDS + 1);
    localparam int H2C_FIFO_DEPTH = MIN_FIFO_DEPTH > 256 ? MIN_FIFO_DEPTH : 256;
    localparam int C2H_FIFO_DEPTH = H2C_FIFO_DEPTH;

    // =========================================================================
    // Register space
    //
    // axil_if is split by qdma_decoder into the config/status block and four
    // packet counter blocks, one per side of each direction's FIFO.  Everything
    // here runs on the management clock; each packet_counters instance makes
    // its own crossing to the domain of the events it counts.
    // =========================================================================
    axi4l_intf axil_config  ();
    axi4l_intf axil_h2c_in  ();
    axi4l_intf axil_h2c_out ();
    axi4l_intf axil_c2h_in  ();
    axi4l_intf axil_c2h_out ();
    axi4l_intf axil_capture ();
    axi4l_intf axil_playback ();

    qdma_decoder i_qdma_decoder (
        .axil_if         ( axil_if      ),
        .config_axil_if  ( axil_config  ),
        .h2c_in_axil_if  ( axil_h2c_in  ),
        .h2c_out_axil_if ( axil_h2c_out ),
        .c2h_in_axil_if  ( axil_c2h_in  ),
        .c2h_out_axil_if ( axil_c2h_out ),
        .capture_axil_if  ( axil_capture  ),
        .playback_axil_if ( axil_playback )
    );

    // =========================================================================
    // Test and debug registers
    //
    // The loopback enable and its status cross to and from the core domain
    // through level synchronizers.  The enable changes rarely and
    // packet_loopback applies it only at a packet boundary, so the crossing
    // needs no handshake.
    // =========================================================================
    qdma_reg_intf reg_if ();

    qdma_reg_blk i_qdma_reg_blk (
        .axil_if    ( axil_config ),
        .reg_blk_if ( reg_if      )
    );

    // Reserved registers pad the block out to a full 16-byte window; they hold
    // their init value and take no hardware update.
    assign reg_if.reserved_0_nxt_v = 1'b0;
    assign reg_if.reserved_0_nxt   = '0;
    assign reg_if.reserved_1_nxt_v = 1'b0;
    assign reg_if.reserved_1_nxt   = '0;

    logic core_loopback_en;
    logic core_loopback_en_mon;
    logic core_loopback_switching;

    sync_level #(.RST_VALUE(1'b0)) i_sync_level__loopback_en (
        .clk_in  ( axil_if.aclk                   ),
        .rst_in  ( 1'b0                           ),
        .rdy_in  (                                ),
        .lvl_in  ( reg_if.loopback_config.enable  ),
        .clk_out ( core_clk                       ),
        .rst_out ( 1'b0                           ),
        .lvl_out ( core_loopback_en               )
    );

    sync_level #(.RST_VALUE(1'b0)) i_sync_level__loopback_enabled (
        .clk_in  ( core_clk                       ),
        .rst_in  ( 1'b0                           ),
        .rdy_in  (                                ),
        .lvl_in  ( core_loopback_en_mon           ),
        .clk_out ( axil_if.aclk                   ),
        .rst_out ( 1'b0                           ),
        .lvl_out ( reg_if.loopback_status_nxt.enabled )
    );

    sync_level #(.RST_VALUE(1'b0)) i_sync_level__loopback_switching (
        .clk_in  ( core_clk                       ),
        .rst_in  ( 1'b0                           ),
        .rdy_in  (                                ),
        .lvl_in  ( core_loopback_switching        ),
        .clk_out ( axil_if.aclk                   ),
        .rst_out ( 1'b0                           ),
        .lvl_out ( reg_if.loopback_status_nxt.switching )
    );

    assign reg_if.loopback_status_nxt_v = 1'b1;

    // =========================================================================
    // H2C stream — CRC check then packet_fifo (ASYNC CDC + S&F) to core clock.
    //
    // packet_crc_rx sits before the FIFO in the QDMA clock domain.  It reads
    // the tcrc field from pkt_h2c_dma.meta (pkt_h2c_meta_t) and compares it
    // against the CRC accumulated over the packet data.  On mismatch it asserts
    // err on the output EOP beat; DROP_ERRORED then discards the packet and
    // counts it without passing it to the core.
    //
    // The checked interface carries only QID in meta, dropping the tcrc field
    // that the downstream FIFO and core don't need.
    // =========================================================================
    // H2C stream steered by the capture enable: to the checker (datapath), or
    // to the capture buffer (debug).  Both are on the DMA-side meta layout.
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( PKT_H2C_META_WID   )
    ) pkt_h2c_chk (.clk(aclk));

    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( PKT_H2C_META_WID   )
    ) pkt_h2c_cap (.clk(aclk));

    logic h2c_capture_en;

    packet_intf_1to2_demux i_packet_intf_1to2_demux__h2c_capture (
        .srst    ( ~aresetn       ),
        .from_tx ( pkt_h2c_dma    ),
        .to_rx_0 ( pkt_h2c_chk    ),
        .to_rx_1 ( pkt_h2c_cap    ),
        .sel     ( h2c_capture_en )
    );

    // Taps the H2C stream ahead of the CRC check, so the meta carries the
    // tcrc supplied by the DMA engine.
    packet_capture i_packet_capture__h2c (
        .clk       ( aclk            ),
        .srst      ( ~aresetn        ),
        .en        ( h2c_capture_en  ),
        .axil_if   ( axil_capture    ),
        .packet_if ( pkt_h2c_cap     )
    );

    pkt_h2c_meta_t h2c_dma_meta;
    assign h2c_dma_meta = pkt_h2c_chk.meta;

    // Checked H2C interface (QDMA clock domain), QID-only meta → H2C FIFO.
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( QID_WID            )
    ) pkt_h2c_checked (.clk(aclk));

    // packet_crc_rx requires matching META_WID on from_tx and to_rx.
    // Use an intermediate interface at PKT_H2C_META_WID, then narrow.
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( PKT_H2C_META_WID   )
    ) pkt_h2c_crc_out (.clk(aclk));

    packet_crc_rx i_packet_crc_rx__h2c (
        .srst    ( ~aresetn          ),
        .from_tx ( pkt_h2c_chk      ),
        .to_rx   ( pkt_h2c_crc_out  ),
        .crc_in  ( h2c_dma_meta.tcrc )
    );

    // Narrow: strip tcrc from meta — FIFO and core only need QID.
    assign pkt_h2c_checked.vld  = pkt_h2c_crc_out.vld;
    assign pkt_h2c_checked.data = pkt_h2c_crc_out.data;
    assign pkt_h2c_checked.eop  = pkt_h2c_crc_out.eop;
    assign pkt_h2c_checked.mty  = pkt_h2c_crc_out.mty;
    assign pkt_h2c_checked.err  = pkt_h2c_crc_out.err;
    assign pkt_h2c_checked.meta = QID_WID'(pkt_h2c_crc_out.meta);
    assign pkt_h2c_crc_out.rdy  = pkt_h2c_checked.rdy;

    // FIFO output interface (core clock domain), routed via packet_loopback.
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( QID_WID            )
    ) pkt_h2c_fifo (.clk(core_clk));

    // Packet events, one per FIFO side.  The input-side event reports the full
    // status range and so accounts for packets the FIFO drops; the output-side
    // event reports delivery.
    packet_event_intf evt_h2c_in  (.clk(aclk));
    packet_event_intf evt_h2c_out (.clk(core_clk));

    packet_fifo #(
        .ASYNC           ( 1              ),
        .DEPTH           ( H2C_FIFO_DEPTH ),
        .MAX_PKT_SIZE    ( MAX_PKT_LEN    ),
        .MAX_DESCRIPTORS ( 32             ),
        .DROP_ERRORED    ( 1              )
    ) i_packet_fifo_h2c (
        .srst_in       ( ~aresetn       ),
        .packet_in_if  ( pkt_h2c_checked ),
        .event_in_if   ( evt_h2c_in     ),
        .srst_out      ( core_srst      ),
        .packet_out_if ( pkt_h2c_fifo   ),
        .event_out_if  ( evt_h2c_out    ),
        .pkt_size      (                )
    );

    // =========================================================================
    // C2H stream — CRC generation then packet_fifo (ASYNC CDC + S&F) to QDMA
    // clock.  After the FIFO the packet size is available; all three fields
    // (size, tcrc, qid) are packed into pkt_c2h_dma.meta as pkt_c2h_meta_t.
    // =========================================================================

    // Internal C2H FIFO interface: carries {tcrc, qid} while crossing domains.
    // size is not yet known inside the FIFO; it is added at the output.
    localparam int C2H_FIFO_META_WID = 32 + QID_WID;  // {tcrc[31:0], qid}

    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( C2H_FIFO_META_WID  )
    ) pkt_c2h_fifo (.clk(core_clk));

    // Raw FIFO output (QDMA clock domain), before size is packed in.
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( C2H_FIFO_META_WID  )
    ) pkt_c2h_fifo_out (.clk(aclk));

    packet_event_intf evt_c2h_in  (.clk(core_clk));
    packet_event_intf evt_c2h_out (.clk(aclk));

    packet_pkg::size_t pkt_c2h_size;

    packet_fifo #(
        .ASYNC           ( 1              ),
        .DEPTH           ( C2H_FIFO_DEPTH ),
        .MAX_PKT_SIZE    ( MAX_PKT_LEN    ),
        .MAX_DESCRIPTORS ( 32             ),
        .DROP_ERRORED    ( 0              )
    ) i_packet_fifo_c2h (
        .srst_in       ( core_srst         ),
        .packet_in_if  ( pkt_c2h_fifo      ),
        .event_in_if   ( evt_c2h_in        ),
        .srst_out      ( ~aresetn          ),
        .packet_out_if ( pkt_c2h_fifo_out  ),
        .event_out_if  ( evt_c2h_out       ),
        .pkt_size      ( pkt_c2h_size      )
    );

    // Widen to full pkt_c2h_meta_t, inserting size at the top.
    pkt_c2h_meta_t c2h_dma_meta;
    assign c2h_dma_meta.size = pkt_c2h_size;
    assign c2h_dma_meta.tcrc = pkt_c2h_fifo_out.meta[C2H_FIFO_META_WID-1 -: 32];
    assign c2h_dma_meta.qid  = QID_WID'(pkt_c2h_fifo_out.meta);

    // Datapath C2H stream toward the DMA engine, before the playback mux.
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( PKT_C2H_META_WID   )
    ) pkt_c2h_chk (.clk(aclk));

    assign pkt_c2h_chk.vld  = pkt_c2h_fifo_out.vld;
    assign pkt_c2h_chk.data = pkt_c2h_fifo_out.data;
    assign pkt_c2h_chk.eop  = pkt_c2h_fifo_out.eop;
    assign pkt_c2h_chk.mty  = pkt_c2h_fifo_out.mty;
    assign pkt_c2h_chk.err  = pkt_c2h_fifo_out.err;
    assign pkt_c2h_chk.meta = PKT_C2H_META_WID'(c2h_dma_meta);
    assign pkt_c2h_fifo_out.rdy = pkt_c2h_chk.rdy;

    // Playback stream, in the DMA-side meta layout.  The meta (including size
    // and tcrc) is supplied by the playback registers.
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( PKT_C2H_META_WID   )
    ) pkt_c2h_play (.clk(aclk));

    logic c2h_playback_en;

    packet_playback i_packet_playback__c2h (
        .clk       ( aclk             ),
        .srst      ( ~aresetn         ),
        .en        ( c2h_playback_en  ),
        .axil_if   ( axil_playback    ),
        .packet_if ( pkt_c2h_play     )
    );

    // The datapath is backpressured, not drained, while playback is selected.
    packet_intf_2to1_mux i_packet_intf_2to1_mux__c2h_playback (
        .srst      ( ~aresetn         ),
        .from_tx_0 ( pkt_c2h_chk      ),
        .from_tx_1 ( pkt_c2h_play     ),
        .to_rx     ( pkt_c2h_dma      ),
        .sel       ( c2h_playback_en  )
    );

    // =========================================================================
    // Loopback switch (core clock domain)
    //
    // tx/rx are named from the host's point of view, which matches the DMA
    // directions: H2C is the host transmitting, C2H the host receiving.  With
    // loopback enabled, H2C is reflected straight into the C2H path, the core
    // sees no H2C traffic, and C2H traffic from the core is discarded.
    // =========================================================================
    // Core-side packet interfaces, between the loopback switch and the
    // axi4s conversion below.
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( QID_WID            )
    ) pkt_h2c_core (.clk(core_clk));

    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( QID_WID            )
    ) pkt_c2h_core (.clk(core_clk));

    // Loopback output (pre-CRC): loopback switch drives this; CRC generator reads it.
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( QID_WID            )
    ) pkt_c2h_lb_out (.clk(core_clk));

    // CRC generator output: same META_WID as input (CRC is out-of-band).
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( QID_WID            )
    ) pkt_c2h_crc_out (.clk(core_clk));

    packet_loopback i_packet_loopback (
        .srst          ( core_srst               ),
        .packet_tx_in  ( pkt_h2c_fifo            ),
        .packet_tx_out ( pkt_h2c_core            ),
        .packet_rx_in  ( pkt_c2h_core            ),
        .packet_rx_out ( pkt_c2h_lb_out          ),
        .en            ( core_loopback_en        ),
        .en_mon        ( core_loopback_en_mon    ),
        .switching     ( core_loopback_switching )
    );

    // CRC generator: computes CRC32 over C2H packet data before the FIFO.
    // crc_out is registered on the input EOP beat and valid at the output EOP,
    // coinciding exactly with the descriptor write in the FIFO.
    logic [31:0] c2h_crc_out;

    packet_crc_tx i_packet_crc_tx__c2h (
        .srst    ( core_srst       ),
        .from_tx ( pkt_c2h_lb_out  ),
        .to_rx   ( pkt_c2h_crc_out ),
        .crc_out ( c2h_crc_out     )
    );

    // Pack {tcrc, qid} into the FIFO input meta (size added at FIFO output).
    assign pkt_c2h_fifo.vld  = pkt_c2h_crc_out.vld;
    assign pkt_c2h_fifo.data = pkt_c2h_crc_out.data;
    assign pkt_c2h_fifo.eop  = pkt_c2h_crc_out.eop;
    assign pkt_c2h_fifo.mty  = pkt_c2h_crc_out.mty;
    assign pkt_c2h_fifo.err  = pkt_c2h_crc_out.err;
    assign pkt_c2h_fifo.meta = {c2h_crc_out, pkt_c2h_crc_out.meta};
    assign pkt_c2h_crc_out.rdy = pkt_c2h_fifo.rdy;

    // =========================================================================
    // packet_intf <-> axi4s_intf conversion (core clock domain)
    //
    // H2C converts straight to axi4s_intf, taking the QID from the packet
    // metadata into tid and supplying the shell_pkg tdest/tuser in the same
    // step; neither has an H2C source, so both are tied off.
    //
    // C2H goes the other way: the shell-typed metadata is remapped to QDMA
    // types and then converted to packet_intf, where the QID rides in the
    // metadata field for the CRC generator to pick up.
    // =========================================================================

    // H2C: packet_intf -> axi4s_intf
    logic [axis_h2c.TID_WID-1:0]   h2c_shell_tid;
    shell_pkg::dma_st_axis_tdest_t h2c_shell_tdest;
    shell_pkg::dma_st_axis_tuser_t h2c_shell_tuser;

    assign h2c_shell_tid               = pkt_h2c_core.meta;
    assign h2c_shell_tdest.unused      = 1'b0;
    assign h2c_shell_tuser.rss_enable  = 1'b0;
    assign h2c_shell_tuser.rss_entropy = '0;

    axi4s_from_packet_adapter #(
        .TID_WID   ( axis_h2c.TID_WID   ),
        .TDEST_WID ( axis_h2c.TDEST_WID ),
        .TUSER_WID ( axis_h2c.TUSER_WID )
    ) i_axi4s_from_packet_adapter__h2c (
        .srst      ( core_srst       ),
        .packet_if ( pkt_h2c_core    ),
        .axis_if   ( axis_h2c        ),
        .tid       ( h2c_shell_tid   ),
        .tdest     ( h2c_shell_tdest ),
        .tuser     ( h2c_shell_tuser )
    );

    // C2H metadata adaptation: shell types -> QDMA types
    axi4s_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .TID_WID       ( AXIS_TID_WID       ),
        .TDEST_WID     ( AXIS_TDEST_WID     ),
        .TUSER_WID     ( AXIS_TUSER_WID     )
    ) axis_c2h_qdma (.aclk(core_clk));

    logic [axis_c2h.TID_WID-1:0]  c2h_shell_tid;
    xilinx_qdma_pkg::axis_tid_t   c2h_qdma_tid;
    xilinx_qdma_pkg::axis_tdest_t c2h_qdma_tdest;
    xilinx_qdma_pkg::axis_tuser_t c2h_qdma_tuser;

    assign c2h_shell_tid          = axis_c2h.tid;
    assign c2h_qdma_tid.qid       = c2h_shell_tid;
    assign c2h_qdma_tdest.unused  = 1'b0;
    assign c2h_qdma_tuser.err     = 1'b0;

    axi4s_intf_set_meta #(
        .TID_WID   ( AXIS_TID_WID   ),
        .TDEST_WID ( AXIS_TDEST_WID ),
        .TUSER_WID ( AXIS_TUSER_WID )
    ) i_axi4s_intf_set_meta__c2h (
        .from_tx ( axis_c2h       ),
        .to_rx   ( axis_c2h_qdma  ),
        .tid     ( c2h_qdma_tid   ),
        .tdest   ( c2h_qdma_tdest ),
        .tuser   ( c2h_qdma_tuser )
    );

    // C2H: axi4s_intf -> packet_intf
    axi4s_to_packet_adapter #(
        .META_WID ( QID_WID )
    ) i_axi4s_to_packet_adapter__c2h (
        .srst      ( core_srst        ),
        .axis_if   ( axis_c2h_qdma    ),
        .packet_if ( pkt_c2h_core     ),
        .meta      ( c2h_qdma_tid.qid ),
        .err       ( 1'b0             )
    );

    // =========================================================================
    // Packet counters
    //
    // One per FIFO side, each clocked in the domain of the events it counts,
    // so the two directions are mirror images: H2C arrives on aclk and leaves
    // on core_clk, C2H the other way around.  packet_counters crosses its own
    // AXI-L from the management clock, so no CDC is needed here.
    //
    // The _in counters see every packet offered to the FIFO and report why one
    // was dropped; the _out counters only ever report STATUS_OK, so they count
    // what the FIFO released.
    //
    // Both taps are on the FIFO itself, which is upstream of the loopback
    // switch.  So with loopback enabled h2c_out still counts, even though the
    // core receives nothing, and c2h_in counts the reflected H2C traffic
    // rather than anything the core sent.
    // =========================================================================
    packet_counters #(.MAX_PKT_SIZE (MAX_PKT_LEN)) i_packet_counters__h2c_in (
        .clk      ( aclk         ),
        .axil_if  ( axil_h2c_in  ),
        .event_if ( evt_h2c_in   )
    );

    packet_counters #(.MAX_PKT_SIZE (MAX_PKT_LEN)) i_packet_counters__h2c_out (
        .clk      ( core_clk     ),
        .axil_if  ( axil_h2c_out ),
        .event_if ( evt_h2c_out  )
    );

    packet_counters #(.MAX_PKT_SIZE (MAX_PKT_LEN)) i_packet_counters__c2h_in (
        .clk      ( core_clk     ),
        .axil_if  ( axil_c2h_in  ),
        .event_if ( evt_c2h_in   )
    );

    packet_counters #(.MAX_PKT_SIZE (MAX_PKT_LEN)) i_packet_counters__c2h_out (
        .clk      ( aclk         ),
        .axil_if  ( axil_c2h_out ),
        .event_if ( evt_c2h_out  )
    );

endmodule : xilinx_alveo_qdma_st
