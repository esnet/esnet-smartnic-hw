// Application core (black-box version)
// (used for OOC synthesis of shell)
(* black_box *) module core
    import shell_pkg::*;
(
    // Clock/reset
    input wire logic clk,
    input wire logic srst,

    input wire logic mgmt_clk,
    input wire logic mgmt_srst,

    input wire logic clk_100mhz,

    // Shell interface
    input  wire logic [SHELL_TO_CORE_WID-1:0] shell_to_core,
    output wire logic [CORE_TO_SHELL_WID-1:0] core_to_shell
);
endmodule : core
