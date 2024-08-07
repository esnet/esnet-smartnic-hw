set module_name xilinx_hbm_right

create_ip -name hbm -vendor xilinx.com -library ip -module_name $module_name -dir . -force

set_property -dict [list \
    CONFIG.USER_SINGLE_STACK_SELECTION {RIGHT} \
    CONFIG.USER_SWITCH_ENABLE_00 {FALSE} \
    CONFIG.USER_MC0_TRAFFIC_OPTION {Random}  \
    CONFIG.USER_MC1_TRAFFIC_OPTION {Random}  \
    CONFIG.USER_MC2_TRAFFIC_OPTION {Random}  \
    CONFIG.USER_MC3_TRAFFIC_OPTION {Random}  \
    CONFIG.USER_MC4_TRAFFIC_OPTION {Random}  \
    CONFIG.USER_MC5_TRAFFIC_OPTION {Random}  \
    CONFIG.USER_MC6_TRAFFIC_OPTION {Random}  \
    CONFIG.USER_MC7_TRAFFIC_OPTION {Random}  \
    CONFIG.USER_MC8_TRAFFIC_OPTION {Random}  \
    CONFIG.USER_MC9_TRAFFIC_OPTION {Random}  \
    CONFIG.USER_MC10_TRAFFIC_OPTION {Random} \
    CONFIG.USER_MC11_TRAFFIC_OPTION {Random} \
    CONFIG.USER_MC12_TRAFFIC_OPTION {Random} \
    CONFIG.USER_MC13_TRAFFIC_OPTION {Random} \
    CONFIG.USER_MC14_TRAFFIC_OPTION {Random} \
    CONFIG.USER_MC15_TRAFFIC_OPTION {Random} \
    CONFIG.USER_MC0_LOOKAHEAD_SBRF {false}  \
    CONFIG.USER_MC1_LOOKAHEAD_SBRF {false}  \
    CONFIG.USER_MC2_LOOKAHEAD_SBRF {false}  \
    CONFIG.USER_MC3_LOOKAHEAD_SBRF {false}  \
    CONFIG.USER_MC4_LOOKAHEAD_SBRF {false}  \
    CONFIG.USER_MC5_LOOKAHEAD_SBRF {false}  \
    CONFIG.USER_MC6_LOOKAHEAD_SBRF {false}  \
    CONFIG.USER_MC7_LOOKAHEAD_SBRF {false}  \
    CONFIG.USER_MC8_LOOKAHEAD_SBRF {false}  \
    CONFIG.USER_MC9_LOOKAHEAD_SBRF {false}  \
    CONFIG.USER_MC10_LOOKAHEAD_SBRF {false} \
    CONFIG.USER_MC11_LOOKAHEAD_SBRF {false} \
    CONFIG.USER_MC12_LOOKAHEAD_SBRF {false} \
    CONFIG.USER_MC13_LOOKAHEAD_SBRF {false} \
    CONFIG.USER_MC14_LOOKAHEAD_SBRF {false} \
    CONFIG.USER_MC15_LOOKAHEAD_SBRF {false} \
    CONFIG.USER_MC0_ENABLE_ECC_CORRECTION {true}  \
    CONFIG.USER_MC1_ENABLE_ECC_CORRECTION {true}  \
    CONFIG.USER_MC2_ENABLE_ECC_CORRECTION {true}  \
    CONFIG.USER_MC3_ENABLE_ECC_CORRECTION {true}  \
    CONFIG.USER_MC4_ENABLE_ECC_CORRECTION {true}  \
    CONFIG.USER_MC5_ENABLE_ECC_CORRECTION {true}  \
    CONFIG.USER_MC6_ENABLE_ECC_CORRECTION {true}  \
    CONFIG.USER_MC7_ENABLE_ECC_CORRECTION {true}  \
    CONFIG.USER_MC8_ENABLE_ECC_CORRECTION {true}  \
    CONFIG.USER_MC9_ENABLE_ECC_CORRECTION {true}  \
    CONFIG.USER_MC10_ENABLE_ECC_CORRECTION {true} \
    CONFIG.USER_MC11_ENABLE_ECC_CORRECTION {true} \
    CONFIG.USER_MC12_ENABLE_ECC_CORRECTION {true} \
    CONFIG.USER_MC13_ENABLE_ECC_CORRECTION {true} \
    CONFIG.USER_MC14_ENABLE_ECC_CORRECTION {true} \
    CONFIG.USER_MC15_ENABLE_ECC_CORRECTION {true} \
    CONFIG.USER_MC0_ENABLE_ECC_SCRUBBING {true}   \
    CONFIG.USER_MC1_ENABLE_ECC_SCRUBBING {true}   \
    CONFIG.USER_MC2_ENABLE_ECC_SCRUBBING {true}   \
    CONFIG.USER_MC3_ENABLE_ECC_SCRUBBING {true}   \
    CONFIG.USER_MC4_ENABLE_ECC_SCRUBBING {true}   \
    CONFIG.USER_MC5_ENABLE_ECC_SCRUBBING {true}   \
    CONFIG.USER_MC6_ENABLE_ECC_SCRUBBING {true}   \
    CONFIG.USER_MC7_ENABLE_ECC_SCRUBBING {true}   \
    CONFIG.USER_MC8_ENABLE_ECC_SCRUBBING {true}   \
    CONFIG.USER_MC9_ENABLE_ECC_SCRUBBING {true}   \
    CONFIG.USER_MC10_ENABLE_ECC_SCRUBBING {true}  \
    CONFIG.USER_MC11_ENABLE_ECC_SCRUBBING {true}  \
    CONFIG.USER_MC12_ENABLE_ECC_SCRUBBING {true}  \
    CONFIG.USER_MC13_ENABLE_ECC_SCRUBBING {true}  \
    CONFIG.USER_MC14_ENABLE_ECC_SCRUBBING {true}  \
    CONFIG.USER_MC15_ENABLE_ECC_SCRUBBING {true}  \
    CONFIG.USER_MC0_INITILIZE_MEM_USING_ECC_SCRUB {true}   \
    CONFIG.USER_MC1_INITILIZE_MEM_USING_ECC_SCRUB {true}   \
    CONFIG.USER_MC2_INITILIZE_MEM_USING_ECC_SCRUB {true}   \
    CONFIG.USER_MC3_INITILIZE_MEM_USING_ECC_SCRUB {true}   \
    CONFIG.USER_MC4_INITILIZE_MEM_USING_ECC_SCRUB {true}   \
    CONFIG.USER_MC5_INITILIZE_MEM_USING_ECC_SCRUB {true}   \
    CONFIG.USER_MC6_INITILIZE_MEM_USING_ECC_SCRUB {true}   \
    CONFIG.USER_MC7_INITILIZE_MEM_USING_ECC_SCRUB {true}   \
    CONFIG.USER_MC8_INITILIZE_MEM_USING_ECC_SCRUB {true}   \
    CONFIG.USER_MC9_INITILIZE_MEM_USING_ECC_SCRUB {true}   \
    CONFIG.USER_MC10_INITILIZE_MEM_USING_ECC_SCRUB {true}  \
    CONFIG.USER_MC11_INITILIZE_MEM_USING_ECC_SCRUB {true}  \
    CONFIG.USER_MC12_INITILIZE_MEM_USING_ECC_SCRUB {true}  \
    CONFIG.USER_MC13_INITILIZE_MEM_USING_ECC_SCRUB {true}  \
    CONFIG.USER_MC14_INITILIZE_MEM_USING_ECC_SCRUB {true}  \
    CONFIG.USER_MC15_INITILIZE_MEM_USING_ECC_SCRUB {true}  \
] [get_ips $module_name]
