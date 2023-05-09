# SLR0->SLR1 crossing
create_pblock       pblock_qdma_slr_0_to_1
add_cells_to_pblock pblock_qdma_slr_0_to_1 [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__qdma_h2c*slr_source*"]
add_cells_to_pblock pblock_qdma_slr_0_to_1 [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__qdma_c2h*slr_dest*"]
resize_pblock       pblock_qdma_slr_0_to_1 -add {CLOCKREGION_X6Y3:CLOCKREGION_X7Y3}
set_property IS_SOFT FALSE [get_pblocks pblock_qdma_slr_0_to_1]

# SLR1->SLR0 crossing
create_pblock       pblock_qdma_slr_1_to_0
add_cells_to_pblock pblock_qdma_slr_1_to_0 [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__qdma_h2c*slr_dest*"]
add_cells_to_pblock pblock_qdma_slr_1_to_0 [get_cells -hierarchical -filter "NAME=~*axi4s_reg_slice__qdma_c2h*slr_source*"]
resize_pblock       pblock_qdma_slr_1_to_0 -add {CLOCKREGION_X6Y4:CLOCKREGION_X7Y4}
set_property IS_SOFT FALSE [get_pblocks pblock_qdma_slr_1_to_0]
