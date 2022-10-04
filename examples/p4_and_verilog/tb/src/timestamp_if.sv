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

interface timestamp_if #(
    parameter type TIMESTAMP_T = bit[63:0]
) (
    input clk,
    input srst
);
    // Signals
    logic       set;
    logic       hold;
    TIMESTAMP_T set_value;
    TIMESTAMP_T timestamp;

    modport client(
        input timestamp
    );

    initial set = 0;
    initial hold = 0;

    // Timestamp is generated from free-running counter
    initial timestamp = 0;
    always @(posedge clk) begin
        if (srst)       timestamp <= 0;
        else if (set)   timestamp <= set_value;
        else if (!hold) timestamp <= timestamp + 1;
    end

    // Tasks
    function static TIMESTAMP_T get();
        return timestamp;
    endfunction

    task update(input TIMESTAMP_T _set_value);
        set <= 1'b1;
        set_value <= _set_value;
        @(posedge clk);
        set <= 1'b0;
    endtask

    task freeze_at(input TIMESTAMP_T _static_value);
        update(_static_value);
        freeze();
    endtask

    task freeze();
        hold <= 1'b1;
    endtask

    task unfreeze();
        hold <= 1'b0;
    endtask

endinterface : timestamp_if
