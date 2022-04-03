# ESnet SmartNIC Hardware Design Repository

This repository contains the hardware design directory for the ESnet SmartNIC platform.

The ESnet SmartNIC Platform is based on the AMD (Xilinx) OpenNIC Shell, which provides
an FPGA-based NIC shell with 100Gbps Ethernet ports, and runs on the AMD (Xilinx) Alveo family
of hardware boards.  More information about the OpenNIC shell can be found at:
https://github.com/Xilinx/open-nic-shell

The ESnet SmartNIC platform implements a P4-programmable packet processing core within the
OpenNIC shell.  The P4 processor is implemented with the AMD (Xilinx) VitisNetP4 IP core.
More information about the VitisNetP4 core is available at the AMD (Xilinx) Vitis Networking
P4 Secure Site (once access priveleges are approved and granted).  Further questions can be
directed to vitisnetp4@xilinx.com.

The SmartNIC platform provides the necessary hardware datapath and control features
to operate the custom VitisNetP4 processor core.  

The `esnet-smartnic-hw` repository includes the RTL source files, verification test suites
and build scripts for compiling a user P4 file into a downloadable bitfile, as well as the
software artifacts necessary for seamless integration with the SmartNIC runtime firmware,
which is located in a companion github repository at:
https://github.com/esnet/esnet-smartnic-fw - COMING SOON!

The OpenNIC shell and SmartNIC designs are built with the AMD (Xilinx) Vivado software tool suite.
The current release supports development with Vivado version 2021.2.



## Repository Structure and Dependencies

The ESnet SmartNIC platform is comprised of a collection of separate modular components,
each maintained in their own git repository.

