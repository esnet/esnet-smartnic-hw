# SLR0
set_property USER_SLR_ASSIGNMENT SLR0 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qdma_h2c*tx"]
set_property USER_SLR_ASSIGNMENT SLR0 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qdma_c2h*rx"]

# SLR1
set_property USER_SLR_ASSIGNMENT SLR1 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qdma_h2c*rx"]
set_property USER_SLR_ASSIGNMENT SLR1 [get_cells -hierarchical -filter "NAME=~*axi4s_pipe_slr__qdma_c2h*tx"]
