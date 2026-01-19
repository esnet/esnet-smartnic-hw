class proxy_test_reg_agent #(
) extends proxy_test_reg_blk_agent;
  
    //===================================
    // Methods
    //===================================
    // Constructor
    function new(
            input string name="proxy_test_reg_agent",
            reg_verif_pkg::reg_agent reg_agent,
            input int BASE_OFFSET=0
        );
        super.new(name, BASE_OFFSET);
        this.reg_agent = reg_agent;
    endfunction

    // Read status
    task get_id(output proxy_test_reg_pkg::reg_id_t id);
        this.read_id(id);
    endtask

    // Check status
    task check_id(output bit fail, output string msg);
        proxy_test_reg_pkg::reg_id_t exp_id = proxy_test_reg_pkg::INIT_ID;
        proxy_test_reg_pkg::reg_id_t got_id;
        this.get_id(got_id);
        if (got_id == exp_id) begin
            fail = 1'b0;
            msg = "ID check passed";
        end else begin
            fail = 1'b1;
            msg = $sformatf("[proxy_test_reg_agent]: ID check failed. Exp: 0x%x, Got: 0x%x", exp_id, got_id);
        end
    endtask

endclass : proxy_test_reg_agent
