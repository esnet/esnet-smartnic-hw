# Smartnic platform
create_pblock       pblock_smartnic_platform
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic_322mhz/reset_inst"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic_322mhz/axis_switch_ingress"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic_322mhz/axis_switch_egress"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic_322mhz/g__fifo*"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic_322mhz/axi4s_split_join*"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic_322mhz/bypass_fifo*"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic_322mhz/*_drop_0"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic_322mhz/smartnic_322mhz_axil_decoder_0"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic_322mhz/smartnic_322mhz_reg_blk_0"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic_322mhz/reg_endian_check_0"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic_322mhz/smartnic_322mhz_timestamp_0"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic_322mhz/axis_probe_app_to_core_*"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic_322mhz/axis_probe_core_to_app_*"]
resize_pblock       pblock_smartnic_platform -add {CLOCKREGION_X2Y6:CLOCKREGION_X5Y7}
#resize_pblock       pblock_smartnic_platform -add {SLR1}

# Smartnic app core
#create_pblock       pblock_smartnic_app
#add_cells_to_pblock pblock_smartnic_app [get_cells [list box_322mhz_inst/smartnic_322mhz/smartnic_322mhz_app]]
#add_cells_to_pblock pblock_smartnic_app [get_cells [list box_322mhz_inst/smartnic_322mhz/smartnic_322mhz_app_sdnet_decoder]]
#resize_pblock       pblock_smartnic_app -add {CLOCKREGION_X0Y8:CLOCKREGION_X7Y11}
#resize_pblock       pblock_smartnic_app -add {SLR2}

# SLR1->SRL2 crossing
create_pblock       pblock_slr_1_to_2
add_cells_to_pblock pblock_slr_1_to_2 [get_cells -hierarchical -filter "NAME=~*axi4l_reg_slice__core_to_app*slr_master*"]
add_cells_to_pblock pblock_slr_1_to_2 [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__core_to_app*slr_source*"]
add_cells_to_pblock pblock_slr_1_to_2 [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__app_to_core*slr_dest*"]
resize_pblock       pblock_slr_1_to_2 -add {CLOCKREGION_X2Y7:CLOCKREGION_X5Y7}
set_property IS_SOFT FALSE [get_pblocks pblock_slr_1_to_2]

# SLR2->SRL1 crossing
create_pblock       pblock_slr_2_to_1
add_cells_to_pblock pblock_slr_2_to_1 [get_cells -hierarchical -filter "NAME=~*axi4l_reg_slice__core_to_app*slr_slave*"]
add_cells_to_pblock pblock_slr_2_to_1 [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__app_to_core*slr_source*"]
add_cells_to_pblock pblock_slr_2_to_1 [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__core_to_app*slr_dest*"]
resize_pblock       pblock_slr_2_to_1 -add {CLOCKREGION_X2Y8:CLOCKREGION_X5Y8}
set_property IS_SOFT FALSE [get_pblocks pblock_slr_2_to_1]
