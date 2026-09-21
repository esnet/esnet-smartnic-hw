"""Setup, teardown, and shared helpers for the sar_test example design Robot tests."""

__all__ = (
    'SAR_NUM_FRAME_BUFFERS',
    'SAR_MAX_FRAME_SIZE',
    'SAR_DEFAULT_SEG_LEN',
    'CHUNK_BYTES',
    'SAR_BUF_ID_WID',
    'SAR_OFFSET_WID',
    'make_reassembly_meta',
    'buf_chunk_addr',
    'testcase_setup',
    'testcase_teardown',
    'SarTestProtocols',
)

from dataclasses import dataclass

from smartnic.lib.packet_playback_protocol import PacketPlaybackProtocol
from smartnic.lib.packet_capture_protocol  import PacketCaptureProtocol
from smartnic.lib.packet_mem_protocol      import PacketMemProtocol
from smartnic.lib.sar_reassembly_protocol  import SarReassemblyProtocol
from smartnic.lib.sar_segmentation_protocol import SarSegmentationProtocol
from sar_test.lib.sar_seg_ctrl_protocol    import SarSegCtrlProtocol

# sar_test RTL constants (must match sar_test.sv localparam values)
SAR_NUM_FRAME_BUFFERS = 4
SAR_MAX_FRAME_SIZE    = 65536   # bytes per frame buffer
SAR_DEFAULT_SEG_LEN   = 512     # default _config.seg_len value
SAR_BUF_ID_WID        = 2       # clog2(SAR_NUM_FRAME_BUFFERS)
SAR_OFFSET_WID        = 16      # clog2(SAR_MAX_FRAME_SIZE)
CHUNK_BYTES           = 32      # HBM AXI data width = min mem_proxy burst


def make_reassembly_meta(buf_id, byte_offset, is_last):
    """Encode the 19-bit playback meta for sar_packet_reassembly.

    Format: {buf_id[1:0], offset[15:0], last[0]}
    """
    return (int(buf_id) << (SAR_OFFSET_WID + 1)) | (int(byte_offset) << 1) | int(is_last)


def buf_chunk_addr(buf_id):
    """Return the mem_proxy chunk address for the start of frame buffer buf_id."""
    return (int(buf_id) * SAR_MAX_FRAME_SIZE) // CHUNK_BYTES


@dataclass
class SarTestProtocols:
    playback:       PacketPlaybackProtocol
    reasm_mem:      PacketMemProtocol
    reassembly:     SarReassemblyProtocol
    segmentation:   SarSegmentationProtocol
    seg_mem:        PacketMemProtocol
    capture:        PacketCaptureProtocol
    seg_ctrl:       SarSegCtrlProtocol


def testcase_setup(dev):
    """Instantiate all protocol objects, reset and enable both SAR paths."""
    app = dev.bar2.smartnic_app_igr

    protocols = SarTestProtocols(
        playback    = PacketPlaybackProtocol(app.reassembly_playback,    'Reassembly Playback'),
        reasm_mem   = PacketMemProtocol(app.reassembly_mem_proxy,        'Reassembly Mem'),
        reassembly  = SarReassemblyProtocol(app.reassembly),
        segmentation= SarSegmentationProtocol(app.segmentation),
        seg_mem     = PacketMemProtocol(app.segmentation_mem_proxy,      'Segmentation Mem'),
        capture     = PacketCaptureProtocol(app.segmentation_capture,    'Segmentation Capture'),
        seg_ctrl    = SarSegCtrlProtocol(app.segmentation_ctrl),
    )

    protocols.reassembly.reset()
    protocols.reassembly.enable()
    protocols.reassembly.clear_counts()
    protocols.reassembly.set_timeout(enable=True, value_ms=1000)
    protocols.reassembly.wait_ready()

    protocols.segmentation.reset()
    protocols.segmentation.enable()
    protocols.segmentation.clear_counts()
    protocols.segmentation.set_segment_length(SAR_DEFAULT_SEG_LEN)
    protocols.segmentation.wait_ready()

    protocols.playback.enable()
    protocols.capture.enable()

    protocols.reasm_mem.wait_ready()
    protocols.seg_mem.wait_ready()

    return protocols


def testcase_teardown(dev):
    """Disable both SAR paths."""
    app = dev.bar2.smartnic_app_igr
    SarReassemblyProtocol(app.reassembly).disable()
    SarSegmentationProtocol(app.segmentation).disable()
