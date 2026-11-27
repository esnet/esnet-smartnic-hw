# Xilinx QSPI

`xilinx_qspi` connects a 32-bit `axi4l_intf` peripheral to the
`xilinx_axi_quad_spi` IP in legacy, non-XIP mode. The IP uses quad-mode
Micron command support,
256-entry FIFOs, one slave-select, and an internal STARTUP primitive to
access the dedicated configuration-flash pins. No external SPI ports or
configuration-pin LOC constraints are needed. The optional `irq` output is
active high and synchronous to the AXI-Lite clock.

Both IP clocks use `axil_if.aclk`. With the configured frequency ratio of
two, SPI SCK is half the AXI-Lite clock frequency. Select that clock for
the flash commands and board timing requirements; use an AXI-Lite clock
crossing at the integration boundary if necessary. For example, a 50 MHz
AXI-Lite clock produces 25 MHz SCK. The FPGA's `CONFIGRATE` setting controls
configuration loading and does not set this runtime SPI frequency.

The wrapper passes write strobes and the low seven address bits through
to the IP's 128-byte register space. Software controls transfer enable,
slave selection, flash opcodes, and address bytes through these registers.
The native IP ignores write strobes: software must use full 32-bit register
writes. Its write address and data valid signals must overlap; AXI-Lite
masters must hold each valid signal until its handshake completes.
See [PG153: Register Space](https://docs.amd.com/r/en-US/pg153-axi-quad-spi/Register-Space-Legacy-and-Enhanced-Non-XIP-Mode).
The `C_SPI_MEM_ADDR_BITS` parameter applies to XIP mode; it does not select
the address bytes supplied by software in legacy mode.

Integration must supply flash timing constraints for the generated SCK
and STARTUP data paths, using the flash data sheet and board trace delays.
The IP's internal constraints do not replace these external timing
requirements. See [PG153: Constraining the IP](https://docs.amd.com/r/en-US/pg153-axi-quad-spi/Constraining-the-IP).
Micron command decoding assumes default VCR/NVCR dummy-cycle settings;
see [PG153: Micron Memory](https://docs.amd.com/r/en-US/pg153-axi-quad-spi/Micron-Memory).

The UltraScale+ Alveo shell runs this component from a 50 MHz clock divided
from its free-running 100 MHz system clock, producing 25 MHz SCK. The common
AXI-Lite CDC carries register transactions and synchronizes reset from the
shell bus. Software polls the existing QSPI window at BAR2 + `0x220000`;
the interrupt output is unused.

The shell's `qspi.xdc` constrains the STARTUP flash clock, data, and select
paths using conservative Micron STR timing limits. It budgets each board
clock/data/select path independently at 0–2 ns propagation. Those bounds
are assumptions to validate against the board routing, rather than measured
trace delays. Runtime SPI timing is independent of the boot configuration
settings in each board's `general.xdc`.

Transmit setup is checked over the half-SCK period from a falling-edge data
launch to the following rising-edge capture. The hold check uses the next
falling-edge change; the intervening reference-clock edge does not update
the transmit data. The receive path uses the IP's documented two-cycle
capture relationship.
