# ESnet SmartNIC hardware design repository (esnet-smartnic-hw)

This repository contains the hardware design directory for the ESnet Smartnic platform.

It includes the RTL source files, verification test suites and build scripts for
compiling a user P4 file into downloadable bitfile.


## Getting Started

The directory structure for the ESnet Smartnic FPGA repository is captured and described in a section below.

It includes an example for a simple p4 application in the examples/p4_simple/ directory.

1. Clone `esnet-smartnic-hw` respository into the local application directory (or add as a sub-module).
2. Intialize all submodules within the esnet-smartnic-hw design directory.
3. Copy the smartnic application Makefile into the local application design directory.
4. Update environment variable assignements in Makefile, as required.
5. Run make to compile a bitfile.


## Directory Structure

```
esnet-smartnic-hw
├── cfg
├── docs
├── esnet-fpga-library -> esnet-fpga-library
├── esnet-open-nic -> esnet-open-nic
├── examples
│   ├── p4_simple
│   └── unsupported
│       ├── p2p
│       └── p4_example
│           ├── app_if
│           ├── artifacts
│           ├── build
│           ├── library
│           ├── Makefile
│           ├── p4
│           ├── reg
│           ├── rtl
│           ├── tb
│           ├── tests
│           ├── verif
│           └── xilinx_ip
├── Makefile
├── makefile.esnet
└── src
    ├── open-nic-plugin
    ├── p4_app
    └── smartnic_322mhz
```
