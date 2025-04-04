## Copyright Notice

ESnet SmartNIC Copyright (c) 2024, The Regents of the University of
California, through Lawrence Berkeley National Laboratory (subject to
receipt of any required approvals from the U.S. Dept. of Energy),
12574861 Canada Inc., Malleable Networks Inc., and Apical Networks, Inc.
All rights reserved.

If you have questions about your rights to use or distribute this software,
please contact Berkeley Lab's Intellectual Property Office at
IPO@lbl.gov.

NOTICE.  This Software was developed under funding from the U.S. Department
of Energy and the U.S. Government consequently retains certain rights.  As
such, the U.S. Government has been granted for itself and others acting on
its behalf a paid-up, nonexclusive, irrevocable, worldwide license in the
Software to reproduce, distribute copies to the public, prepare derivative
works, and perform publicly and display publicly, and to permit others to do so.



## ESnet SmartNIC Hardware Design Repository

This repository contains the hardware design directory for the ESnet SmartNIC platform.

The ESnet SmartNIC Platform is based on the AMD (Xilinx) OpenNIC Shell, which provides
an FPGA-based NIC shell with 100Gbps Ethernet ports, and runs on the AMD (Xilinx) Alveo family
of hardware boards.  More information about the OpenNIC shell can be found at:
https://github.com/esnet/open-nic-shell

The ESnet SmartNIC platform implements a P4-programmable packet processing core within the
OpenNIC shell.  The P4 processing is implemented with the AMD (Xilinx) VitisNetP4 IP core.
More information about the VitisNetP4 core is available at
https://www.xilinx.com/products/intellectual-property/ef-di-vitisnetp4.html

The SmartNIC platform provides the necessary hardware datapath and control features
to operate the custom VitisNetP4 processor.  The `esnet-smartnic-hw` repository includes the
RTL source files, verification test suites and build scripts for compiling a user P4 file
into a downloadable bitfile, as well as the software artifacts necessary for seamless integration
with the SmartNIC runtime firmware, which is located in a companion github repository at:
https://github.com/esnet/esnet-smartnic-fw

The OpenNIC shell and SmartNIC designs are built with the AMD (Xilinx) Vivado software tool
suite.  The current release supports development with Vivado version 2023.2.2, running on
Ubuntu 20.04 LTS.  Furthermore, while the ESnet SmartNIC Platform, the AMD (Xilinx) OpenNIC
shell and the AMD (Xilinx) Vivado tool suite are all public and openly available, note
that the AMD (Xilinx) VitisNetP4 IP core is a commercially licensed feature that requires a
site-specific license file.

The ESnet SmartNIC platform is made available in the hope that it will
be useful to the networking community. Users should note that it is
made available on an "as-is" basis, and should not expect any
technical support or other assistance with building or using this
software. For more information, please refer to the LICENSE.md file in
each of the source code repositories.

The developers of the ESnet SmartNIC platform can be reached by email
at smartnic@es.net.

## Repository Structure and Dependencies

The ESnet SmartNIC platform is comprised of a collection of separate modular components,
each maintained in their own git repository.

