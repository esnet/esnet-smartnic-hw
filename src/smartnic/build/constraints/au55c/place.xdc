# Smartnic platform
create_pblock       pblock_smartnic_platform
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/reset_inst"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/axis_switch_ingress"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/axis_switch_egress"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/g__fifo*"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/bypass_fifo*"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/*_drop_0"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/smartnic_axil_decoder_0"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/smartnic_reg_blk_0"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/reg_endian_check_0"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/smartnic_timestamp_0"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/axis_probe_app_to_core_*"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/axis_probe_core_to_app_*"]
resize_pblock       pblock_smartnic_platform -add {SLR1}

# Smartnic app core
create_pblock       pblock_smartnic_appcore
add_cells_to_pblock pblock_smartnic_appcore [get_cells -hierarchical -filter "NAME=~*/smartnic/smartnic_app*"]
add_cells_to_pblock pblock_smartnic_appcore [get_cells -hierarchical -filter "NAME=~*/smartnic/smartnic_to_app*"]
resize_pblock       pblock_smartnic_appcore -add {SLR2}

# Smartnic platform-to-app interfaces
create_pblock       pblock_smartnic_platform_to_app_if
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4l_reg_slice__core_to_app*slr_master*"]
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__core_to_app*slr_source*"]
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__app_to_core*slr_dest*"]
resize_pblock       pblock_smartnic_platform_to_app_if -add {CLOCKREGION_X2Y7:CLOCKREGION_X5Y7}
set_property IS_SOFT FALSE [get_pblocks pblock_smartnic_platform_to_app_if]

# Smartnic app-to-platform interfaces
create_pblock       pblock_smartnic_app_to_platform_if
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4l_reg_slice__core_to_app*slr_slave*"]
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__app_to_core*slr_source*"]
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__core_to_app*slr_dest*"]
resize_pblock       pblock_smartnic_app_to_platform_if -add {CLOCKREGION_X2Y8:CLOCKREGION_X5Y8}
set_property IS_SOFT FALSE [get_pblocks pblock_smartnic_app_to_platform_if]
