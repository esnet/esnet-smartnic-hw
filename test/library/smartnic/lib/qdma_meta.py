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


QDMA_DATA_BYTE_WID = 64   # QDMA AXI-S beat width (512 bits)
_CRC_POLY = 0x04c11db7
_CRC_INIT = 0xffffffff


def _crc_beat(crc, beat):
    # MSB-first CRC over one beat, taken as a little-endian integer: the last
    # byte is shifted in first.
    for byte in reversed(beat):
        crc ^= byte << 24
        for _ in range(8):
            crc = ((crc << 1) ^ _CRC_POLY if crc & 0x80000000 else crc << 1) & _TCRC_MASK
    return crc


def qdma_crc(data):
    """CRC the QDMA engine carries in tcrc for a packet payload.

    This is not the Ethernet CRC-32 (zlib.crc32).  It uses the same polynomial
    (0x04c11db7) and init (0xffffffff) but is non-reflected with no final xor,
    and is computed beat by beat over the 512-bit AXI-S data bus:

      - each beat is treated as one integer (byte 0 least significant) and
        shifted in MSB first, so the last byte of the beat enters first;
      - the state carries across the beats of a packet, in order;
      - the final beat is zero-padded to a full beat and the padding is part
        of the CRC.

    Empirically derived from H2C captures of 60, 64 and 196 byte packets.
    """
    data = bytes(data)
    data += bytes(-len(data) % QDMA_DATA_BYTE_WID)
    crc = _CRC_INIT
    for i in range(0, len(data), QDMA_DATA_BYTE_WID):
        crc = _crc_beat(crc, data[i:i + QDMA_DATA_BYTE_WID])
    return crc


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
        """True if the tcrc matches the qdma_crc of the packet payload."""
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
