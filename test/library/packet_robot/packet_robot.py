from robot.api.deco import keyword, library

from operator import truediv
from functools import reduce

import scapy
from scapy.all import rdpcap, wrpcap
from scapy.all import Ether, Dot1Q
from scapy.all import IP, ARP, ICMP
from scapy.all import IPOption, IPOption_EOL, IPOption_NOP, IPOption_Security, IPOption_LSRR, IPOption_Timestamp, IPOption_RR, IPOption_Stream_Id, IPOption_SSRR, IPOption_MTU_Probe, IPOption_MTU_Reply, IPOption_Traceroute, IPOption_Address_Extension, IPOption_Router_Alert, IPOption_SDBM
from scapy.all import IPv6, ICMPv6ND_NS, ICMPv6NDOptSrcLLAddr, ICMPv6EchoRequest
from scapy.all import UDP, TCP
from scapy.all import ESP

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
    def packet_write_pcap(self, filename, *packets):
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
    def packet_log_packets(self, *packets):
        for idx, packet in enumerate(packets):
            print(f"====== packet {idx} ======")
            packet.show()

    
