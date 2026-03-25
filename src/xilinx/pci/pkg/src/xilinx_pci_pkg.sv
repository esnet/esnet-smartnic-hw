package xilinx_pci_pkg;
    import pci_vpd_pkg::*;

    //===================================
    // Parameters
    //===================================
    // Extended configuration interface
    localparam int CFG_EXT_REG_SEL_WID = 10;
    localparam int CFG_EXT_FUNC_SEL_WID = 8;

    localparam int CFG_EXT_LEGACY_LO_OFFSET = 10'h0B0;
    localparam int CFG_EXT_LEGACY_HI_OFFSET = 10'h0BF;

    localparam int CFG_EXT_LEGACY_LO_DWORD_IDX = CFG_EXT_LEGACY_LO_OFFSET >> 2;
    localparam int CFG_EXT_LEGACY_HI_DWORD_IDX = CFG_EXT_LEGACY_HI_OFFSET >> 2;

    localparam int CFG_EXT_REGISTER__VPD_CTRL = CFG_EXT_LEGACY_LO_DWORD_IDX;
    localparam int CFG_EXT_REGISTER__VPD_DATA = CFG_EXT_REGISTER__VPD_CTRL + 1;

    //===================================
    // Typedefs
    //===================================
    typedef struct packed {logic flag; logic[VPD_ADDR_WID-1:0] addr; logic[7:0] NXT_CAP; logic[7:0] CAP_ID;} vpd_ctrl_reg_t;

    //===================================
    // Functions
    //===================================
    function automatic bit cfg_ext_legacy_access_in_range(input int register_number, input int function_number);
        if (register_number <  CFG_EXT_LEGACY_LO_DWORD_IDX) return 1'b0;
        if (register_number >= CFG_EXT_LEGACY_LO_DWORD_IDX) return 1'b0;
        if (function_number >= 2**CFG_EXT_FUNC_SEL_WID)     return 1'b0;
        return 1'b1;
    endfunction

endpackage : xilinx_pci_pkg
