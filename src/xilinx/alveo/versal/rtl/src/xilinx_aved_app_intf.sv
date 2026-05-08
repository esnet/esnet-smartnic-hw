interface xilinx_aved_app_intf;

    wire logic clk;
    wire logic srst;

    axi4l_intf  axil_if ();

    modport aved (
        output clk,
        output srst
    );

    modport app (
        input  clk,
        input  srst
    );

endinterface : xilinx_aved_app_intf

