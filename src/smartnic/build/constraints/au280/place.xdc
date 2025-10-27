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
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__core_to_app*g__fwd*tx"]
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__core_to_app*g__rev*rx"]
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__core_to_p4*g__fwd*tx"]
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__core_to_p4*g__rev*rx"]
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__core_to_app*tx"]
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__h2c_demux_out*tx"]
add_cells_to_pblock pblock_smartnic_platform_to_app_if [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__c2h_mux_out*rx"]
resize_pblock       pblock_smartnic_platform_to_app_if -add {CLOCKREGION_X3Y8:CLOCKREGION_X6Y8}
set_property IS_SOFT FALSE [get_pblocks pblock_smartnic_platform_to_app_if]

# Smartnic app-to-platform interfaces
create_pblock       pblock_smartnic_app_to_platform_if
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__core_to_app*g__fwd*rx"]
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__core_to_app*g__rev*tx"]
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__core_to_p4*g__fwd*rx"]
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__core_to_p4*g__rev*tx"]
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__core_to_app*rx"]
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__h2c_demux_out*rx"]
add_cells_to_pblock pblock_smartnic_app_to_platform_if [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__c2h_mux_out*tx"]
resize_pblock       pblock_smartnic_app_to_platform_if -add {CLOCKREGION_X3Y7:CLOCKREGION_X6Y7}
set_property IS_SOFT FALSE [get_pblocks pblock_smartnic_app_to_platform_if]


# Smartnic SLR2-to-SLR1-to-SLR0 pipelining
create_pblock        pblock_slr_2_to_1
add_cells_to_pblock  pblock_slr_2_to_1 [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__to_qs_0*g__fwd*tx"]
add_cells_to_pblock  pblock_slr_2_to_1 [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__to_qs_0*g__rev*rx"]
add_cells_to_pblock  pblock_slr_2_to_1 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qs_to_phy_1*rx"]
resize_pblock        pblock_slr_2_to_1 -add {CLOCKREGION_X0Y8:CLOCKREGION_X3Y9}
set_property IS_SOFT FALSE [get_pblocks pblock_slr_2_to_1]

create_pblock        pblock_slr_1_to_2
add_cells_to_pblock  pblock_slr_1_to_2 [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__to_qs_0*g__fwd*rx"]
add_cells_to_pblock  pblock_slr_1_to_2 [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__to_qs_0*g__rev*tx"]
add_cells_to_pblock  pblock_slr_1_to_2 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qs_to_phy_1*tx"]
resize_pblock        pblock_slr_1_to_2 -add {CLOCKREGION_X0Y6:CLOCKREGION_X1Y7}
set_property IS_SOFT FALSE [get_pblocks pblock_slr_1_to_2]

create_pblock        pblock_slr_1_to_0
add_cells_to_pblock  pblock_slr_1_to_0 [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__to_qs_1*g__fwd*tx"]
add_cells_to_pblock  pblock_slr_1_to_0 [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__to_qs_1*g__rev*rx"]
add_cells_to_pblock  pblock_slr_1_to_0 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__app_to_qs*tx"]
add_cells_to_pblock  pblock_slr_1_to_0 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qs_to_phy_0*rx"]
resize_pblock        pblock_slr_1_to_0 -add {CLOCKREGION_X0Y4:CLOCKREGION_X1Y5}
set_property IS_SOFT FALSE [get_pblocks pblock_slr_1_to_0]

create_pblock        pblock_slr_0_to_1
add_cells_to_pblock  pblock_slr_0_to_1 [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__to_qs_1*g__fwd*rx"]
add_cells_to_pblock  pblock_slr_0_to_1 [get_cells -hierarchical -filter "NAME=~*axi4l_pipe_slr__to_qs_1*g__rev*tx"]
add_cells_to_pblock  pblock_slr_0_to_1 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__app_to_qs*rx"]
add_cells_to_pblock  pblock_slr_0_to_1 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qs_to_phy_0*tx"]
resize_pblock        pblock_slr_0_to_1 -add {CLOCKREGION_X0Y2:CLOCKREGION_X1Y3}
set_property IS_SOFT FALSE [get_pblocks pblock_slr_0_to_1]

# Smartnic egress qs
create_pblock       pblock_smartnic_egress_qs
add_cells_to_pblock pblock_smartnic_egress_qs [get_cells -hierarchical -filter "NAME=~*smartnic_egress_qs_0"]
resize_pblock       pblock_smartnic_egress_qs -add {CLOCKREGION_X0Y1:CLOCKREGION_X1Y3}
resize_pblock       pblock_smartnic_egress_qs -add {CLOCKREGION_X0Y0:CLOCKREGION_X3Y0}
set_property IS_SOFT FALSE [get_pblocks pblock_smartnic_egress_qs]
