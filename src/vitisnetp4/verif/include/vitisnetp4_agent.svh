class `VITISNETP4_AGENT_NAME extends xilinx_vitisnetp4_verif_pkg::xilinx_vitisnetp4_agent;

    //===================================
    // Methods
    //===================================
    // Constructor
    function new(input string name=`"`VITISNETP4_AGENT_NAME`", input string hier_path);
        super.new(
            .name(name),
            .hier_path(hier_path),
            .cfg(`VITISNETP4_PKG_NAME::XilVitisNetP4Config)
        );
    endfunction

endclass : `VITISNETP4_AGENT_NAME
