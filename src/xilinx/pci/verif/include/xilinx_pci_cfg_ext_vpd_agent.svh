// (Xilinx) PCIe extended interface agent class for PCI Vital Product Data (VPD) access
class xilinx_pci_cfg_ext_vpd_agent extends pci_vpd_verif_pkg::pci_vpd_agent;

    local static const string __CLASS_NAME = "xilinx_pci_verif_pkg::xilinx_pci_cfg_ext_vpd_agent";

    //===================================
    // Parameters
    //===================================
    localparam int __DEFAULT_WR_TIMEOUT = 50;
    localparam int __DEFAULT_RD_TIMEOUT = 50;

    //===================================
    // Properties
    //===================================
    xilinx_pci_cfg_ext_intf_agent pci_cfg_ext_agent;

    local int __function_number;

    bit [VPD_ADDR_WID-1:0] __cache_base_addr;
    bit [3:0][7:0]         __cache_data;

    //===================================
    // Methods
    //===================================

    // Constructor
    function new(
        input string name="xilinx_pci_cfg_ext_vpd_agent",
        input int function_number = 0,
        input int WR_TIMEOUT = __DEFAULT_WR_TIMEOUT,
        input int RD_TIMEOUT = __DEFAULT_RD_TIMEOUT
    );
        super.new(name);
        // WORKAROUND-INIT-PROPS {
        //     Provide/repeat default assignments for all remaining instance properties here.
        //     Works around an apparent object initialization bug (as of Vivado 2024.2)
        //     where properties are not properly allocated when they are not assigned
        //     in the constructor.
        this.pci_cfg_ext_agent = null;
        // } WORKAROUND-INIT-PROPS
        this.__function_number = function_number;
        set_wr_timeout(WR_TIMEOUT);
        set_rd_timeout(RD_TIMEOUT);
    endfunction

    // Destructor
    // [[ implements std_verif_pkg::base.destroy() ]]
    virtual function automatic void destroy();
        super.destroy();
    endfunction

    // Configure trace output
    // [[ overrides std_verif_pkg::base.trace_msg() ]]
    function automatic void trace_msg(input string msg);
        _trace_msg(msg, __CLASS_NAME);
    endfunction

    // Put agent in idle state
    // [[ implements pci_vpd_verif_pkg::pci_vpd_agent.idle() ]]
    task idle();
        pci_cfg_ext_agent.idle();
    endtask

    protected task automatic _write_context(input bit wr, input bit [VPD_ADDR_WID-1:0] addr);
        bit error, timeout;
        vpd_ctrl_reg_t ctrl_reg;
        ctrl_reg.flag = wr;
        ctrl_reg.addr = addr;
        ctrl_reg.NXT_CAP = 'x;
        ctrl_reg.CAP_ID = 'x;
        pci_cfg_ext_agent.write(CFG_EXT_REGISTER__VPD_CTRL, __function_number, ctrl_reg, error, timeout);
    endtask

    protected task automatic _read_context(output bit flag);
        bit error, timeout;
        vpd_ctrl_reg_t ctrl_reg;
        pci_cfg_ext_agent.read(CFG_EXT_REGISTER__VPD_CTRL, __function_number, ctrl_reg, error, timeout);
        flag = ctrl_reg.flag;
    endtask

    protected task automatic _read_data(output bit [31:0] data);
        bit error, timeout;
        pci_cfg_ext_agent.read(CFG_EXT_REGISTER__VPD_DATA, __function_number, data, error, timeout);
    endtask

    protected task automatic _write_data(input bit [31:0] data);
        bit error, timeout;
        pci_cfg_ext_agent.write(CFG_EXT_REGISTER__VPD_DATA, __function_number, data, error, timeout);
    endtask

    // Read byte from VPD data structure
    // [[ implements pci_vpd_verif_pkg::pci_vpd_agent._read_byte() ]]
    protected task automatic _read_byte(input int addr, output byte data, output bit error, output bit timeout);
        bit flag;
        logic [3:0][7:0] data_reg;
        _write_context(1'b0, addr);
        do
            _read_context(flag);
        while (!flag);
        _read_data(data_reg);
        data = data_reg[0];
        error = 1'b0;
        timeout = 1'b0;
    endtask

    // Write byte to VPD data structure
    // [[ implements pci_vpd_verif_pkg::pci_vpd_agent._write_byte() ]]
    protected task automatic _write_byte(input int addr, input byte data, output bit error, output bit timeout);
        error = 1'b0;
        timeout = 1'b0;
    endtask

endclass
