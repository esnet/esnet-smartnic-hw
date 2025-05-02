ESnet Shell
------------------------------
The ESnet shell is a work in progress that aims to provide a sort of 'hardware abstraction layer' between the physical accelerator card and the hosted network application.

It divides the design into three components: the `hw` layer, the `shell` layer and the `core` layer. These are described in the sections below.

Hardware (`hw`) Layer
-----------------------------
This layer contains the card-specific logic and metadata, including physical pinout, logic to drive card-specific system controllers or GPIO, build/flash/JTAG details, customized timing constraints, etc.

Shell (`shell`) Layer
-----------------------------
This layer defines a common set of logic and IP for implementing a simple shell for network card implementations. This includes instantiations of MAC, PCIe, QDMA and system monitoring IP. It also includes a top level register decoder and register blocks for controlling shell-level functions.

The southbound interface (to the `hw`) is architecture/vendor-specific. A

Core (`core`) Layer
----------------------------
This layer contains all application-specific logic and IP. For a given hardware platform, the `hw` and `shell` content are common for all applications and shouldn't require changes from one to another.

NOTE: In the context of the ESnet SmartNIC, the SmartNIC platform itself would be an application and captured as a `core`. This should not be confused with an ESNet SmartNIC application, which is (yet) another layer accommodated by the SmartNIC design and outside the scope of the ESnet shell abstraction.

Design Objectives
----------------------------
The main objective of the ESnet shell is to provide an abstraction layer to simplify the portability of network applications between different hardware platforms.

This abstraction is meant to be tailored specifically for ESnet applications, providing for all necessary requirements but no more, and thus is expected to yield the best combination of performance and flexibility in that context. However, it is expected that this configuration will be suitable for other designers using similar platforms.

Ideally the development of this abstraction will improve portability not only between hardware platforms but also architectures, etc. Initially the shell is designed to support Alveo cards using the UltraScale+ architecture. It is unlikely that the shell can be ported to Versal directly given the significant architectural changes, but some of the abstractions (interfaces, etc.) are expected to remain useful.

Interfaces
-----------------------------
Interfaces have been captured to define the boundaries between the different layers.

An Alveo-specific `shell` and set of `hw` implementations (for AU280, AU55C and AU250) has been captured. These are in the `xilinx.alveo` library. A common `xilinx_alveo_hw_intf` has been captured to abstract the Alveo `hw` and `shell` layers.

The `shell_intf` defines the connectivity between the shell and the core. This consists of clocks, resets, AXI-S interfaces to/from MACs, AXI-S interfaces to/from QDMA, and an AXI-L control interface.

