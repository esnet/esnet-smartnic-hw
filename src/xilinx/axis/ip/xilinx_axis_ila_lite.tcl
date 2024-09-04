set module_name xilinx_axis_ila_lite

create_ip -name ila -vendor xilinx.com -library ip -module_name $module_name -dir . -force

set_property -dict [list \
    CONFIG.C_NUM_OF_PROBES {6} \
    CONFIG.C_PROBE0_WIDTH  {8} \
    CONFIG.C_PROBE3_WIDTH  {1} \
    CONFIG.C_PROBE5_WIDTH  {1} \
    CONFIG.C_DATA_DEPTH    {65536} \
    CONFIG.C_ADV_TRIGGER   {true}  \
    CONFIG.C_INPUT_PIPE_STAGES {4} \
    CONFIG.C_EN_STRG_QUAL  {1} \
    CONFIG.C_PROBE0_MU_CNT {2} \
    CONFIG.C_PROBE1_MU_CNT {2} \
    CONFIG.C_PROBE2_MU_CNT {2} \
    CONFIG.C_PROBE3_MU_CNT {2} \
    CONFIG.C_PROBE4_MU_CNT {2} \
    CONFIG.C_PROBE5_MU_CNT {2} \
    CONFIG.ALL_PROBE_SAME_MU {false} \
    CONFIG.ALL_PROBE_SAME_MU_CNT {2} \
] [get_ips $module_name]
