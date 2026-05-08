    // DDR4
    output wire        CH0_DDR4_0_0_act_n,
    output wire [16:0] CH0_DDR4_0_0_adr,
    output wire [1:0]  CH0_DDR4_0_0_ba,
    output wire        CH0_DDR4_0_0_bg,
    output wire        CH0_DDR4_0_0_ck_c,
    output wire        CH0_DDR4_0_0_ck_t,
    output wire        CH0_DDR4_0_0_cke,
    output wire        CH0_DDR4_0_0_cs_n,
    inout  wire [8:0]  CH0_DDR4_0_0_dm_n,
    inout  wire [71:0] CH0_DDR4_0_0_dq,
    inout  wire [8:0]  CH0_DDR4_0_0_dqs_c,
    inout  wire [8:0]  CH0_DDR4_0_0_dqs_t,
    output wire        CH0_DDR4_0_0_odt,
    output wire        CH0_DDR4_0_0_reset_n,
    output wire        CH0_DDR4_0_1_act_n,
    output wire [17:0] CH0_DDR4_0_1_adr,
    input  wire        CH0_DDR4_0_1_alert_n,
    output wire [1:0]  CH0_DDR4_0_1_ba,
    output wire [1:0]  CH0_DDR4_0_1_bg,
    output wire        CH0_DDR4_0_1_ck_c,
    output wire        CH0_DDR4_0_1_ck_t,
    output wire        CH0_DDR4_0_1_cke,
    output wire        CH0_DDR4_0_1_cs_n,
    inout  wire [71:0] CH0_DDR4_0_1_dq,
    inout  wire [17:0] CH0_DDR4_0_1_dqs_c,
    inout  wire [17:0] CH0_DDR4_0_1_dqs_t,
    output wire        CH0_DDR4_0_1_odt,
    output wire        CH0_DDR4_0_1_par,
    output wire        CH0_DDR4_0_1_reset_n,

    // PCIe
    input  wire       gt_pcie_refclk_clk_n,
    input  wire       gt_pcie_refclk_clk_p,
    input  wire [7:0] gt_pciea1_grx_n,
    input  wire [7:0] gt_pciea1_grx_p,
    output wire [7:0] gt_pciea1_gtx_n,
    output wire [7:0] gt_pciea1_gtx_p,

    // HBM
    input  wire       hbm_ref_clk_0_clk_n,
    input  wire       hbm_ref_clk_0_clk_p,
    input  wire       hbm_ref_clk_1_clk_n,
    input  wire       hbm_ref_clk_1_clk_p,
    
    // SMBus
    inout  wire       smbus_0_scl_io,
    inout  wire       smbus_0_sda_io,

    // Clocks
    input  wire       sys_clk0_0_clk_n,
    input  wire       sys_clk0_0_clk_p,
    input  wire       sys_clk0_1_clk_n,
    input  wire       sys_clk0_1_clk_p

