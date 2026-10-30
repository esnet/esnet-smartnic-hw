__all__ = (
    'QDMA_QID_WID',
    'QDMA_TCRC_WID',
    'QDMA_SIZE_WID',
    'QDMA_H2C_META_WID',
    'QDMA_C2H_META_WID',
    'qdma_crc',
    'QdmaH2cMeta',
    'QdmaC2hMeta',
)

import zlib

# Metadata layouts of the QDMA packet interfaces (xilinx_qdma_pkg).  The packed
# structs list the most significant field first:
#
#   pkt_h2c_meta_t = {tcrc[31:0], qid[QID_WID-1:0]}
#   pkt_c2h_meta_t = {size[15:0], tcrc[31:0], qid[QID_WID-1:0]}
QDMA_QID_WID  = 12
QDMA_TCRC_WID = 32
QDMA_SIZE_WID = 16

QDMA_H2C_META_WID = QDMA_TCRC_WID + QDMA_QID_WID
QDMA_C2H_META_WID = QDMA_SIZE_WID + QDMA_TCRC_WID + QDMA_QID_WID

_QID_MASK  = (1 << QDMA_QID_WID) - 1
_TCRC_MASK = (1 << QDMA_TCRC_WID) - 1
_SIZE_MASK = (1 << QDMA_SIZE_WID) - 1


def qdma_crc(data):
    """IEEE 802.3 CRC-32 of a packet payload, as carried in the QDMA tcrc."""
    return zlib.crc32(bytes(data)) & _TCRC_MASK


class QdmaH2cMeta():
    """H2C metadata, as supplied by the DMA engine with each packet."""

    def __init__(self, qid, tcrc):
        self.qid = qid
        self.tcrc = tcrc

    @classmethod
    def unpack(cls, meta):
        return cls(qid  = meta & _QID_MASK,
                   tcrc = (meta >> QDMA_QID_WID) & _TCRC_MASK)

    def pack(self):
        return ((self.tcrc & _TCRC_MASK) << QDMA_QID_WID) | (self.qid & _QID_MASK)

    def crc_ok(self, data):
        """True if the tcrc matches the CRC-32 of the packet payload."""
        return self.tcrc == qdma_crc(data)

    def __eq__(self, other):
        return isinstance(other, QdmaH2cMeta) and self.pack() == other.pack()

    def __repr__(self):
        return f'QdmaH2cMeta(qid={self.qid}, tcrc=0x{self.tcrc:08x})'


class QdmaC2hMeta():
    """C2H metadata, as presented to the DMA engine with each packet."""

    def __init__(self, qid, tcrc, size):
        self.qid = qid
        self.tcrc = tcrc
        self.size = size

    @classmethod
    def unpack(cls, meta):
        return cls(qid  = meta & _QID_MASK,
                   tcrc = (meta >> QDMA_QID_WID) & _TCRC_MASK,
                   size = (meta >> (QDMA_QID_WID + QDMA_TCRC_WID)) & _SIZE_MASK)

    def pack(self):
        return ((self.size & _SIZE_MASK) << (QDMA_QID_WID + QDMA_TCRC_WID)) | \
               ((self.tcrc & _TCRC_MASK) << QDMA_QID_WID) | \
               (self.qid & _QID_MASK)

    def __eq__(self, other):
        return isinstance(other, QdmaC2hMeta) and self.pack() == other.pack()

    def __repr__(self):
        return f'QdmaC2hMeta(qid={self.qid}, tcrc=0x{self.tcrc:08x}, size={self.size})'
