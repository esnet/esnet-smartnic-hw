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
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/smartnic_to_app_decoder_0"]
add_cells_to_pblock pblock_smartnic_platform [get_cells -hierarchical -filter "NAME=~*/smartnic/g__probe*"]
resize_pblock       pblock_smartnic_platform -add {SLR2}

# Smartnic app core
create_pblock       pblock_smartnic_appcore
add_cells_to_pblock pblock_smartnic_appcore [get_cells -hierarchical -filter "NAME=~*/smartnic/g__host_mux_app*"]
resize_pblock       pblock_smartnic_appcore -add {SLR1}

# Smartnic platform-to-app interfaces
create_pblock       pblock_smartnic_platform_to_app_if
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4l_reg_slice__core_to_app*slr_master*"]
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4l_reg_slice__core_to_p4*slr_master*"]
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__core_to_app*slr_source*"]
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__h2c_demux_out*slr_source*"]
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__c2h_mux_out*slr_dest*"]
resize_pblock       pblock_smartnic_platform_to_app_if -add {CLOCKREGION_X3Y8:CLOCKREGION_X6Y8}
set_property IS_SOFT FALSE [get_pblocks pblock_smartnic_platform_to_app_if]

# Smartnic app-to-platform interfaces
create_pblock       pblock_smartnic_app_to_platform_if
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4l_reg_slice__core_to_app*slr_slave*"]
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4l_reg_slice__core_to_p4*slr_slave*"]
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__c2h_mux_out*slr_source*"]
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__core_to_app*slr_dest*"]
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__h2c_demux_out*slr_dest*"]
resize_pblock       pblock_smartnic_app_to_platform_if -add {CLOCKREGION_X3Y7:CLOCKREGION_X6Y7}
set_property IS_SOFT FALSE [get_pblocks pblock_smartnic_app_to_platform_if]

# Smartnic platform-to-app interfaces
set_property USER_SLR_ASSIGNMENT SLR2 [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__to_qs_0*g__fwd*tx"]
set_property USER_SLR_ASSIGNMENT SLR2 [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__to_qs_0*g__rev*rx"]
set_property USER_SLR_ASSIGNMENT SLR2 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qs_to_phy_1*rx"]

# Smartnic app-to-platform interfaces
set_property USER_SLR_ASSIGNMENT SLR1 [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__to_qs_0*g__fwd*rx"]
set_property USER_SLR_ASSIGNMENT SLR1 [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__to_qs_0*g__rev*tx"]
set_property USER_SLR_ASSIGNMENT SLR1 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qs_to_phy_1*tx"]

# Smartnic app-to-qs interfaces
set_property USER_SLR_ASSIGNMENT SLR1 [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__to_qs_1*g__fwd*tx"]
set_property USER_SLR_ASSIGNMENT SLR1 [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__to_qs_1*g__rev*rx"]
set_property USER_SLR_ASSIGNMENT SLR1 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__app_to_qs*tx"]
set_property USER_SLR_ASSIGNMENT SLR1 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qs_to_phy_0*rx"]

# Smartnic qs-to-app interfaces
set_property USER_SLR_ASSIGNMENT SLR0 [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__to_qs_1*g__fwd*rx"]
set_property USER_SLR_ASSIGNMENT SLR0 [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__to_qs_1*g__rev*tx"]
set_property USER_SLR_ASSIGNMENT SLR0 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__app_to_qs*rx"]
set_property USER_SLR_ASSIGNMENT SLR0 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qs_to_phy_0*tx"]

# Smartnic egress qs
create_pblock       pblock_smartnic_egress_qs
add_cells_to_pblock pblock_smartnic_egress_qs [get_cells -hierarchical -filter "NAME=~*smartnic_egress_qs_0"]
set_property IS_SOFT FALSE [get_pblocks pblock_smartnic_egress_qs]
resize_pblock       pblock_smartnic_egress_qs -add {SLR0}