The platform includes the following repositories:

   - `OpenNIC shell` (https://github.com/Xilinx/open-nic-shell.git)  
     An FPGA-based NIC shell that runs on the AMD (Xilinx) Alveo family of hardware boards.  

   - `ESnet SmartNIC Hardware` (https://github.com/esnet/esnet-smartnic-hw.git)  
     Hardware design directory for the ESnet SmartNIC platform.

   - `ESnet SmartNIC Firmware` (https://github.com/esnet/esnet-smartnic-fw.git - COMING SOON!)  
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
  Contains the AMD (Xilinx) OpenNIC Shell repository (imported as a git submodule).  OpenNIC shell delivers an
  FPGA-based NIC shell with 100Gbps Ethernet ports, for use on the AMD (Xilinx) Alveo platform.

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
  OpenNIC shell Makefile.  Used to build the AMD (Xilinx) open-nic-shell for the target application.

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


3. Install the prerequisites required to run the esnet regio tools:

       > sudo apt install python3-yaml python3-jinja2 python3-click
       > pip3 install -r esnet-fpga-library/tools/regio/requirements.txt

   Note: The above instructions and more details about the `regio` tools can be found in the README file
   at: esnet-fpga-library/tools/regio/README.md


4. Install the AMD (Xilinx) Vivado tool suite, including the VitisNetP4 option, and configure the runtime
   environment by executing the settings64.sh script located in the Vivado installation directory:
   
       > source /opt/Xilinx/Vivado/2021.2/settings64.sh

   where the Vivado installation directory is located at /opt/Xilinx/Vivado/2021.2/ in this example.


5. Build the `p4_simple` example design by executing the p4_simple application Makefile:

       > cd examples/p4_simple
       > make

   This step creates an artifact zipfile with the default pathname:
   `artifacts/esnet-smartnic-<BUILD_NAME>/artifacts.<BUILD_NAME>.export_hwapi.manual.zip`

   This artifact zipfile contains all of the necessary h/w artifacts to integrate with the firmware.
   In addition to the bitfile, it includes firmware driver files, regmap yaml files, the source p4 file,
   and any wireshark .lua files.

   For more details about the `p4_simple` design, as well as simulating the P4 program,  refer to
   examples/p4_simple/README.md.




## Building a New P4 Application

The following steps can be taken by a new user to setup a local application design directory for building
the bitfile and artifacts for a custom P4-based SmartNIC application.

1. Install the esnet-smartnic-hw respository as in Step 1 of 'Getting Started' above.

   Or, alternatively, add to an existing git repository as a sub-module:

       > git submodule add https://github.com/esnet/esnet-smartnic-hw.git


2. Initialize all submodules within esnet-smartnic-hw/ as in Step 2 of 'Getting Started' above.


3. Install Vivado and configure runtime environment as in Step 3 of 'Getting Started' above.


4. Copy the example SmartNIC application Makefile into the local application design directory (and return
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
   directory.



## P4 Programming Requirements

The P4 processing core of the SmartNIC platform is implemented with the AMD (Xilinx) VitisNetP4 IP core.
In order to meet the requirements of the VitisNetP4 IP core and the SmartNIC platform, a new P4 program should
consider the following guidelines: 


##### 1. AMD (Xilinx) P4 Architecture.

The Vitis Networking P4 compiler supports a specific pipelined datapath architecture that is comprised of 3
customizable stages: A Parser Engine, followed by a Match-Action Engine, followed by a Deparser Engine.
User P4 files **MUST** be structured to comply with this processing architecture, and specify the custom operations
desired within each of these processing stages.

More details about the AMD (Xilinx) P4 architecture can be found in the *Vitis Networking P4 User Guide, UG1308
(v2021.2 Early Access) January 4, 2022*.



##### 2. Include files.

The P4 program **MUST** include the following AMD (Xilinx) VitisNetP4 include files:

      #include <core.p4>
      #include <xsa.p4>

These files capture built-in constructs and the standard definitions for the AMD (Xilinx) P4 architecture.
They are located in the Vivado installation directory at:
/opt/Xilinx/Vivado/2021.2/data/ip/xilinx/vitis_net_p4_v1_0/include/p4/


##### 3. Interfaces.

The P4 processing core supports 3 types of interfaces:

- *Packet Ports* are the primary interfaces responsible for moving packets in and out of the core, as well as
between engines.  Engines can only contain a single input packet port and a single output packet port.

- *Metadata Ports* carry sideband data related to a packet. Metadata can only correspond to a single packet
and is processed in parallel with the packet.  More on Metadata below.

- *Register IO Ports (axi4l)* are used to control the contents of the Look-up engines.


##### 4. Metadata Definitions.

The VitisNetP4 core supports both `Standard Metadata` (defined and set by the P4 core), and `User Metadata`
(defined and set by the SmartNIC platform).  Both types of metadata can be read and/or written by the P4
program.

For more details about the `Standard Metadata` definitions, see *Vitis Networking P4 User Guide, UG1308
(v2021.2 Early Access) January 4, 2022.*

In order for the compiled VitisNetP4 core to match the SmartNIC application interface, a user P4 program **MUST**
define the User Metadata structure as follows:

      struct short_metadata {
          bit<64> ingress_global_timestamp;  // 64b timestamp (in nanoseconds). Set at packet arrival time.
          bit<2>  dest_port;                 // 2b destination port (0:CMAC0, 1:CMAC1, 2:HOST0, 3:HOST1).
                                             // dest_port set to src_port by default.
          bit<1>  truncate_enable;           // reserved (tied to 0).
          bit<16> packet_length;             // reserved (tied to 0).
          bit<1>  rss_override_enable;       // reserved (tied to 0).
          bit<8>  rss_override;              // reserved (tied to 0).
      }


##### 5. Lookup Engines and Externs.

In order for the compiled VitisNetP4 core to match the SmartNIC application
interface, a user Program **MUST** have:

- One (or more) Look-up Engines.
- No HBM BCAMs.
- No Externs.

Support for these features may be added in a future release.


##### 6. Reference Documents.

The following reference documents can be accessed from the AMD (Xilinx) Vitis Networking P4 Secure Site
(once access priveleges are approved and granted):

- *Vitis Networking P4 Installation Guide and Release Notes, UG1307 (v2021.2 Early Access) January 4, 2022.*

- *Vitis Networking P4 User Guide, UG1308 (v2021.2 Early Access) January 4, 2022.*

- *Vitis Networking P4 Getting Started Guide, UG1373 (v2021.2 Early Access) January 4, 2022.*

Users may also be interested in the information at https://p4.org/.




# Known Issues

- None to date.


**NOTE: See lower level README files for more details.**

