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

class timestamp_agent #(
    parameter type TIMESTAMP_T = bit[63:0]
);

    //===================================
    // Properties
    //===================================
    rand TIMESTAMP_T _timestamp_init;

    //===================================
    // Interfaces
    //===================================
    virtual timestamp_if timestamp_vif;

    //===================================
    // Methods
    //===================================

    // Constructor
    function new();
        randomize();
    endfunction

    task reset();
        timestamp_vif.update(_timestamp_init);
    endtask

    task set_static(input TIMESTAMP_T timestamp);
        timestamp_vif.freeze_at(timestamp);
    endtask

    task set(input TIMESTAMP_T timestamp);
        timestamp_vif.update(timestamp);
    endtask

    task freeze();
        timestamp_vif.freeze();
    endtask

    task unfreeze();
        timestamp_vif.unfreeze();
    endtask

endclass : timestamp_agent
