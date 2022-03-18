# Example Design: p4_simple

The p4_simple example design provides the P4 source code and a behavioural simulation testcase for a simple
P4 application core.

This example follows a pure P4 design flow and does NOT include any custom verilog hardware.  As such,
the user only provides the working P4 program file to build the custom smartnic hardware.



## Functional Specification

The p4_simple design implements a simple table-based Layer-2 packet switch.  It uses a single LPM lookup
table that takes the Ethernet Destination MAC Address field as the key.

When the lookup matches, the table returns the programmed destination port for the specified packet flow.
The returned destination port is then written into the output metadata (dest_port field), which is used
by the smartnic hardware for packet forwarding.

When the lookup misses, the output metadata remains unchanged and the packet is forwarded to the destination
port that was specified in the packet's input metadata (dest_port field).

Packets with invalid and errored Ethernet headers are dropped.



## Development Flow

The sections below direct the user to:

1. Install the SmartNIC platform design repositories
2. Execute a P4 behavioural simulation (to verify P4 program correctness ahead of building hardware).
3. Build the P4-based custom smartnic hardware.


### Installing the SmartNIC Repositories

Refer to steps 1-3 in the `Getting Started` section of the esnet-smartnic-hw/README.md file
(https://github.com/esnet/esnet-smartnic-hw#readme).


### Simulating the P4 program

Refer to instructions in the esnet-smartnic-hw/examples/p4_simple/p4/sim/README.md file
(https://github.com/esnet/esnet-smartnic-hw/examples/p4_simple/p4/sim#readme).


### Building the SmartNIC hardware design

Refer to step 6 in the `Building a New Application` section of the esnet-smartnic-hw/README.md file
(https://github.com/esnet/esnet-smartnic-hw#readme).



**NOTE: See lower level README files for more details.**



# Known Issues

- None to date.
