# Smartnic app core
create_pblock pblock_smartnic_app
add_cells_to_pblock [get_pblocks pblock_smartnic_app] -top
resize_pblock [get_pblocks pblock_smartnic_app] -add {SLR2}

