# Smartnic platform
create_pblock       pblock_smartnic_platform
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/smartnic_mux_inst"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/smartnic_demux_inst"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/smartnic_bypass_inst"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/smartnic_host_inst"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/g__fifo*"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/g__cmac_tid*"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/g__host_mux_core*"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/smartnic_axil_decoder_0"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/smartnic_cmac_decoder_0"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/smartnic_host_decoder_0"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/smartnic_bypass_decoder_0"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/axil_to_regs_cdc"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/smartnic_reg_blk_0"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/reg_endian_check_0"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/smartnic_timestamp_0"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/g__probe*"]
resize_pblock       pblock_smartnic_platform -add {SLR2}

# Smartnic app core
create_pblock       pblock_smartnic_appcore
add_cells_to_pblock pblock_smartnic_appcore [get_cells -hierarchical -filter "NAME=~*/smartnic/g__host_mux_app*"]
add_cells_to_pblock pblock_smartnic_appcore [get_cells -hierarchical -filter "NAME=~*/smartnic/smartnic_to_app*"]
resize_pblock       pblock_smartnic_appcore -add {SLR1}

# Smartnic platform-to-app interfaces
create_pblock       pblock_smartnic_platform_to_app_if
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4l_reg_slice__core_to_app*slr_master*"]
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__core_to_app*slr_source*"]
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__h2c_demux_out*slr_source*"]
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__app_to_core*slr_dest*"]
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__c2h_mux_out*slr_dest*"]
resize_pblock       pblock_smartnic_platform_to_app_if -add {CLOCKREGION_X3Y8:CLOCKREGION_X6Y8}
set_property IS_SOFT FALSE [get_pblocks pblock_smartnic_platform_to_app_if]

# Smartnic app-to-platform interfaces
create_pblock       pblock_smartnic_app_to_platform_if
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4l_reg_slice__core_to_app*slr_slave*"]
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__app_to_core*slr_source*"]
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__c2h_mux_out*slr_source*"]
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__core_to_app*slr_dest*"]
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__h2c_demux_out*slr_dest*"]
resize_pblock       pblock_smartnic_app_to_platform_if -add {CLOCKREGION_X3Y7:CLOCKREGION_X6Y7}
set_property IS_SOFT FALSE [get_pblocks pblock_smartnic_app_to_platform_if]

