ESnet Shell
------------------------------
The ESnet shell provides a hardware abstraction layer between the physical accelerator card and the hosted network application.

It divides the design into three components: the `hw` layer, the `shell` layer and the `core` layer. These are described in the sections below.

Hardware (`hw`) Layer
-----------------------------
This layer contains the card-specific logic and metadata, including physical pinout, logic to drive card-specific system controllers or GPIO, build/flash/JTAG details, customized timing constraints, etc.

Shell (`shell`) Layer
-----------------------------
This layer defines a common set of logic and IP for implementing a simple shell for network card implementations. This includes instantiations of MAC, PCIe, QDMA and system monitoring IP. It also includes a top level register decoder and register blocks for controlling shell-level functions.

The southbound interface (to the `hw`) is architecture/vendor-specific. A common `xilinx_alveo_hw_intf` has been captured to abstract the Alveo `hw` and `shell` layers. For Versal AVED platforms, the `xilinx_aved_app_intf` serves the equivalent role.

Core (`core`) Layer
----------------------------
This layer contains all application-specific logic and IP. For a given hardware platform, the `hw` and `shell` content are common for all applications and shouldn't require changes from one to another.

NOTE: In the context of the ESnet SmartNIC, the SmartNIC platform itself would be an application and captured as a `core`. This should not be confused with an ESNet SmartNIC application, which is (yet) another layer accommodated by the SmartNIC design and outside the scope of the ESnet shell abstraction.

Design Objectives
----------------------------
The main objective of the ESnet shell is to provide an abstraction layer to simplify the portability of network applications between different hardware platforms.

This abstraction is meant to be tailored specifically for ESnet applications, providing for all necessary requirements but no more, and thus is expected to yield the best combination of performance and flexibility in that context. However, it is expected that this configuration will be suitable for other designers using similar platforms.

The shell supports both Xilinx Alveo cards (UltraScale+ architecture, with CMAC for 100G network connectivity) and AMD Versal AVED platforms (with DCMAC for 400G network connectivity). The `shell_intf` parameterization allows the same `core` module to be instantiated unchanged on both platforms, with port count and data widths resolved at elaboration time.

Interfaces
-----------------------------
Interfaces have been captured to define the boundaries between the different layers.

An Alveo-specific `shell` and set of `hw` implementations (for AU280, AU55C and AU250) has been captured. These are in the `xilinx.alveo` library. A common `xilinx_alveo_hw_intf` has been captured to abstract the Alveo `hw` and `shell` layers.

The `shell_intf` defines the connectivity between the shell and the core. It is a **parameterized flat SV interface** — all signals are plain `logic` with no embedded interface instances, ensuring compatibility with Vivado OOC synthesis and DFX flows. Parameters control the number of network ports (`NUM_PORTS`), network port data width (`PORT_DATA_BYTE_WID`), DMA streaming data width (`DMA_ST_DATA_BYTE_WID`), DMA queue count (`DMA_ST_QUEUES`), and AXI-L address width (`AXIL_ADDR_WID`). Default values are defined in the interface itself; each platform top-level overrides them at instantiation.

The `shell_intf` carries:
- Clock and reset signals (driven by the shell, consumed by the core)
- AXI-L management interface (shell drives controller-originated signals toward core; core drives peripheral responses)
- AXI-S network port interfaces — `port_rx` (ingress) and `port_tx` (egress) — arrayed by `NUM_PORTS`
- AXI-S DMA streaming interfaces — `h2c` (host-to-core) and `c2h` (core-to-host)

Adapter Modules
-----------------------------
Two adapter modules bridge between the `shell_intf` flat signals and the SV interface types used internally:

- `shell_adapter__shell`: used by shell-side modules (`xilinx_alveo_shell`, `xilinx_aved_shell_adapter`). Takes a `shell_intf.shell` modport and drives/reads `axi4l_intf` and `axi4s_intf` instances.
- `shell_adapter__core`: used by the `core` module. Takes a `shell_intf.core` modport and produces `axi4l_intf` and `axi4s_intf` instances for use by application logic.

Both adapters derive all sizing parameters (data widths, address width) from the connected `shell_intf` instance rather than from `shell_pkg`, so they remain correct regardless of which platform parameters are in effect.
