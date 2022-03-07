// =============================================================================
//  NOTICE: This computer software was prepared by The Regents of the
//  University of California through Lawrence Berkeley National Laboratory
//  and Peter Bengough hereinafter the Contractor, under Contract No.
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
package p4_example_pkg;
    // --------------------------------------------------------------
    // Imports
    // --------------------------------------------------------------
    import sdnet_0_pkg::*;

    // --------------------------------------------------------------
    // Parameters & Typedefs
    // --------------------------------------------------------------

    // Timestamp
    localparam int TIMESTAMP_WID = 64;

    typedef logic [TIMESTAMP_WID-1:0] timestamp_t;

    // User metadata
    typedef USER_META_DATA_T user_metadata_t;

endpackage : p4_example_pkg
