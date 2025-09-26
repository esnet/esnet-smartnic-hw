module smartnic_app_egr_p4
    import smartnic_pkg::*;
#(
    parameter int NUM_PORTS = 2  // Number of ingress/egress axi4s ports.
 ) (
    input  logic          core_clk,
    input  logic          core_rstn,

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
    // Parameters
    localparam int DATA_BYTE_WID = axis_in[0].DATA_BYTE_WID;

    // Parameter checking
    initial begin
        std_pkg::param_check(axis_in[0].TID_WID,        PORT_WID,                "axis_in.TID_WID");
        std_pkg::param_check(axis_in[0].TDEST_WID,      PORT_WID,                "axis_in.TDEST_WID");
        std_pkg::param_check(axis_in[0].TUSER_WID,      TUSER_SMARTNIC_META_WID, "axis_in.TDEST_WID");
        std_pkg::param_check(axis_out[0].DATA_BYTE_WID, DATA_BYTE_WID,           "axis_out.DATA_BYTE_WID");
        std_pkg::param_check(axis_out[0].TID_WID,       PORT_WID,                "axis_out.TID_WID");
        std_pkg::param_check(axis_out[0].TDEST_WID,     PORT_WID,                "axis_out.TDEST_WID");
        std_pkg::param_check(axis_out[0].TUSER_WID,     TUSER_SMARTNIC_META_WID, "axis_out.TDEST_WID");
    end

    // Signals
    p4_proc_pkg::user_metadata_t user_metadata_in;
    logic                        user_metadata_in_valid;

    p4_proc_pkg::user_metadata_t user_metadata_out;
    logic                        user_metadata_out_valid;

    // Interfaces
    axi4s_intf #(.DATA_BYTE_WID(DATA_BYTE_WID)) axis_to_vitisnetp4 (.aclk(core_clk), .aresetn(core_rstn));
    axi4s_intf #(.DATA_BYTE_WID(DATA_BYTE_WID)) axis_from_vitisnetp4 (.aclk(core_clk), .aresetn(core_rstn));

    // P4 processor complex
    p4_proc #(.NUM_PORTS(NUM_PORTS)) p4_proc_inst (
        .core_clk                       ( core_clk ),
        .core_rstn                      ( core_rstn ),
        .timestamp                      ( timestamp ),
        .axil_if                        ( axil_to_p4_proc ),
        .axis_in                        ( axis_in ),
        .axis_out                       ( axis_out ),
        .axis_to_vitisnetp4                  ( axis_to_vitisnetp4 ),
        .axis_from_vitisnetp4                ( axis_from_vitisnetp4 ),
        .user_metadata_to_vitisnetp4_valid   ( user_metadata_in_valid ),
        .user_metadata_to_vitisnetp4         ( user_metadata_in ),
        .user_metadata_from_vitisnetp4_valid ( user_metadata_out_valid ),
        .user_metadata_from_vitisnetp4       ( user_metadata_out )
    );

    // P4 pipeline wrapper
    vitisnetp4_egr_wrapper vitisnetp4_egr_wrapper_inst (
        .core_clk                ( core_clk ),
        .core_rstn               ( core_rstn ),
        .axil_if                 ( axil_to_vitisnetp4 ),
        .axis_rx                 ( axis_to_vitisnetp4 ),
        .axis_tx                 ( axis_from_vitisnetp4 ),
        .user_metadata_in_valid  ( user_metadata_in_valid ),
        .user_metadata_in        ( user_metadata_in ),
        .user_metadata_out_valid ( user_metadata_out_valid ),
        .user_metadata_out       ( user_metadata_out ),
        .timestamp               ( timestamp ),
        .egr_flow_ctl            ( egr_flow_ctl ),
        .axil_to_extern          ( axil_to_extern ),
        .axis_to_extern          ( axis_to_extern ),
        .axis_from_extern        ( axis_from_extern )
    );

endmodule : smartnic_app_egr_p4
