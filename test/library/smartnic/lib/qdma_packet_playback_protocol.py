__all__ = (
    'QdmaPacketPlaybackProtocol',
)

from smartnic.lib.packet_playback_protocol import PacketPlaybackProtocol
from smartnic.lib.qdma_meta import (QDMA_C2H_META_WID, QDMA_QID_WID, QDMA_SIZE_WID,
                                    QdmaC2hMeta, qdma_crc)

class QdmaPacketPlaybackProtocol(PacketPlaybackProtocol):
    """Packet playback into the QDMA C2H stream.

    The metadata the DMA engine needs with each packet (qid, tcrc and the
    packet size) is built from the arguments to send().  tcrc defaults to the
    qdma_crc of the payload; pass it explicitly to inject a bad CRC.
    """

    def __init__(self, proxy, name='QDMA Playback', debug=0, **kargs):
        super().__init__(proxy, name, debug=debug, **kargs)
        self.debug = debug
        meta_width = int(self.proxy.control.info.meta_width)
        if meta_width != QDMA_C2H_META_WID:
            raise ValueError(f'[{self.name}] meta width {meta_width}b does not match '
                             f'the QDMA C2H meta ({QDMA_C2H_META_WID}b)')

    def send(self, data, qid=0, tcrc=None, burst=1):
        size = len(data)
        if not 0 <= qid < (1 << QDMA_QID_WID):
            raise ValueError(f'[{self.name}] qid {qid} out of range')
        if not 0 < size < (1 << QDMA_SIZE_WID):
            raise ValueError(f'[{self.name}] packet size {size}B out of range')
        if tcrc is None:
            tcrc = qdma_crc(data)
        meta = QdmaC2hMeta(qid=qid, tcrc=tcrc, size=size)
        if self.debug:
            print(f'# [{self.name}] {meta}')
        super().send(data, meta=meta.pack(), burst=burst)
