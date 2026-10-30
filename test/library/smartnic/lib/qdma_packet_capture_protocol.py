__all__ = (
    'QdmaPacketCaptureProtocol',
)

from smartnic.lib.packet_capture_protocol import PacketCaptureProtocol
from smartnic.lib.qdma_meta import QDMA_H2C_META_WID, QdmaH2cMeta

class QdmaPacketCaptureProtocol(PacketCaptureProtocol):
    """Packet capture on the QDMA H2C stream.

    The capture sits ahead of the H2C CRC check, so the metadata of each
    captured packet carries the qid and tcrc exactly as the DMA engine
    supplied them.  capture() and wait_on_capture() return (data, meta) as
    the base class does, with meta decoded to a QdmaH2cMeta.
    """

    def __init__(self, proxy, name='QDMA Capture', debug=0, **kargs):
        super().__init__(proxy, name, debug=debug, **kargs)
        self.debug = debug
        meta_width = int(self.proxy.control.info.meta_width)
        if meta_width != QDMA_H2C_META_WID:
            raise ValueError(f'[{self.name}] meta width {meta_width}b does not match '
                             f'the QDMA H2C meta ({QDMA_H2C_META_WID}b)')

    def _get_capture(self, size):
        (data, meta) = super()._get_capture(size)
        meta = QdmaH2cMeta.unpack(meta)
        if self.debug:
            print(f'#     {meta}, CRC {"OK" if meta.crc_ok(data) else "MISMATCH"}')
        return (data, meta)
