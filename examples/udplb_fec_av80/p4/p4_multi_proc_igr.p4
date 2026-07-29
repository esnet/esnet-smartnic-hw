#include <core.p4>
#include <xsa.p4>

// ****************************************************************************** //
// *************************** H E A D E R S  *********************************** //
// ****************************************************************************** //

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

// ****************************************************************************** //
// ************************* S T R U C T U R E S  ******************************* //
// ****************************************************************************** //

// header structure
struct headers {
    ethernet_t ethernet;
}

struct smartnic_metadata {
    bit<64> timestamp_ns;    // 64b timestamp (in nanoseconds). Set at packet arrival time.
    bit<16> pid;             // 16b packet id used by platform (READ ONLY - DO NOT EDIT).
    bit<4>  ingress_port;    // bit<0>   port_num (0:P0, 1:P1).
                             // bit<3:1> port_typ (0:PHY, 1:PF, 2:VF, 3:APP, 4-7:reserved).
    bit<4>  egress_port;     // bit<0>   port_num (0:P0, 1:P1).
                             // bit<3:1> port_typ (0:PHY, 1:PF, 2:VF, 3:APP, 4-6:reserved, 7:UNSET).
    bit<1>  truncate_enable; // 1b set to 1 to enable truncation of egress packet to 'truncate_length'.
    bit<16> truncate_length; // 16b set to desired length of egress packet (used when 'truncate_enable' == 1).
    bit<1>  rss_enable;      // 1b set to 1 to override open-nic-shell rss hash result with 'rss_entropy' value.
    bit<12> rss_entropy;     // 12b set to rss_entropy hash value (used for open-nic-shell qdma qid selection).
    bit<4>  drop_reason;     // reserved (tied to 0).
    bit<32> scratch;         // reserved (tied to 0).
}

// ****************************************************************************** //
// *************************** P A R S E R  ************************************* //
// ****************************************************************************** //

parser ParserImpl( packet_in packet,
                   out headers hdr,
                   inout smartnic_metadata sn_meta,
                   inout standard_metadata_t smeta) {
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition accept;
    }
}

// ****************************************************************************** //
// **************************  P R O C E S S I N G   **************************** //
// ****************************************************************************** //

control MatchActionImpl( inout headers hdr,
                         inout smartnic_metadata sn_meta,
                         inout standard_metadata_t smeta) {

    // Extern function
    UserExtern<bit<12>,bit<12>>(16) minimal_user_extern_example;
    bit<12> extern_in;
    bit<12> extern_out;

    action forwardPacket(bit<4> dest_port) {
        extern_in = 8w0 ++ dest_port;
        minimal_user_extern_example.apply(extern_in, extern_out);
        sn_meta.egress_port = (bit<4>) (extern_out);
    }
    
    action loopPacket() {
        sn_meta.egress_port = sn_meta.ingress_port;
    }

    action dropPacket() {
        smeta.drop = 1;
    }

    table forward {
        key     = { hdr.ethernet.dstAddr : lpm; }
        actions = { forwardPacket; 
                    loopPacket;
                    dropPacket;
                    NoAction; }
        size    = 128;
        num_masks = 8;
        default_action = loopPacket;
    }

    apply {
        if (smeta.parser_error != error.NoError) {
            dropPacket();
            return;
        }
        
        if (hdr.ethernet.isValid()) {
            sn_meta.rss_entropy = 8w0 ++ sn_meta.ingress_port;
            sn_meta.rss_enable = 1w1;
            forward.apply();
        }
        else
            dropPacket();
    }
}

// ****************************************************************************** //
// ***************************  D E P A R S E R  ******************************** //
// ****************************************************************************** //

control DeparserImpl( packet_out packet,
                      in headers hdr,
                      inout smartnic_metadata sn_meta,
                      inout standard_metadata_t smeta) {
    apply {
        packet.emit(hdr.ethernet);
    }
}

// ****************************************************************************** //
// *******************************  M A I N  ************************************ //
// ****************************************************************************** //

XilinxPipeline(
    ParserImpl(), 
    MatchActionImpl(), 
    DeparserImpl()
) main;
