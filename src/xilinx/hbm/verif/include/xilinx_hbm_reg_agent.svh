class xilinx_hbm_reg_agent extends xilinx_hbm_reg_blk_agent;

    //===================================
    // Methods
    //===================================
    function new(
            input string name="xilinx_hbm_reg_agent",
            const ref reg_verif_pkg::reg_agent reg_agent,
            input int BASE_OFFSET=0
    );
        super.new(name, BASE_OFFSET);
        this.reg_agent = reg_agent;
    endfunction
 
    // Reset agent state
    // [[ implements std_verif_pkg::agent.reset() virtual method ]]
    function automatic void reset();
        super.reset();
        // Nothing extra to do
    endfunction

    // Reset client
    // [[ implements std_verif_pkg::agent.reset_client ]]
    task reset_client();
        soft_reset();
    endtask

    task soft_reset();
        xilinx_hbm_reg_pkg::reg_control_t reg_control;
        this.read_control(reg_control);
        reg_control.reset = 1;
        this.write_control(reg_control);
        reg_control.reset = 0;
        this.write_control(reg_control);
        wait_ready();
    endtask

    // Poll register block for ready status
    // [[ implements std_verif_pkg::agent.wait_ready() virtual method ]]
    task wait_ready();
        xilinx_hbm_reg_pkg::reg_status_t reg_status;
        do
            this.read_status(reg_status);
        while (reg_status.reset == 1'b1 || reg_status.init_done == 1'b0);
    endtask

    task get_dram_temp(output int temp);
        xilinx_hbm_reg_pkg::reg_dram_status_t reg_dram_status;
        this.read_dram_status(reg_dram_status);
        temp = reg_dram_status.temp;
    endtask

    task get_dram_cattrip(output bit cattrip);
        xilinx_hbm_reg_pkg::reg_dram_status_t reg_dram_status;
        this.read_dram_status(reg_dram_status);
        cattrip = reg_dram_status.cattrip;
    endtask

endclass : xilinx_hbm_reg_agent
