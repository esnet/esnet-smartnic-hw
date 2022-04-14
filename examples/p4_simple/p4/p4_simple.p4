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

struct short_metadata {
    bit<64> ingress_global_timestamp;  // 64b timestamp (in nanoseconds). Set at packet arrival time.
    bit<2>  dest_port;                 // 2b destination port (0:CMAC0, 1:CMAC1, 2:HOST0, 3:HOST1).
                                       // dest_port set to src_port by default.
    bit<1>  truncate_enable;           // reserved (tied to 0).
    bit<16> packet_length;             // reserved (tied to 0).
    bit<1>  rss_override_enable;       // reserved (tied to 0).
    bit<8>  rss_override;              // reserved (tied to 0).
}
 

// ****************************************************************************** //
// *************************** P A R S E R  ************************************* //
// ****************************************************************************** //

parser ParserImpl( packet_in packet,
                   out headers hdr,
                   inout short_metadata short_meta,
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
                         inout short_metadata short_meta,
                         inout standard_metadata_t smeta) {

    action forwardPacket(bit<2> dest_port) {
        short_meta.dest_port = dest_port;
    }
    
    action dropPacket() {
        smeta.drop = 1;
    }

    table forward {
        key     = { hdr.ethernet.dstAddr : lpm; }
        actions = { forwardPacket; 
                    dropPacket;
                    NoAction; }
        size    = 128;
        num_masks = 8;
        default_action = NoAction;
    }

    apply {
        if (smeta.parser_error != error.NoError) {
            dropPacket();
            return;
        }
        
        if (hdr.ethernet.isValid())
            forward.apply();
        else
            dropPacket();
    }
}

// ****************************************************************************** //
// ***************************  D E P A R S E R  ******************************** //
// ****************************************************************************** //

control DeparserImpl( packet_out packet,
                      in headers hdr,
                      inout short_metadata short_meta,
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
