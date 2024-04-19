# Example Design: p4_multi_proc

The p4_multi_proc example design provides the P4 source code and behavioural simulation testcases for a simple
multi-processor P4 application.  The ingress processor implements the 'p4_with_extern' example, while the egress
processor implements the 'p4_only' example.  See examples/p4_with_extern/README.md and examples/p4_only/README.md
for additional details.

Note: In addition to the source code for the ingress and egress P4 processors, this example design also includes
placeholders for custom ingress and egress RTL datapath functions (smartnic_app_igr and smartnic_app_egr), to be
considered for full support in a future release.  In this release, these placeholder blocks simply implement
pass-through logic.


## Development Flow

The sections below direct the user to:

1. Install the SmartNIC platform design repositories.
2. Execute a P4 behavioural simulation (to verify P4 program correctness ahead of building hardware).
3. Generate and Simulate the AMD (Xilinx) Vitisnetp4 Example Design at the RTL-level (optional).
4. Build the P4-based custom SmartNIC hardware.


### Installing the SmartNIC Repositories

Refer to the `Getting Started` section of the `esnet-smartnic-hw/README.md` file:
https://github.com/esnet/esnet-smartnic-hw#readme


### Simulating the P4 Programs

Refer to instructions in the `esnet-smartnic-hw/examples/p4_multi_proc/p4/sim_igr/README.md` file.


### Generating and Simulating the AMD (Xilinx) Vitisnetp4 Example Design

1. Prior to generating the AMD (Xilinx) vitisnetp4 example design, a user must set the following
variables in the root-level application Makefile:

`EXAMPLE_P4_FILE` specifies the full pathname of the P4 file,
`EXAMPLE_VITISNETP4_IP_NAME` specifies the vitisnetp4 instance name for the example design, and
`EXAMPLE_TEST_DIR` specifies the path to the test directory that will be imported for simulation.  For example:

       export EXAMPLE_P4_FILE := $(CURDIR)/p4/p4_multi_proc_igr.p4
       export EXAMPLE_VITISNETP4_IP_NAME := sdnet_igr
       export EXAMPLE_TEST_DIR := $(CURDIR)/p4/sim_igr/test-fwd-p0

   By setting the above Makefile variables, the example design will import all input stimulus, CLI programming,
and any (optional) extern behvioural models associated with the specified simulation testcase.


2. The AMD (Xilinx) vitisnetp4 example design can be generated in the local application design directory by
running the 'example' target of the root-level application Makefile, as follows:

       > make example

   Executing the above make command will generate the vitisnetp4 example design in a subdirectory
called `example/sdnet_igr_ex/`.


3. From the `example/sdnet_igr_ex/` subdirectory, the AMD (Xilinx) Vivado tool can be invoked, the
example design project can be opened, and the p4 processor can be simulated, as follows:

       > cd example/sdnet_igr_ex
       > vivado

       - From the `File->Project->Open...` menu, select 'sdnet_igr_ex.xpr' and open the example design project.
       - From the `Flow Navigator` menu, select 'Simulation->Run Simulation->Run Behavioural Simulation'.

   For more information about how to simulate designs and evaluate results within the AMD (Xilinx) Vivado GUI,
refer to the following document:

   - *Vivado Design Suite User Guide - Logic Simulation, UG900 (v2023.2) October 18, 2023.*


4. Note that vitisnetp4 example design generation also supports the optional instantiation of custom user extern
function(s) by supplying the following additional file content:

   - C++ behavioural model for the custom extern function(s) in file `p4/sim/user_externs/sdnet_igr_extern.cpp`.

   - System verilog RTL code for the custom extern function(s) in file `src/sdnet_igr_extern/rtl/src/sdnet_igr_extern.sv`.
   If a user wishes to captures extern function(s) in a design hierarchy comprised of multiple .sv files,
   all of the .sv files located in the `src/sdnet_igr_extern/rtl/src/` directory will be included in the example
   design project.

   Finally, when simulating the vitisnetp4 example design with a user extern function, the `sdnet_igr_extern`
instantiation can be found within the `example_dut_wrapper` module (instance name `dut_inst/sdnet_igr_extern_inst`).

   See the `p4_with_extern` example design for reference.


### Building the SmartNIC hardware design

Refer to the `Getting Started` section of the `esnet-smartnic-hw/README.md` file:
https://github.com/esnet/esnet-smartnic-hw#readme


**NOTE: See lower level README files for more details.**



# Known Issues

- None to date.
