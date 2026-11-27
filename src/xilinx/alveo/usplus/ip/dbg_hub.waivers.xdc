# Validation-only waiver; load with read_xdc -ref dbg_hub.
# XSDB's command read/write FIFOs use vendor FIFO Generator dual-clock RAM.
# Their pointer protocol protects RAM payload capture; the corresponding
# write-clock -> read-register paths are already false-pathed in the netlist.
# Restrict the waiver to the command FIFO RAM/output-register paths inside
# this IP. Other debug-hub controls and all application FIFOs remain visible.
create_waiver -scoped -type CDC -id CDC-15 -user esnet \
    -description {XSDB debug-hub vendor FIFO Generator command FIFO RAM payload crossing} \
    -from [get_pins -hierarchical -filter { \
        NAME =~ *U_CMD6_RD/U_RD_FIFO/*inst_fifo_gen/*gdm.dm_gen.dm/RAM_reg*/CLK || \
        NAME =~ *U_CMD6_WR/U_WR_FIFO/*inst_fifo_gen/*gdm.dm_gen.dm/RAM_reg*/CLK \
    }] \
    -to [get_pins -hierarchical -filter { \
        NAME =~ *U_CMD6_RD/U_RD_FIFO/*inst_fifo_gen/*gdm.dm_gen.dm/gpr1.dout_i_reg*/D || \
        NAME =~ *U_CMD6_WR/U_WR_FIFO/*inst_fifo_gen/*gdm.dm_gen.dm/gpr1.dout_i_reg*/D \
    }]
