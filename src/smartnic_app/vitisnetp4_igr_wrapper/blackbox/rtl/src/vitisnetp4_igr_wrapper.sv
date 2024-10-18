// vitisnetp4_igr_wrapper module black box. Used for platform level builds.
(*black_box*) module vitisnetp4_igr_wrapper
    import smartnic_pkg::*;
    import p4_proc_pkg::*;
(
    input  logic            core_clk,
    input  logic            core_rstn,

    axi4l_intf.peripheral   axil_if,
    axi4s_intf.rx           axis_rx,
    axi4s_intf.tx           axis_tx,

    input  logic            user_metadata_in_valid,
    input  user_metadata_t  user_metadata_in,
    output logic            user_metadata_out_valid,
    output user_metadata_t  user_metadata_out,

    input timestamp_t       timestamp,

    input logic [3:0]       egr_flow_ctl,

    axi4l_intf.peripheral   axil_to_extern,

    axi4s_intf.rx           axis_to_extern,
    axi4s_intf.tx           axis_from_extern
);

endmodule : vitisnetp4_igr_wrapper
