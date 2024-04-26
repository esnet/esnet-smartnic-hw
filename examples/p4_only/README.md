# Example Design: p4_only

The p4_only example design provides the P4 source code and a behavioural simulation testcase for a simple
P4 application core.

This example follows a pure P4 design flow and does NOT include any custom verilog hardware.  As such,
the user only provides the working P4 program file to build the custom SmartNIC hardware.



## Functional Specification

The p4_only design implements a simple table-based Layer-2 packet switch.  It uses a single LPM lookup
table that takes the Ethernet Destination MAC Address field as the key.

When the lookup matches, the table returns the programmed destination port for the specified packet flow.
The returned destination port is then written into the output metadata (`egress_port` field), which is used
by the SmartNIC hardware for packet forwarding.

When the lookup misses, the output metadata remains unchanged and the packet is forwarded to the destination
port that was specified in the packet's input metadata (`egress_port` field).

Packets with invalid and errored Ethernet headers are dropped.



## Development Flow

The sections below direct the user to:

1. Install the SmartNIC platform design repositories.
2. Execute a P4 behavioural simulation (to verify P4 program correctness ahead of building hardware).
3. Generate and Simulate the AMD (Xilinx) Vitisnetp4 Example Design at the RTL-level (optional).
4. Build the P4-based custom SmartNIC hardware.


### Installing the SmartNIC Repositories

Refer to the `Getting Started` section of the `esnet-smartnic-hw/README.md` file:
https://github.com/esnet/esnet-smartnic-hw#readme


### Simulating the P4 Program

Refer to instructions in the `esnet-smartnic-hw/examples/p4_only/p4/sim/README.md` file.


### Generating and Simulating the AMD (Xilinx) Vitisnetp4 Example Design

1. Prior to generating the AMD (Xilinx) vitisnetp4 example design, a user must set the following
variables in the root-level application Makefile:

`EXAMPLE_P4_FILE` specifies the full pathname of the P4 file,
`EXAMPLE_VITISNETP4_IP_NAME` specifies the vitisnetp4 instance name for the example design, and
`EXAMPLE_TEST_DIR` specifies the path to the test directory that will be imported for simulation.  For example:

       export EXAMPLE_P4_FILE := $(CURDIR)/p4/p4_only.p4
       export EXAMPLE_VITISNETP4_IP_NAME := vitisnetp4_igr
       export EXAMPLE_TEST_DIR := $(CURDIR)/p4/sim/test-fwd-p0

   By setting the above Makefile variables, the example design will import all input stimulus, CLI programming,
and any (optional) extern behvioural models associated with the specified simulation testcase.


2. The AMD (Xilinx) vitisnetp4 example design can be generated in the local application design directory by
running the 'example' target of the root-level application Makefile, as follows:

       > make example

   Executing the above make command will generate the vitisnetp4 example design in a subdirectory
called `example/vitisnetp4_igr_ex/`.


3. From the `example/vitisnetp4_igr_ex/` subdirectory, the AMD (Xilinx) Vivado tool can be invoked, the
example design project can be opened, and the p4 processor can be simulated, as follows:

       > cd example/vitisnetp4_igr_ex
       > vivado

       - From the `File->Project->Open...` menu, select 'vitisnetp4_igr_ex.xpr' and open the example design project.
       - From the `Flow Navigator` menu, select 'Simulation->Run Simulation->Run Behavioural Simulation'.

   For more information about how to simulate designs and evaluate results within the AMD (Xilinx) Vivado GUI,
refer to the following document:

   - *Vivado Design Suite User Guide - Logic Simulation, UG900 (v2023.2) October 18, 2023.*


4. Note that vitisnetp4 example design generation also supports the optional instantiation of custom user extern
function(s) by supplying the following additional file content:

   - C++ behavioural model for the custom extern function(s) in file `p4/sim/user_externs/vitisnetp4_igr_extern.cpp`.

   - System verilog RTL code for the custom extern function(s) in file `src/vitisnetp4_igr_extern/rtl/src/vitisnetp4_igr_extern.sv`.
   If a user wishes to captures extern function(s) in a design hierarchy comprised of multiple .sv files,
   all of the .sv files located in the `src/vitisnetp4_igr_extern/rtl/src/` directory will be included in the example
   design project.

   Finally, when simulating the vitisnetp4 example design with a user extern function, the `vitisnetp4_igr_extern`
instantiation can be found within the `example_dut_wrapper` module (instance name `dut_inst/vitisnetp4_igr_extern_inst`).

   See the `p4_with_extern` example design for reference.


### Building the SmartNIC hardware design

Refer to the `Getting Started` section of the `esnet-smartnic-hw/README.md` file:
https://github.com/esnet/esnet-smartnic-hw#readme


**NOTE: See lower level README files for more details.**



# Known Issues

- None to date.