The platform includes the following repositories:

   - `OpenNIC shell` (https://github.com/esnet/open-nic-shell.git)
     An FPGA-based NIC shell that runs on the AMD (Xilinx) Alveo
     family of hardware boards.  This repository is a fork of a
     Xilinx-provided repository (https://github.com/Xilinx/open-nic-shell.git).
     This repository also includes customizations for the ESnet SmartNIC platform.

   - `ESnet SmartNIC Hardware` (https://github.com/esnet/esnet-smartnic-hw.git)
     Hardware design directory for the ESnet SmartNIC platform.

   - `ESnet SmartNIC Firmware` (https://github.com/esnet/esnet-smartnic-fw.git)
     Firmware design directory for the ESnet SmartNIC platform.

   - `ESnet FPGA library` (https://github.com/esnet/esnet-fpga-library.git)
     General-purpose components and infrastructure for a structured FPGA design methodology.

   - `SVunit` (https://github.com/svunit/svunit.git)
     An open-source framework for FPGA System Verilog
     verification. SVunit is used by the SmartNIC platform, but is
     neither maintained nor distributed by ESnet.

   - `ESnet Regio` (https://github.com/esnet/regio.git)
     Automation tools for the implementation of FPGA register map logic and software code.


All dependent repositories are instantiated in the parent repository as a submodule, as
depicted below:

```
esnet-smartnic-hw/ (parent repository)
├── esnet-fpga-library/ (submodule)
│   └── tools/
│       ├── regio/ (submodule)
│       └── svunit/ (submodule)
└── open-nic-shell/ (submodule)

esnet-smartnic-fw/ (parent repository)
```



## Directory Structure

The directory structure for the ESnet SmartNIC hardware design repository is captured and described below.

```
esnet-smartnic-hw/
├── cfg/
├── config.mk
├── docs/
├── esnet-fpga-library/
├── examples/
├── LICENSE.md
├── Makefile
├── makefile.esnet
├── open-nic-shell/
├── paths.mk
├── README.md
├── scripts/
├── src/
└── test/

cfg/
  Contains global configuration files for the SmartNIC project.

config.mk
  Sets environment variables for the SmartNIC project.

docs/
  Contains documentation files for the SmartNIC platform.

esnet-fpga-library/
  Contains the ESnet FPGA Design Library (imported as a git submodule).
  This library contains general-purpose FPGA design content.

examples/
  Contains SmartNIC application design exaples.  A new application directory can be started
  by copying one of the provided example directories, or by modeling portions of the example
  directory structure.

LICENSE.md
  Contains the licensing terms and copyright notice for this repository.

Makefile
  SmartNIC platform Makefile.  Used to build the FPGA bitfile for the target application,
  as well as generate all artifacts necessary for firmware integration on the hardware platform.

makefile.esnet
  OpenNIC shell Makefile.
  Used to build the AMD (Xilinx) open-nic-shell for the target application.

open-nic_shell/
  Contains the AMD (Xilinx) OpenNIC Shell repository (imported as a git submodule).
  OpenNIC shell delivers an FPGA-based NIC shell with 100Gbps Ethernet ports,
  for use on the AMD (Xilinx) Alveo platform.

paths.mk
  Describes paths to resources provided by the SmartNIC project.

README.md
  This README file.

scripts/
  Contains SmartNIC platform scripts, for application configuration.

src/
  Contains RTL source and verification code for SmartNIC platform FPGA design components,
  captured in System Verilog.

test/
  Contains Robot Framework test suite files and Python library code for SmartNIC platform FPGA
  functional testing on hardware. Tests are executed within containers built by esnet-smartnic-fw.
```


## Getting Started

### Installing the SmartNIC Hardware Design Repository

The following steps guide a new user through the installation of the
SmartNIC Hardware Design Repository, beginning with a
suitably-configured host running Ubuntu 20.04 LTS Linux.

1. Install the esnet-smartnic-hw respository by creating a clone from github into a local directory:

       > git clone https://github.com/esnet/esnet-smartnic-hw.git


2. Initialize all submodules within the esnet-smartnic-hw/ design directory:

       > cd esnet-smartnic-hw
       > git submodule update --init --recursive


3. Install the prerequisites required to run the esnet regio tools:

       > sudo apt install python3-yaml python3-jinja2 python3-click
       > pip3 install -r esnet-fpga-library/tools/regio/requirements.txt

   Note: The above instructions and more details about the `regio` tools can be found in the README file
   at: `esnet-fpga-library/tools/regio/README.md`


### Installing and Configuring the Vivado Runtime Environment

1. Install the AMD (Xilinx) Vivado tool suite (version 2023.2.2), including the VitisNetP4 option.

2. Configure the runtime environment by executing the settings64.sh script located in the Vivado
installation directory:

       > source /tools/Xilinx/Vivado/2023.2/settings64.sh

   where the Vivado installation directory is located at /tools/Xilinx/Vivado/2023.2/ in this example.

3. Set the XILINXD_LICENSE_FILE environment variable accordingly to resolve the site-specific license for
the AMD (Xilinx) VitisNetp4 IP core.  This can be done with a `.flexlmrc` file in the users home directory,
or in a BASH script file (such as a `.bashrc` in the users home directory).  The example BASH shell
command is:

       > export XILINXD_LICENSE_FILE=<filename>

### Building the SmartNIC p4_only Example Design

Build the `p4_only` example design by executing the p4_only application Makefile.
From the esnet-smartnic-hw directory:

       > cd examples/p4_only
       > make

   Upon completion, the above step creates an artifact zipfile with the default pathname:
   `artifacts/<BUILD_NAME>/artifacts.<BOARD>.<BUILD_NAME>.0.zip`

   This artifact zipfile contains all of the necessary h/w artifacts to integrate with the firmware.
   In addition to the bitfile, it includes firmware driver files, regmap yaml files, the source p4 file,
   and any wireshark .lua files.

   For more details about the `p4_only` design, as well as simulating the P4 program,  refer to the
   [p4_only README](examples/p4_only/README.md).


### Building a New P4 Application

The following steps can be taken by a new user to setup a local application design directory for building
the bitfile and artifacts for a custom P4-based SmartNIC application.

1. Install the esnet-smartnic-hw respository (as described above).

   Or, alternatively, add the esnet-smartnic-hw respository to an existing git repository as a sub-module:

       > git submodule add https://github.com/esnet/esnet-smartnic-hw.git

2. Initialize all submodules within the esnet-smartnic-hw/ design directory:

       > cd esnet-smartnic-hw
       > git submodule update --init --recursive

3. Install Vivado and configure the runtime environment (as described above).

4. Return  to the local application design directory and then copy the example SmartNIC application Makefile and p4/ sub-directory into the local application design directory:

       > cd ../
       > cp esnet-smartnic-hw/examples/p4_only/Makefile ./
       > cp -r esnet-smartnic-hw/examples/p4_only/p4 ./

5. Using a preferred editor, edit the copied Makefile to update the SMARTNIC_DIR environment variable assignment as follows:

       #SMARTNIC_DIR := ../..
       SMARTNIC_DIR := $(CURDIR)/esnet-smartnic-hw

6. Copy the application p4 file to the following location and filename:

       > cp <p4_filename> p4/`basename $PWD`.p4

     Note: By default, the SmartNIC scripts take the basename of the application design directory to be the name of the application, as well as its associated filenames.

7. Build the design by executing the copied application Makefile:

       > make

8. To simulate the P4 program, refer to the [p4/sim README](examples/p4_only/p4/sim/README.md).


### Ingress and Egress processing functions

This release of the ESnet SmartNIC architecture is presently structured to accommodate optionally capturing separate
ingress and egress processing functions.  It includes separate P4 processors (for ingress and egress P4 programs),
as well as optionally customizable ingress and egress RTL datapath functions.  See block diagram at `docs/smartnic_app.svg`.

The P4 files for building these separate processors (smartnic_app_igr_p4 and smartnic_app_egr_p4) are specified
in the root-level application Makefile by the P4_IGR_FILE and P4_EGR_FILE variables.  Applications that implement
only a single P4 program should specify only the P4_IGR_FILE variable and leave the P4_EGR_FILE variable unspecified.
If the P4_EGR_FILE variable is unspecified, pass-through logic is implemented instead of an egress processor.

The current SmartNIC release supports backwards compatibility for legacy SmartNIC applications (which implement only
a single P4 processor) by automatically mapping the P4 program onto the ingress processor and implementing pass-through
logic in place of the egress P4 processor.  The optionally cumstomizable ingress and egress RTL datapath functions also
implement pass-through logic by default.

Support for multi-processor application design is limited in the current release.  See the `p4_multi_proc` example design
for reference.


### User Extern Function Support

The ESnet SmartNIC Platform optionally supports the integration of custom user extern function(s) that
complement an application P4 program.  For such a design, in addition to the application P4 program, a
user must provide a custom C++ (.cpp) model of the extern function(s) for behavioural simulation, as well
as the custom system verilog RTL code that implements the function for synthesis (and RTL simulation,
if desired).

For an extern function that is associated with the *ingress* P4 processor:
- The name of the extern top-level module MUST be `vitisnetp4_igr_extern`
- The extern RTL code MUST be located in a filename with the path `src/vitisnetp4_igr/rtl/src/vitisnetp4_igr_extern.sv`
- The .cpp model MUST be located in a filename with the path `p4/sim/user_externs/vitisnetp4_igr_extern.cpp`
- Subdirectories and files necessary to support the automated build and simulation scripts MUST also be included and
structured as shown.

See the `p4_with_extern` example design for reference.


#### Building a New P4-with-extern Application

The following steps can be taken by a new user to setup a local application design directory for building
the bitfile and artifacts for a custom P4-based SmartNIC application that includes a custom user extern function.

1. Install the esnet-smartnic-hw respository (as described above).

2. Initialize all submodules within the esnet-smartnic-hw/ design directory:

       > cd esnet-smartnic-hw
       > git submodule update --init --recursive

3. Beside the esnet-smartnic-hw/ directory, create a new application design directory based on a copy of the `p4_with_extern`
example design:

       > cd ../
       > cp -r esnet-smartnic-hw/examples/p4_with_extern <APP_NAME>
       > cd  <APP_NAME>

4. Using a preferred editor, edit the application Makefile to update the SMARTNIC_DIR environment variable assignment as follows:

       SMARTNIC_DIR := ../esnet-smartnic-hw

5. Copy the application p4 file to the following location and filename:

       > cp <p4_filename> p4/`basename $PWD`.p4

   Note: By default, the SmartNIC scripts take the basename of the application design directory to be the name of the application.  The application name is used in associated filenames as well.

6. Copy the application extern system verilog file to the following location and filename:

       > cp <extern_filename> src/vitisnetp4_igr/rtl/src/vitisnetp4_igr_extern.sv

7. Install Vivado and configure the runtime environment (as described above).

8. Build the design by executing the copied application Makefile:

       > make

9. To simulate the P4 program, copy the extern cpp file to the following location and filename:

       > cp <cpp_filename> p4/sim/user_externs/vitisnetp4_igr_extern.cpp

    Refer to the [p4/sim README](examples/p4_with_extern/p4/sim/README.md).


## P4 Programming Requirements

The P4 processing core of the SmartNIC platform is implemented with the AMD (Xilinx) VitisNetP4 IP core.
In order to meet the requirements of the VitisNetP4 IP core and the SmartNIC platform, a new P4 program should
consider the following guidelines.


### AMD (Xilinx) P4 Architecture:

The Vitis Networking P4 compiler supports a specific pipelined datapath architecture that is comprised of 3
customizable stages: A Parser Engine, followed by a Match-Action Engine, followed by a Deparser Engine.
User P4 files **MUST** be structured to comply with this processing architecture, and specify the custom operations
desired within each of these processing stages.

More details about the AMD (Xilinx) P4 architecture can be found in the *Vitis Networking P4 User Guide, UG1308
(v2023.2) Oct 18, 2023*.


### Include files:

The P4 program **MUST** include the following AMD (Xilinx) VitisNetP4 include files:

      #include <core.p4>
      #include <xsa.p4>

These files capture built-in constructs and the standard definitions for the AMD (Xilinx) P4 architecture.
They are located in the Vivado installation directory at:
`$XILINX_VIVADO/data/ip/xilinx/vitis_net_p4_v2_0/include/p4/`


### Interfaces:

The P4 processing core supports 3 types of interfaces:

- *Packet Ports* are the primary interfaces responsible for moving packets in and out of the core, as well as
between engines.  Engines can only contain a single input packet port and a single output packet port.

- *Metadata Ports* carry sideband data related to a packet. Metadata can only correspond to a single packet
and is processed in parallel with the packet.  More on Metadata below.

- *Register IO Ports (axi4l)* are used to control the contents of the Look-up engines.


### Metadata Definitions:

The VitisNetP4 core supports both `Standard Metadata` (defined and set by the P4 core), and `User Metadata`
(defined and set by the SmartNIC platform).  Both types of metadata can be read and/or written by the P4
program.

For more details about the `Standard Metadata` definitions, see *Vitis Networking P4 User Guide, UG1308
(v2023.2) Oct 18, 2023*.

In order for the compiled VitisNetP4 core to match the SmartNIC application interface, a user P4 program **MUST**
define the User Metadata structure as follows:

    struct smartnic_metadata {
        bit<64> timestamp_ns;    // 64b timestamp (in nanoseconds). Set at packet arrival time.
        bit<16> pid;             // 16b packet id used by platform (READ ONLY - DO NOT EDIT).
        bit<4>  ingress_port;    // bit<0>   port_num (0:P0, 1:P1).
                                 // bit<3:1> port_typ (0:PHY, 1:PF, 2:VF, 3:APP, 4-7:reserved).
        bit<4>  egress_port;     // bit<0>   port_num (0:P0, 1:P1).
                                 // bit<3:1> port_typ (0:PHY, 1:PF, 2:VF, 3:APP, 4-6:reserved, 7:UNSET).
        bit<1>  truncate_enable; // 1b set to 1 to enable truncation of egress packet to 'truncate_length'.
        bit<16> truncate_length; // 16b set to desired length of egress packet (used when 'truncate_enable' == 1).
        bit<1>  rss_enable;      // 1b set to 1 to override open-nic-shell rss hash result with 'rss_entropy' value.
        bit<12> rss_entropy;     // 12b set to rss_entropy hash value (used for open-nic-shell qdma qid selection).
        bit<4>  drop_reason;     // reserved (tied to 0).
        bit<32> scratch;         // reserved (tied to 0).
    }

### Lookup Engines:

In order for the compiled VitisNetP4 core to match the SmartNIC application
interface, a user Program **MUST** have:

- One (or more) Look-up Engines.
- No HBM BCAMs.

Support for these features may be added in a future release.


### Upgrading a P4 application from a legacy version to this release

This release of the ESnet SmartNIC Platform includes significant changes to the SmartNIC FPGA architecture.  See block
diagrams below:

![SmartNIC Top Level Block Diagram](docs/smartnic.svg)

The new architecture incorporates 2 optional P4-programmable blocks (*smartnic_app_igr_p4, smartnic_app_egr_p4*) and
4 optional RTL-programmable blocks (*vitisnetp4_igr_extern, vitisnetp4_egr_extern, smartnic_app_igr, smatnic_app_egr*).
It also expands the number of datapath interfaces used to stream packet traffic into and out of these functional blocks
by leveraging PCIe SR-IOV viritual functions (VFs).  See block diagram below.

![SmartNIC Application Block Diagram](docs/smartnic_app.svg)

It should be noted that while this new datapath architecture is designed to connect the new datapath interfaces using separate
virtual functions (VFs) of an SR-IOV-enabled PCIe endpoint, this first release of the platform does NOT include an SRIOV-enabled
PCIe endpoint. The addition of PCIe SR-IOV support is planned for an upcoming release. In the interim, HOST traffic may be
directed to a single HOST interface by programming the ingress and egress queue configuration accordingly.

By consequence of the new datapath updates, changes have been made to the SmartNIC configuration and status registers
i.e. obsolete registers have been removed, and new registers have been added, as necessary.  The programming for this updated
register set has been reflected in the SmartNIC platform firmware (esnet-smartnic-fw).

Consistent with legacy releases of the SmartNIC platform, this version supports a single P4-processor application, with
optional support for an RTL extern function, and optional RTL simulation support using the AMD example design. Other possible
work flows and application examples are included in the release for reference, but are presently 'unsupported'.
The supported 'p4_only' and 'p4_with_extern' examples have documentation and instructions (READMEs), as well as limited
assistance from ESnet for questions and unexpected problems.  The 'unsupported' examples and work flows do NOT include README
instructions, or ESnet support.

The new datapath changes have been implemented to be backward compatible. Legacy single P4-processor applications will
automatically instantiate 'passthru' versions of the new optionally programmable functions. The directory structure and automation
scripts are designed to support legacy applications with minimal changes required to the source files and directories.

For 'p4_only' applications, simply update the 'esnet-smartnic-hw' submodule and adapt the p4 program to the updated 'ingress_port'
and 'egress_port' metadata definitions.

For 'p4_with_extern' applications, create a new design directory by following the instructions above from the section
'Building a New P4-with-extern Application', and adapt the p4 program to the updated 'ingress_port' and 'egress_port' metadata
definitions.



### Reference Documents:

The following reference documents can be accessed from the AMD (Xilinx) Vitis Networking P4 Secure Site
(once access priveleges are approved and granted):

- *Vitis Networking P4 Installation Guide and Release Notes, UG1307 (v2023.2) Oct 18, 2023*.

- *Vitis Networking P4 User Guide, UG1308 (v2023.2) Oct 18, 2023*.

- *Vitis Networking P4 Getting Started Guide, UG1373 (v2023.2) Oct 18, 2023*.

Users may also be interested in the information at https://p4.org/.



## Known Issues

- None to date.
