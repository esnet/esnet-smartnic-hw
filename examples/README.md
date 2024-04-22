# SmartNIC Example Designs

The `esnet-smartnic-hw/examples/` directory contains the design directories for the following application examples:

## Supported (in this release)

### p4_only/

The p4_only example design provides the P4 source code and a behavioural simulation testcase for a simple
P4 application core.  This example follows a pure P4 design flow and does NOT include any custom verilog hardware.
As such,  the user only needs to provide a working P4 program file to build the custom SmartNIC hardware.

### p4_with_extern/

The p4_with_extern example design provides the P4 source code and a behavioural simulation testcase for a simple
P4 application core AND a user extern function.  In addition to the P4 program, the source content for this example
includes a C++ (.cpp) behavioural model and system verilog RTL code for the accompanying extern function.

### p4_multi_proc/

The p4_multi_proc example design provides an example for a multi-processor application that incorporates separate
ingress and egress P4 functions.  The example includes separate programs and behavioural simulation directories for
the ingress and egress P4 functions, as well as an extern function that accompanies the ingress P4 processor.

**NOTE:** See lower level README files for more details about each design.



## Unsupported (for future release)

### p4_hbm/

The p4_hbm example design provides the P4 source code and a behavioural simulation testcase for a
P4 application core that leverages the integrated HBM (high-bandwidth memory) to implement a large (1M)
IPv4/IPv6 filter.  This example follows a pure P4 design flow and does NOT include any custom verilog hardware.
As such, the user only needs  to provide a working P4 program file to build the custom SmartNIC hardware.

p4_hbm is a legacy example design whose support was suspended when the AMD vitisnetp4 IP dropped HBM support for
AMD Ultrascale+ devices.  Support for this design may be resurrected in future device technologies.

### p4_and_verilog/ 

The p4_and_verilog example design will be intended to provide an example of a design implementation that is comprised
of both a working P4 program and custom verilog hardware.  In addition to the directories that support p4 simulation
and building custom SmartNIC hardware, it will also include directories for verilog source files and simulation.

### p2p/ 

The p2p example design will be intended to provide an example of a design implementation that is comprised of only
custom verilog hardware.  It will include directories for verilog source files and simulation, as well as building
custom SmartNIC hardware (without a P4 processing core).
