# SLR0->SLR1 crossing
create_pblock       pblock_qdma_slr_0_to_1
add_cells_to_pblock pblock_qdma_slr_0_to_1 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qdma_h2c*tx*"]
add_cells_to_pblock pblock_qdma_slr_0_to_1 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qdma_c2h*rx*"]
resize_pblock       pblock_qdma_slr_0_to_1 -add {CLOCKREGION_X6Y2:CLOCKREGION_X7Y3}
set_property IS_SOFT FALSE [get_pblocks pblock_qdma_slr_0_to_1]

# SLR1->SLR0 crossing
create_pblock       pblock_qdma_slr_1_to_0
add_cells_to_pblock pblock_qdma_slr_1_to_0 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qdma_h2c*rx*"]
add_cells_to_pblock pblock_qdma_slr_1_to_0 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qdma_c2h*tx*"]
resize_pblock       pblock_qdma_slr_1_to_0 -add {CLOCKREGION_X6Y4:CLOCKREGION_X7Y5}
set_property IS_SOFT FALSE [get_pblocks pblock_qdma_slr_1_to_0]
