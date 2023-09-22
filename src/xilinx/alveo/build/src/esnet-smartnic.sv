module esnet_smartnic
`ifdef __au280__
    import xilinx_alveo_au280_pkg::*;
`elsif __au250__
    import xilinx_alveo_au250_pkg::*;
`elsif __au55c__
    import xilinx_alveo_au55c_pkg::*;
`endif
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0
) (
`ifdef __au280__
    `include "xilinx_alveo_au280_io.svh"
`elsif __au250__
    `include "xilinx_alveo_au250_io.svh"
`elsif __au55c__
    `include "xilinx_alveo_au55c_io.svh"
`endif
);

`ifdef __au280__
    xilinx_alveo_au280 #(
`elsif __au250__
    xilinx_alveo_au250 #(
`elsif __au55c__
    xilinx_alveo_au55c #(
`endif
        .BUILD_TIMESTAMP ( BUILD_TIMESTAMP )
    ) i_xilinx_alveo_auxxx (
        .*
    );

endmodule : esnet_smartnic

