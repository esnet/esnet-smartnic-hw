module smartnic_sw_igr
#(
    parameter int  NUM_CMAC = 2
) (
    input logic        core_clk,
    input logic        core_rstn,

    axi4s_intf.rx   axis_cmac_to_core   [NUM_CMAC],
    axi4s_intf.rx   axis_host_to_core   [NUM_CMAC],
    axi4s_intf.tx   axis_core_to_app    [NUM_CMAC],
    axi4s_intf.tx   axis_core_to_bypass,

    smartnic_reg_intf.peripheral   smartnic_regs
);
    import smartnic_pkg::*;

    // ----------------------------------------------------------------
    //  axi4s interface instantiations
    // ----------------------------------------------------------------
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(igr_tdest_t))   axis_cmac_to_core_p [NUM_CMAC]    ();
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(igr_tdest_t))   axis_host_to_core_p [NUM_CMAC]    ();

    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(igr_tdest_t))  _axis_core_to_app    [NUM_CMAC]    ();
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(igr_tdest_t))  _axis_core_to_bypass               ();

    igr_tdest_t  igr_sw_tdest     [2*NUM_CMAC];

    generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__sw_igr
        axi4s_intf_pipe cmac_to_core_pipe (.axi4s_if_from_tx(axis_cmac_to_core[i]), .axi4s_if_to_rx(axis_cmac_to_core_p[i]));
        axi4s_intf_pipe host_to_core_pipe (.axi4s_if_from_tx(axis_host_to_core[i]), .axi4s_if_to_rx(axis_host_to_core_p[i]));

        // ingress tdest configuration logic.
        always @(posedge core_clk) begin
           if (axis_cmac_to_core[i].tready && axis_cmac_to_core[i].tvalid && axis_cmac_to_core[i].sop)
              igr_sw_tdest[i] <= smartnic_regs.igr_sw_tdest[i];

           if (axis_host_to_core[i].tready && axis_host_to_core[i].tvalid && axis_host_to_core[i].sop)
              igr_sw_tdest[2+i] <= smartnic_regs.igr_sw_tdest[2+i];
        end

        assign _axis_core_to_app[i].tready = axis_core_to_app[i].tready;

        assign axis_core_to_app[i].aclk    = core_clk;
        assign axis_core_to_app[i].aresetn = core_rstn;
        assign axis_core_to_app[i].tvalid  = _axis_core_to_app[i].tvalid;
        assign axis_core_to_app[i].tdata   = _axis_core_to_app[i].tdata;
        assign axis_core_to_app[i].tkeep   = _axis_core_to_app[i].tkeep;
        assign axis_core_to_app[i].tlast   = _axis_core_to_app[i].tlast;
        assign axis_core_to_app[i].tid     = _axis_core_to_app[i].tid;
        assign axis_core_to_app[i].tuser   = '0;
        assign axis_core_to_app[i].tdest   = {1'b0, _axis_core_to_app[i].tid};

    end : g__sw_igr
    endgenerate

    // tpause logic for bypass ingress traffic (for test purposes).
    assign _axis_core_to_bypass.tready = axis_core_to_bypass.tready && !smartnic_regs.switch_config.igr_sw_tpause;

    assign axis_core_to_bypass.aclk    = core_clk;
    assign axis_core_to_bypass.aresetn = core_rstn;
    assign axis_core_to_bypass.tvalid  = _axis_core_to_bypass.tvalid && !smartnic_regs.switch_config.igr_sw_tpause;
    assign axis_core_to_bypass.tdata   = _axis_core_to_bypass.tdata;
    assign axis_core_to_bypass.tkeep   = _axis_core_to_bypass.tkeep;
    assign axis_core_to_bypass.tlast   = _axis_core_to_bypass.tlast;
    assign axis_core_to_bypass.tid     = _axis_core_to_bypass.tid;
    assign axis_core_to_bypass.tuser   = '0;
    assign axis_core_to_bypass.tdest   = {1'b0, _axis_core_to_bypass.tdest[1:0]};

    // ingress switch logic.
    axis_switch_ingress axis_switch_ingress
    (
     .aclk    ( core_clk ),
     .aresetn ( core_rstn ),

     .m_axis_tdata  ({ _axis_core_to_bypass.tdata  , _axis_core_to_app[1].tdata  , _axis_core_to_app[0].tdata  }),
     .m_axis_tkeep  ({ _axis_core_to_bypass.tkeep  , _axis_core_to_app[1].tkeep  , _axis_core_to_app[0].tkeep  }),
     .m_axis_tlast  ({ _axis_core_to_bypass.tlast  , _axis_core_to_app[1].tlast  , _axis_core_to_app[0].tlast  }),
     .m_axis_tid    ({ _axis_core_to_bypass.tid    , _axis_core_to_app[1].tid    , _axis_core_to_app[0].tid    }),
     .m_axis_tdest  ({ _axis_core_to_bypass.tdest  , _axis_core_to_app[1].tdest  , _axis_core_to_app[0].tdest  }),
     .m_axis_tready ({ _axis_core_to_bypass.tready , _axis_core_to_app[1].tready , _axis_core_to_app[0].tready }),
     .m_axis_tvalid ({ _axis_core_to_bypass.tvalid , _axis_core_to_app[1].tvalid , _axis_core_to_app[0].tvalid }),

     .s_axis_tdata  ({ axis_host_to_core_p[1].tdata  , axis_host_to_core_p[0].tdata  , axis_cmac_to_core_p[1].tdata  , axis_cmac_to_core_p[0].tdata  }),
     .s_axis_tkeep  ({ axis_host_to_core_p[1].tkeep  , axis_host_to_core_p[0].tkeep  , axis_cmac_to_core_p[1].tkeep  , axis_cmac_to_core_p[0].tkeep  }),
     .s_axis_tlast  ({ axis_host_to_core_p[1].tlast  , axis_host_to_core_p[0].tlast  , axis_cmac_to_core_p[1].tlast  , axis_cmac_to_core_p[0].tlast  }),
     .s_axis_tid    ({ axis_host_to_core_p[1].tid    , axis_host_to_core_p[0].tid    , axis_cmac_to_core_p[1].tid    , axis_cmac_to_core_p[0].tid    }),
     .s_axis_tdest  ({ igr_sw_tdest[3]               , igr_sw_tdest[2]               , igr_sw_tdest[1]               , igr_sw_tdest[0]               }),
     .s_axis_tready ({ axis_host_to_core_p[1].tready , axis_host_to_core_p[0].tready , axis_cmac_to_core_p[1].tready , axis_cmac_to_core_p[0].tready }),
     .s_axis_tvalid ({ axis_host_to_core_p[1].tvalid , axis_host_to_core_p[0].tvalid , axis_cmac_to_core_p[1].tvalid , axis_cmac_to_core_p[0].tvalid }),

     .s_decode_err  ()
    );

endmodule // smartnic_sw_igr
