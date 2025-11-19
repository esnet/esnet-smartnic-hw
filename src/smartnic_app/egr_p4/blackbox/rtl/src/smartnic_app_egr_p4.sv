// smartnic_app_egr_p4 module black box. Used for platform level builds.
(*black_box*) module smartnic_app_egr_p4
    import smartnic_pkg::*;
#(
    parameter int NUM_PORTS = 2  // Number of ingress/egress axi4s ports.
 ) (
    input  logic          core_clk,
    input  logic          core_srst,

    input  timestamp_t    timestamp,

    axi4l_intf.peripheral axil_to_p4_proc,
    axi4l_intf.peripheral axil_to_vitisnetp4,
    axi4l_intf.peripheral axil_to_extern,

    input  logic [3:0]    egr_flow_ctl,

    axi4s_intf.rx         axis_in  [NUM_PORTS],
    axi4s_intf.tx         axis_out [NUM_PORTS],
    axi4s_intf.rx         axis_to_extern,
    axi4s_intf.tx         axis_from_extern
);
   
endmodule : smartnic_app_egr_p4
