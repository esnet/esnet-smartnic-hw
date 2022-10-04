// =============================================================================
//  NOTICE: This computer software was prepared by The Regents of the
//  University of California through Lawrence Berkeley National Laboratory
//  and Jonathan Sewter hereinafter the Contractor, under Contract No.
//  DE-AC02-05CH11231 with the Department of Energy (DOE). All rights in the
//  computer software are reserved by DOE on behalf of the United States
//  Government and the Contractor as provided in the Contract. You are
//  authorized to use this computer software for Governmental purposes but it
//  is not to be released or distributed to the public.
//
//  NEITHER THE GOVERNMENT NOR THE CONTRACTOR MAKES ANY WARRANTY, EXPRESS OR
//  IMPLIED, OR ASSUMES ANY LIABILITY FOR THE USE OF THIS SOFTWARE.
//
//  This notice including this sentence must appear on any copies of this
//  computer software.
// =============================================================================

class p4_and_verilog_reg_agent #(
) extends p4_and_verilog_reg_blk_agent;
  
    //===================================
    // Methods
    //===================================
    // Constructor
    function new(
            input string name="p4_and_verilog_reg_agent",
            const ref reg_verif_pkg::reg_agent reg_agent,
            input int BASE_OFFSET=0
        );
        super.new(name, BASE_OFFSET);
        this.reg_agent = reg_agent;
    endfunction

    // Read status
    task get_status(output p4_and_verilog_reg_pkg::reg_status_t status);
        this.read_status(status);
    endtask

    // Check status
    task check_status(output bit fail, output string msg);
        p4_and_verilog_reg_pkg::reg_status_t exp_status = p4_and_verilog_reg_pkg::INIT_STATUS;
        p4_and_verilog_reg_pkg::reg_status_t got_status;
        this.get_status(got_status);
        if (got_status == exp_status) begin
            fail = 1'b0;
            msg = "STATUS check passed";
        end else begin
            fail = 1'b1;
            msg = $sformatf("[p4_and_verilog_reg_agent]: STATUS check failed. Exp: 0x%x, Got: 0x%x", exp_status, got_status);
        end
    endtask

endclass : p4_and_verilog_reg_agent
