module vitisnetp4_egr_extern
    import vitisnetp4_egr_pkg::*;
    import smartnic_pkg::*;
(
    input   logic clk,
    input   logic rstn,

    input   USER_EXTERN_OUT_T    extern_from_vitisnetp4,
    input   USER_EXTERN_VALID_T  extern_from_vitisnetp4_valid,
    output  USER_EXTERN_IN_T     extern_to_vitisnetp4,
    output  USER_EXTERN_VALID_T  extern_to_vitisnetp4_valid,

    input   timestamp_t    timestamp,
    input   logic [3:0]    egr_flow_ctl,

    axi4l_intf.peripheral  axil_to_extern,
    axi4s_intf.rx          axis_to_extern,
    axi4s_intf.tx          axis_from_extern
);

    // Use 
    vitisnetp4_0_extern #(
        .EXTERN_VALID_T  ( USER_EXTERN_VALID_T ),
        .EXTERN_OUT_T    ( USER_EXTERN_OUT_T ),
        .EXTERN_IN_T     ( USER_EXTERN_IN_T )
    ) vitsnetp4_0_extern (.*);

endmodule: vitisnetp4_egr_extern
