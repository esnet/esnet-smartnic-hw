from robot.api.deco import keyword, library

from operator import truediv
from functools import reduce

import scapy
from scapy.all import Ether, IP, ICMP, IPv6, ARP, ICMPv6ND_NS, ICMPv6NDOptSrcLLAddr, ICMPv6EchoRequest, UDP, TCP, rdpcap, wrpcap

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
    def packet_ip(self, **kwargs):
        return IP(**kwargs)

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
        wrpcap(filename, *packets)

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
    def packet_log_packets(self, *packets):
        for idx, packet in enumerate(packets):
            print(f"====== packet {idx} ======")
            packet.show()

    
