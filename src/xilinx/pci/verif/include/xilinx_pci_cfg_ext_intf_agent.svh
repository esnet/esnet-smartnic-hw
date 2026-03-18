// (Xilinx) PCIe extended interface agent class for PCI Vital Product Data (VPD) access
class xilinx_pci_cfg_ext_intf_agent extends std_verif_pkg::agent;

    local static const string __CLASS_NAME = "xilinx_pci_verif_pkg::xilinx_pci_cfg_ext_intf_agent";

    //===================================
    // Properties
    //===================================
    protected int _WR_TIMEOUT = 16;
    protected int _RD_TIMEOUT = 16;

    virtual xilinx_pci_cfg_ext_intf pci_cfg_ext_vif;

    //===================================
    // Methods
    //===================================

    // Constructor
    function new(input string name="xilinx_pci_cfg_ext_intf_agent");
        super.new(name);
        // WORKAROUND-INIT-PROPS {
        //     Provide/repeat default assignments for all remaining instance properties here.
        //     Works around an apparent object initialization bug (as of Vivado 2024.2)
        //     where properties are not properly allocated when they are not assigned
        //     in the constructor.
        this._WR_TIMEOUT = 16;
        this._RD_TIMEOUT = 16;
        pci_cfg_ext_vif = null;
        // } WORKAROUND-INIT-PROPS
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

    function void set_wr_timeout(input int WR_TIMEOUT);
        this._WR_TIMEOUT = WR_TIMEOUT;
    endfunction

    function int get_wr_timeout();
        return this._WR_TIMEOUT;
    endfunction

    function void set_rd_timeout(input int RD_TIMEOUT);
        this._RD_TIMEOUT = RD_TIMEOUT;
    endfunction

    function int get_rd_timeout();
        return this._RD_TIMEOUT;
    endfunction
    // Put agent in idle state
    // [[ implements pci_vpd_verif_pkg::pci_vpd_agent.idle() ]]
    task idle();
        pci_cfg_ext_vif.idle();
    endtask

    // Read PCI extended config register
    task automatic read(input int register_number, input int function_number, output bit [31:0] data, output bit error, output bit timeout);
        error = !cfg_ext_legacy_access_in_range(register_number, function_number);
        lock();
        pci_cfg_ext_vif.read(register_number, function_number, data, timeout, get_rd_timeout());
        unlock();
    endtask

    // Write PCI extended config register
    task automatic write(input int register_number, input int function_number, input bit [31:0] data, output bit error, output bit timeout);
        error = !cfg_ext_legacy_access_in_range(register_number, function_number);
        lock();
        pci_cfg_ext_vif.write(register_number, function_number, data, timeout, get_wr_timeout());
        unlock();
    endtask

endclass
