# SLR0->SLR1 crossing
create_pblock       pblock_qdma_slr_0_to_1
add_cells_to_pblock pblock_qdma_slr_0_to_1 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qdma_h2c*tx*"]
add_cells_to_pblock pblock_qdma_slr_0_to_1 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qdma_c2h*rx*"]
resize_pblock       pblock_qdma_slr_0_to_1 -add {CLOCKREGION_X6Y3:CLOCKREGION_X7Y3}
set_property IS_SOFT FALSE [get_pblocks pblock_qdma_slr_0_to_1]

# SLR1->SLR0 crossing
create_pblock       pblock_qdma_slr_1_to_0
add_cells_to_pblock pblock_qdma_slr_1_to_0 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qdma_h2c*rx*"]
add_cells_to_pblock pblock_qdma_slr_1_to_0 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qdma_c2h*tx*"]
resize_pblock       pblock_qdma_slr_1_to_0 -add {CLOCKREGION_X6Y4:CLOCKREGION_X7Y4}
set_property IS_SOFT FALSE [get_pblocks pblock_qdma_slr_1_to_0]

# SLR1->SLR2 crossing
create_pblock       pblock_qdma_slr_1_to_2
add_cells_to_pblock pblock_qdma_slr_1_to_2 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__adap_tx*tx*"]
add_cells_to_pblock pblock_qdma_slr_1_to_2 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__adap_rx*rx*"]
resize_pblock       pblock_qdma_slr_1_to_2 -add {CLOCKREGION_X6Y7:CLOCKREGION_X7Y7}
set_property IS_SOFT FALSE [get_pblocks pblock_qdma_slr_1_to_2]

# SLR2->SLR1 crossing
create_pblock       pblock_qdma_slr_2_to_1
add_cells_to_pblock pblock_qdma_slr_2_to_1 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__adap_tx*rx*"]
add_cells_to_pblock pblock_qdma_slr_2_to_1 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__adap_rx*tx*"]
resize_pblock       pblock_qdma_slr_2_to_1 -add {CLOCKREGION_X6Y8:CLOCKREGION_X7Y8}
set_property IS_SOFT FALSE [get_pblocks pblock_qdma_slr_2_to_1]


