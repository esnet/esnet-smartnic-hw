# ESnet SmartNIC Hardware Design Repository

This repository contains the hardware design directory for the ESnet SmartNIC platform.

The ESnet SmartNIC Platform is based on the Xilinx (AMD) OpenNIC Shell, which provides
an FPGA-based NIC shell with 100Gbps Ethernet ports, and runs on the Xilinx Alveo family
of hardware boards.  More information about the OpenNIC shell can be found at:
https://github.com/Xilinx/open-nic-shell

The ESnet SmartNIC platform implements a P4-programmable packet processing core within the
OpenNIC shell.  The platform provides the necessary hardware datapath and control features
for the custom processing core.

The esnet-smartnic-hw repository includes the RTL source files, verification test suites
and build scripts for compiling a user P4 file into a downloadable bitfile, as well as the
software artifacts necessary for seamless integration with the smartnic runtime firmware,
which is located in a companion github repository at:
https://github.com/esnet/esnet-smartnic-fw.

The OpenNIC shell and SmartNIC designs are built with the Xilinx Vivado software tool suite.
The current release supports development with Vivado version 2021.2.



## Repository Structure and Dependencies

The ESnet SmartNIC platform is comprised of a collection of separate modular components,
each maintained in their own git repository.

The platform includes the following repositories:

   - `OpenNIC shell` (https://github.com/Xilinx/open-nic-shell.git)  
     An FPGA-based NIC shell that runs on the Xilinx Alveo family of hardware boards.  

   - `ESnet SmartNIC Hardware` (https://github.com/esnet/esnet-smartnic-hw.git)  
     Hardware design directory for the ESnet SmartNIC platform.

   - `ESnet SmartNIC Firmware` (https://github.com/esnet/esnet-smartnic-fw.git)  
     Firmware design directory for the ESnet SmartNIC platform.

   - `ESnet FPGA library` (https://github.com/esnet/esnet-fpga-library.git)  
     General-purpose components and infrastructure for a structured FPGA design methodology.     

   - `SVunit` (https://github.com/svunit/svunit.git)  
     An open-source framework for FPGA System Verilog verification.

   - `ESnet Regio` (https://github.com/esnet/regio.git)  
     Automation tools for the implementation of FPGA register map logic and software code.


All dependent repositories are instantiated in the parent repository as a submodule, as
depicted below:

```
esnet-smartnic-hw/ (parent repository)
├── esnet-fpga-library/ (submodule)
│   └── tools/
│       ├── regio/ (submodule)
│       └── svunit/ (submodule)
└── open-nic-shell/ (submodule)

esnet-smartnic-fw/ (parent repository)
```



## Directory Structure

The directory structure for the ESnet SmartNIC hardware design repository is captured and described below.

```
esnet-smartnic-hw/
├── cfg/
├── docs/
├── esnet-fpga-library/
├── open-nic_shell/
├── examples/
├── src/
├── Makefile
├── makefile.esnet
├── paths.mk
└── README.md

cfg/
  Contains global configuration files for the SmartNIC project.

docs/
  Contains documentation files for the SmartNIC platform.

esnet-fpga-library/
  Contains the ESnet FPGA Design Library (imported as a git submodule).  This library contains general-purpose
  FPGA design content.

open-nic_shell/
  Contains the Xilinx OpenNIC Shell repository (imported as a git submodule).  OpenNIC shell delivers an
  FPGA-based NIC shell with 100Gbps Ethernet ports, for use on the Xilinx Alveo platform.

examples/
  Contains SmartNIC application design exaples.  A new application directory can be started by
  copying one of the provided example directories, or by modeling portions of the example directory structure.

src/
  Contains RTL source and verification code for SmartNIC platform FPGA design components,
  captured in System Verilog.

Makefile
  SmartNIC platform Makefile.  Used to build the FPGA bitfile for the target application, as well as
  generate all artifacts necessary for firmware integration on the hardware platform.

makefile.esnet
  OpenNIC shell Makefile.  Used to build the Xilinx open-nic-shell for the target application.

paths.mk
  Sets environment variables for standard pathnames.

README.md - This README file.

```



## Getting Started 

The following steps guide a new user through the installation of the SmartNIC Hardware Design Repository,
as well as simulating and building a simple P4-based example design.

1. Install the esnet-smartnic-hw respository by creating a clone from github into a local directory:

       > git clone https://github.com/esnet/esnet-smartnic-hw.git


2. Initialize all submodules within the esnet-smartnic-hw/ design directory:

       > cd esnet-smartnic-hw
       > git submodule update --init --recursive


3. Install the Xilinx Vivado tool suite and configure the runtime environment by executing the
   settings64.sh script located in the Vivado installation directory:
   
       > source /opt/Xilinx/Vivado/2021.2/settings64.sh

   where the Vivado installation directory is located at /opt/Xilinx/Vivado/2021.2/ in this example.


4. Build the `p4_simple` example design by executing the p4_simple application Makefile:

       > cd examples/p4_simple
       > make all

   This step creates an artifact zipfile with the default pathname:
   `artifacts/esnet-smartnic-<BUILD_NAME>/artifacts.<BUILD_NAME>.export_hwapi.manual.zip`

   This artifact zipfile contains all of the necessary h/w artifacts to integrate with the firmware.
   In addition to the bitfile, it includes firmware driver files, regmap yaml files, the source p4 file,
   and any wireshark .lua files.

   For more details about the `p4_simple` design, as well as simulating the P4 program,  refer to
   examples/p4_simple/README.md (https://github.com/esnet/esnet-smartnic-hw/examples/p4_simple#readme).




## Building a New P4 Application

The following steps can be taken by a new user to setup a local application design directory for building
the bitfile and artifacts for a custom P4-based SmartNIC application.

1. Install the esnet-smartnic-hw respository as in Step 1 of 'Getting Started' above.

   Or, alternatively, add to an existing git repository as a sub-module:

       > git submodule add https://github.com/esnet/esnet-smartnic-hw.git


2. Initialize all submodules within esnet-smartnic-hw/ as in Step 2 of 'Getting Started' above.


3. Install Vivado and configure runtime environment as in Step 3 of 'Getting Started' above.


4. Copy the example smartnic application Makefile into the local application design directory (and return
   to the local application design directory):

       > cp examples/p4_simple/Makefile ../
       > cd ../


5. Using a preferred editor, update the environment variable assignments in the application Makefile above,
   as required:

       export APP_DIR      := $(CURDIR)
       export SMARTNIC_DIR := $(APP_DIR)/esnet-smartnic-hw
       export APP_NAME     := $(shell basename $(APP_DIR) )
       export P4_FILE      := $(APP_DIR)/p4/$(APP_NAME).p4


6. Build the design by executing the application Makefile as in Step 4 of 'Getting Started' above.


7. To simulate the P4 program, refer to the README.md file provided in the esnet-smartnic-hw/examples/p4_simple/
   directory (https://github.com/esnet/esnet-smartnic-hw/examples/p4_simple/p4/sim#readme).



## P4 Program Requirements

### User Metadata

       struct short_metadata {
            bit<64> ingress_global_timestamp;  // 64b high-precision timestamp (in nanoseconds) for packet arrival time.
            bit<2>  dest_port;                 // 2b destination port (0:CMAC0, 1:CMAC1, 2:HOST0, 3:HOST1).
            bit<1>  truncate_enable;           // reserved (set to 0).
            bit<16> packet_length;             // reserved (set to 0).
            bit<1>  rss_override_enable;       // reserved (set to 0).
            bit<8>  rss_override;              // reserved (set to 0).
        }






**NOTE: See lower level README files for more details.**

# Known Issues

- None to date.
