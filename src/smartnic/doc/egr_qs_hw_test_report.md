# ESnet SmartNIC HBM Egress Queues - Performance Test Report
 Egress queues have been implemented in the ESnet SmartNIC platform in order to take advantage of HBM in order to support advanced traffic management functions in SmartNIC network applications. This report will capture the results of functional and performance testing of this queue implementation in hardware.

 ## Design
 The queue implementation is captured in [`smartnic_egress_qs.sv`](../../rtl/src/smartnic_egress_qs.sv). This component leverages the [common ESnet FPGA repository](../../../../esnet-fpga-library/) extensively (especially the `packet`, `alloc` and `axi3` libraries) and   instantiates the [HBM Controller IP](../../../xilinx/hbm/ip) directly.

 The HBM memory is managed as a pool of 2kB buffers allocated by a scatter-gather controller. As packets are received they are written to the memory using an available buffer descriptor. The buffer descriptor is stored and added to a list representing a virtual output queue. A packet scheduler services the output queues according to a specified algorithm or configuration and uses the descriptors to dequeue the packet data for transmission.

 ## Configuration
 For this testing, the egress queue component is implemented with a trivial packet scheduler, for which all packets enqueued are dequeued in the same order. The intent is to configure the queue component to look as much as possible like a wire. This simplifies the setup/analysis and allows for a simple way to measure performance. Obviously the mechanics of storing/loading the packet data to/from HBM is much more complicated than a wire, but under some operating conditions at least the queues would be expected to behave equivalently to a wire with some added delay.

## DPDK Testing
 To source/sink packets the `dpdk-pktgen` software application is used. This application is capable of sourcing traffic over the PCIe interface.

 The application is executed within a `smartnic-dpdk` container and configures one dedicated CPU core for Tx and another for Rx, for each of the two PCIe physical functions. The test system is able to source ~60Gbps, which is sufficient for functional testing and initial performance testing.

 ## SmartNIC Configuration
The SmartNIC platform is configured to provide one QDMA queue (C2H/H2C) to each of the VF2 interfaces:
```
sn-cfg configure host --host-id 0 --reset-dma-queues --dma-queues vf2:0:1
sn-cfg configure host --host-id 1 --reset-dma-queues --dma-queues vf2:1:1
```
Test I/O is configured (instead of CMAC I/O) and the application is bypassed:
```
sn-cfg configure switch -i 0:test:app
sn-cfg configure switch -i 1:test:app
sn-cfg configure switch -e 0:test
sn-cfg configure switch -e 1:test
sn-cfg configure switch -b straight
```
The application is bypassed:
```
regio-esnet-smartnic eval dev0.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_enable=1
```
The egress queues are enabled:
```
regio-esnet-smartnic eval dev0.bar2.smartnic_egr_qs.control.control.enable=1
``` 

# DPDK Test Results
The following tables describe the transmitted and received throughput (bandwidth + packet rate), for a 1 minute `dpdk-pktgen` test:

### Port 0

| Packet Size (B) | Tx (Pkts) | Tx (Gbps) | Tx (Mpps) | Rx (Pkts) | Rx (Gbps) | Rx (Mpps) |  %  |
|-----------------|-----------|-----------|-----------|-----------|-----------|-----------|-----|
| 64              | 617607424 | 6.5       |  9.81     | 517236810 | 5.5       | 8.21      |  84 |
| 128             | 498882304 | 10        |  8.22     | 498882304 | 10        | 8.22      | 100 |
| 256             | 487485440 | 17        |  7.93     | 487485440 | 17        | 7.93      | 100 |
| 512             | 433299584 | 30        |  7.11     | 433299584 | 30        | 7.11      | 100 |
| 768             | 400614400 | 39        |  6.25     | 400614400 | 39        | 6.22      | 100 |
| 1024            | 360409408 | 47        |  5.66     | 360409408 | 47        | 5.66      | 100 |
| 1512            | 294786048 | 57        |  4.67     | 294786048 | 57        | 4.67      | 100 |

### Port 1

| Packet Size (B) | Tx (Pkts) | Tx (Gbps) | Tx (Mpps) | Rx (Pkts) | Rx (Gbps) | Rx (Mpps) |  %  |
|-----------------|-----------|-----------|-----------|-----------|-----------|-----------|-----|
| 64              | 599251712 | 6.5       | 9.69      | 503097180 | 5.5       | 8.14      |  84 |
| 128             | 496064320 | 10        | 8.14      | 496064320 | 10        | 8.14      | 100 |
| 256             | 474661824 | 17        | 7.85      | 474661824 | 17        | 7.85      | 100 |
| 512             | 427937152 | 30        | 7.10      | 427937152 | 30        | 7.10      | 100 |
| 768             | 378125952 | 39        | 6.18      | 378125952 | 39        | 6.18      | 100 |
| 1024            | 340600192 | 46        | 5.58      | 340600192 | 46        | 5.58      | 100 |
| 1512            | 241657216 | 57        | 4.63      | 241657216 | 57        | 4.63      | 100 |

### Discussion
Packet transmission through the HBM queues has been demonstrated on either of the two physical ports at up to 57Gbps. This limit represents the speed at which the software application (`dpdk-pktgen`) can generate and transmit packets over PCIe, and not a fundamental limitation of the queues or memory accesses themselves. Future testing using hardware-generated test packets are required to validate 100Gbps support.

At small packet sizes the queues are unable to keep up to the ~10Mpps rate that can be sourced by `dpdk-pktgen`. If the queues are bypassed, the receive side *is* able to keep up, so the ~8.2Mpps limit appears to be the result of the queues themselves, at least for minimum-size packets. Additional testing and design iteration might be warranted to improve this, possibly by increasing the parallelism of the scatter/gather state machines, or optimizing the HBM access patterns.

Note that the system is robust to the transmitter providing more traffic than can be processed by the HBM queues. Some traffic is lost so Rx < Tx, but that traffic is dropped efficiently such that there is no unexpected performance degradation, lockups, etc. 