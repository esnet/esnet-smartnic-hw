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
package smartnic_322mhz_pkg;

    // --------------------------------------------------------------
    // Imports
    // --------------------------------------------------------------

    // --------------------------------------------------------------
    // Parameters
    // --------------------------------------------------------------

    // --------------------------------------------------------------
    // Typedefs
    // --------------------------------------------------------------

    typedef enum logic [1:0] {
        CMAC_PORT0 = 2'b00,
        CMAC_PORT1 = 2'b01,
        HOST_PORT0 = 2'b10,
        HOST_PORT1 = 2'b11
    } port_encoding_t;

    typedef union packed {
        port_encoding_t encoded;
        bit [1:0]       raw;
    } port_t;

endpackage : smartnic_322mhz_pkg
