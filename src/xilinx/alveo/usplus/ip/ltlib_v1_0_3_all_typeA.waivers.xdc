# ILA 6.2 type-A match-logic configuration transfer. Load with read_xdc -ref
# ltlib_v1_0_3_all_typeA so each source/destination pair stays within one
# component instance, including parameterized and uniquified references.
# ila.xdc actively false-paths u_srl_drive to the nested output register.
# The nested register can be absent after optimization. Probe inputs and
# crossings between component instances remain subject to validation.
create_waiver -quiet -scoped -type CDC -id CDC-10 -user esnet \
    -description {ILA reviewed match-logic configuration transfer to nested output register} \
    -from [get_pins -quiet -hierarchical -filter {NAME =~ *u_srl_drive/CLK}] \
    -to [get_pins -quiet -hierarchical -filter {NAME =~ *I_WHOLE_SLICE.G_SLICE_IDX*.U_ALL_SRL_SLICE/I_IS_TERMINATION_SLICE_W_OUTPUT_REG.DOUT_O_reg/D}]
