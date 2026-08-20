class sar_test_reg_agent #(
) extends sar_test_reg_blk_agent;

    //===================================
    // Methods
    //===================================
    function new(
            input string name="sar_test_reg_agent",
            reg_verif_pkg::reg_agent reg_agent,
            input int BASE_OFFSET=0
        );
        super.new(name, BASE_OFFSET);
        this.reg_agent = reg_agent;
    endfunction

    task get_id(output sar_test_reg_pkg::reg_id_t id);
        this.read_id(id);
    endtask

    task check_id(output bit fail, output string msg);
        sar_test_reg_pkg::reg_id_t exp_id = sar_test_reg_pkg::INIT_ID;
        sar_test_reg_pkg::reg_id_t got_id;
        this.get_id(got_id);
        if (got_id == exp_id) begin
            fail = 1'b0;
            msg = "ID check passed";
        end else begin
            fail = 1'b1;
            msg = $sformatf("[sar_test_reg_agent]: ID check failed. Exp: 0x%x, Got: 0x%x", exp_id, got_id);
        end
    endtask

endclass : sar_test_reg_agent
