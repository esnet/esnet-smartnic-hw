from robot.api.deco import keyword, library
from robot.api import Failure, ContinuableFailure

from operator import truediv
from functools import reduce

import scapy
from scapy.all import rdpcap, wrpcap
from scapy.all import Ether, Dot1Q
from scapy.all import IP, ARP, ICMP
from scapy.all import IPOption, IPOption_EOL, IPOption_NOP, IPOption_Security, IPOption_LSRR, IPOption_Timestamp, IPOption_RR, IPOption_Stream_Id, IPOption_SSRR, IPOption_MTU_Probe, IPOption_MTU_Reply, IPOption_Traceroute, IPOption_Address_Extension, IPOption_Router_Alert, IPOption_SDBM
from scapy.all import IPv6, ICMPv6ND_NS, ICMPv6ND_NA, ICMPv6NDOptSrcLLAddr, ICMPv6EchoRequest, ICMPv6EchoReply
from scapy.all import UDP, TCP
from scapy.all import ESP
from scapy.all import checksum, in4_chksum, in6_chksum, raw, socket

#---------------------------------------------------------------------------------------------------
# TODO: Maybe auto-create layer keywords by introspection into the scapy layer list
@library
class Library:
    def __init__(self):
        pass

    @keyword
    def packet_ether(self, **kwargs):
        return Ether(**kwargs)

    @keyword
    def packet_dot1q(self, **kwargs):
        return Dot1Q(**kwargs)

    @keyword
    def packet_ip(self, **kwargs):
        return IP(**kwargs)

    @keyword
    def packet_ipoption(self, **kwargs):
        return IPOption(**kwargs)

    @keyword
    def packet_ipoption_eol(self, **kwargs):
        return IPOption_EOL(**kwargs)

    @keyword
    def packet_ipoption_nop(self, **kwargs):
        return IPOption_NOP(**kwargs)

    @keyword
    def packet_ipoption_security(self, **kwargs):
        return IPOption_Security(**kwargs)

    @keyword
    def packet_ipoption_lssr(self, **kwargs):
        return IPOption_LSSR(**kwargs)

    @keyword
    def packet_ipoption_timestamp(self, **kwargs):
        return IPOption_Timestamp(**kwargs)

    @keyword
    def packet_ipoption_rr(self, **kwargs):
        return IPOption_RR(**kwargs)

    @keyword
    def packet_ipoption_stream_id(self, **kwargs):
        return IPOption_Stream_Id(**kwargs)

    @keyword
    def packet_ipoption_ssrr(self, **kwargs):
        return IPOption_SSRR(**kwargs)

    @keyword
    def packet_ipoption_mtu_probe(self, **kwargs):
        return IPOption_MTU_Probe(**kwargs)

    @keyword
    def packet_ipoption_mtu_reply(self, **kwargs):
        return IPOption_MTU_Reply(**kwargs)

    @keyword
    def packet_ipoption_traceroute(self, **kwargs):
        return IPOption_Traceroute(**kwargs)

    @keyword
    def packet_ipoption_address_extension(self, **kwargs):
        return IPOption_Address_Extension(**kwargs)

    @keyword
    def packet_ipoption_router_alert(self, **kwargs):
        return IPOption_Router_Alert(**kwargs)

    @keyword
    def packet_ipoption_sdbm(self, **kwargs):
        return IPOption_SDBM(**kwargs)

    @keyword
    def packet_ipv6(self, **kwargs):
        return IPv6(**kwargs)

    @keyword
    def packet_icmp(self, **kwargs):
        print(kwargs)
        return ICMP(**kwargs)

    @keyword
    def packet_udp(self, **kwargs):
        return UDP(**kwargs)

    @keyword
    def packet_tcp(self, **kwargs):
        return TCP(**kwargs)

    @keyword
    def packet_esp(self, **kwargs):
        return ESP(**kwargs)

    @keyword
    def packet_arp(self, **kwargs):
        return ARP(**kwargs)

    @keyword
    def packet_ICMPv6ND_NS(self, **kwargs):
        return ICMPv6ND_NS(**kwargs)

    @keyword
    def packet_ICMPv6EchoRequest(self, **kwargs):
        return ICMPv6EchoRequest(**kwargs)

    @keyword
    def packet_ICMPv6NDOptSrcLLAddr(self, **kwargs):
        return ICMPv6NDOptSrcLLAddr(**kwargs)

    @keyword
    def packet_payload(self, **kwargs):
        return bytes(kwargs['payload'], 'utf-8')

    @keyword
    def packet_compose(self, *layers):
        # Compose all of the layers using the "/" (div) operator
        return reduce(truediv, layers)

    @keyword
    def packet_write_pcap(self, filename, packets):
        wrpcap(filename, packets)

    @keyword
    def packet_read_pcap(self, filename):
        return rdpcap(filename)

    @keyword
    def packet_layer_fields(self, packet, layer_name):
        if packet.haslayer(layer_name):
            return packet[layer_name].fields
        else:
            return {}

    @keyword
    def packet_layer_is_present(self, packet, layer_name):
        return packet.haslayer(layer_name)

    @keyword
    def packet_layer_is_absent(self, packet, layer_name):
        return not self.packet_layer_is_present(packet, layer_name)

    @keyword
    def packet_checksums_ok(self, packet):
        # operate on a copy of the packet so we can zero out the checksum without breaking the original
        packet_copy = packet.copy()

        if packet_copy.haslayer("IP"):
            return self.packet_ipv4_checksums_ok(packet_copy)
        elif packet_copy.haslayer("IPv6"):
            return self.packet_ipv6_checksums_ok(packet_copy)
        else:
            raise ContinuableFailure("No checksum implementation provided for non-IP packet type {}".format(packet_copy.summary()))

    # This function expects to be operating on a *copy* of the original packet so it is safe to modify the packet here
    def packet_ipv6_checksums_ok(self, packet):
        ip = packet[IPv6]

        # RFC 2460 requires that a zero checksum is inverted to all 1s for covered protocols (eg. UDP)
        l4_invert_zero_chksum = False

        # identify the L4 proto, collect the rx checksum, zero it out and determine the checksum method
        if packet.haslayer("UDP"):
            l4_proto = socket.IPPROTO_UDP
            l4_rx_chksum = packet[UDP].chksum
            packet[UDP].chksum = 0
            l4_invert_zero_chksum = True
        elif packet.haslayer("ICMPv6EchoReply"):
            l4_proto = socket.IPPROTO_ICMPV6
            l4_rx_chksum = packet[ICMPv6EchoReply].cksum
            packet[ICMPv6EchoReply].cksum = 0
        elif packet.haslayer("ICMPv6ND_NA"):
            l4_proto = socket.IPPROTO_ICMPV6
            l4_rx_chksum = packet[ICMPv6ND_NA].cksum
            packet[ICMPv6ND_NA].cksum = 0
        else:
            raise ContinuableFailure("No checksum implementation provided for {}".format(ip.payload.name))

        if l4_rx_chksum is None:
            # No checksum provided in this packet
            raise ContinuableFailure("No checksum available in packet {}".format(packet.summary()))

        l4_raw = raw(ip.payload)
        calc_chksum = in6_chksum(l4_proto, ip, l4_raw)

        if l4_invert_zero_chksum and calc_chksum == 0:
            calc_chksum = 0xFFFF

        if l4_rx_chksum != calc_chksum:
            raise Failure("Incorrect {} checksum: Packet has 0x{:04x}, expected correct 0x{:04x}".format(
                ip.payload.name,
                l4_rx_chksum,
                calc_chksum
            ))

    # This function expects to be operating on a *copy* of the original packet so it is safe to modify the packet here
    def packet_ipv4_checksums_ok(self, packet):
        ip = packet[IP]

        # Compute and check the IPv4 header checksum
        l3_rx_chksum = packet[IP].chksum
        packet[IP].chksum = 0
        l3_calc_chksum = checksum(bytes(packet[IP])[:packet[IP].ihl * 4])

        if l3_rx_chksum != l3_calc_chksum:
            raise Failure("Incorrect IPv4 header checksum: Packet has 0x{:04x}, expected correct 0x{:04x}".format(
                l3_rx_chksum,
                l3_calc_chksum
            ))

        # RFC 768 requires that a zero checksum is inverted to all 1s for covered protocols (eg. UDP)
        l4_invert_zero_chksum = False

        # identify the L4 proto, collect the rx checksum, zero it out and determine the checksum method
        if packet.haslayer("UDP"):
            l4_proto = socket.IPPROTO_UDP
            l4_rx_chksum = packet[UDP].chksum
            packet[UDP].chksum = 0
            has_pseudo_header = True
            l4_invert_zero_chksum = True
        elif packet.haslayer("ICMP"):
            l4_proto = socket.IPPROTO_ICMP
            l4_rx_chksum = packet[ICMP].chksum
            packet[ICMP].chksum = 0
            has_pseudo_header = False
        else:
            raise ContinuableFailure("No checksum implementation provided for {}".format(ip.payload.name))

        if l4_rx_chksum is None:
            # No checksum provided in this packet
            raise ContinuableFailure("No checksum available in packet {}".format(packet.summary()))

        l4_raw = raw(ip.payload)
        if has_pseudo_header:
            calc_chksum = in4_chksum(l4_proto, ip, l4_raw)
            if l4_invert_zero_chksum and calc_chksum == 0:
                calc_chksum = 0xFFFF
        else:
            calc_chksum = checksum(l4_raw)

        if l4_rx_chksum != calc_chksum:
            raise Failure("Incorrect {} checksum: Packet has 0x{:04x}, expected correct 0x{:04x}".format(
                ip.payload.name,
                l4_rx_chksum,
                calc_chksum
            ))

    @keyword
    def packet_log_packets(self, *packets):
        for idx, packet in enumerate(packets):
            print(f"====== packet {idx} ======")
            packet.show()

    
