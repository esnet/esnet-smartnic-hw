# Example Design: shell


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

1. Prior to generating the AMD (Xilinx) vitisnetp4 example design, a user must specify the p4bm test directory
that will be imported for simulation.  This is done by assigning the full directory pathname to the
EXAMPLE_TEST_DIR variable in the application Makefile. For example:

       export EXAMPLE_TEST_DIR := $(CURDIR)/p4/sim/test-fwd-p0

   By setting the above Makefile variable, the example design will import all input stimulus, CLI programming,
and any (optional) extern behvioural models associated with the specified simulation testcase.


2. The AMD (Xilinx) vitisnetp4 example design can be generated in the local application design directory by
running the 'example' target of the root-level application Makefile, as follows:

       > make example

   Executing the above make command will generate the vitisnetp4 example design in a subdirectory
called `example/sdnet_0_ex/`.


3. From the `example/sdnet_0_ex/` subdirectory, the AMD (Xilinx) Vivado tool can be invoked, the
example design project can be opened, and the p4 processor can be simulated, as follows:

       > cd example/sdnet_0_ex
       > vivado

       - From the `File->Project->Open...` menu, select 'sdnet_0_ex.xpr' and open the example design project.
       - From the `Flow Navigator` menu, select 'Simulation->Run Simulation->Run Behavioural Simulation'.

   For more information about how to simulate designs and evaluate results within the AMD (Xilinx) Vivado GUI,
refer to the following document:

   - *Vivado Design Suite User Guide - Logic Simulation, UG900 (v2023.1) May 10, 2023.*


4. Note that vitisnetp4 example design generation supports the optional instantiation of custom user extern
function(s) by including the following design files:

   - System Verilog RTL code for custom extern function(s) in the file `extern/rtl/smartnic_extern.sv`.
  Furthermore, if a user captures extern function(s) in a design hierarchy comprised of multiple .sv files,
  all of the .sv files located in the `extern/rtl` directory will be included in the example design project,

   - C++ behavioural model(s) for custom extern function(s) in the file `p4/sim/user_externs/smartnic_extern.cpp`

   Furthermore, when simulating the vitisnetp4 example design with a user extern, the `smartnic_extern`
instantiation is located within the `example_dut_wrapper` module (instance name `dut_inst/smartnic_extern_0`).


### Building the SmartNIC hardware design

Refer to the `Getting Started` section of the `esnet-smartnic-hw/README.md` file:
https://github.com/esnet/esnet-smartnic-hw#readme


**NOTE: See lower level README files for more details.**



# Known Issues

- None to date.
