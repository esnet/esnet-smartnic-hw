module smartnic_sw_egr
#(
    parameter int  NUM_CMAC = 2
) (
    input logic     core_clk,
    input logic     core_rstn,

    axi4s_intf.rx   axis_bypass_to_core,
    axi4s_intf.rx   axis_app_to_core    [NUM_CMAC],
    axi4s_intf.tx   axis_core_to_cmac   [NUM_CMAC],
    axi4s_intf.tx   axis_core_to_host   [NUM_CMAC],

    smartnic_reg_intf.peripheral   smartnic_regs
);
    import smartnic_pkg::*;

    // ----------------------------------------------------------------
    //  axi4s interface instantiations
    // ----------------------------------------------------------------
    axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                  .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(egr_tdest_t))   axis_app_to_core_p [NUM_CMAC] ();
    axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                  .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(egr_tdest_t))  _axis_core_to_cmac [NUM_CMAC] ();
    axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                  .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(egr_tdest_t))  _axis_core_to_host [NUM_CMAC] ();

    // muxing logic for tdest-to-tdest re-mapping.
    port_t  axis_app_to_core_p_tdest [NUM_CMAC];
    port_t  tdest_remap_mux_select   [NUM_CMAC];

    // tdest-to-tdest re-mapping for app_to_core[0].
    assign tdest_remap_mux_select[0] = (axis_app_to_core[0].tdest == LOOPBACK) ? {1'b0, axis_app_to_core[0].tid} : axis_app_to_core[0].tdest.raw[1:0];

    always @(posedge core_clk) begin
       if (axis_app_to_core[0].tready && axis_app_to_core[0].tvalid && axis_app_to_core[0].sop) begin
          case (tdest_remap_mux_select[0])
             CMAC_PORT0 : axis_app_to_core_p_tdest[0] <= smartnic_regs.app_0_tdest_remap[0];
             CMAC_PORT1 : axis_app_to_core_p_tdest[0] <= smartnic_regs.app_0_tdest_remap[1];
             HOST_PORT0 : axis_app_to_core_p_tdest[0] <= smartnic_regs.app_0_tdest_remap[2];
             HOST_PORT1 : axis_app_to_core_p_tdest[0] <= smartnic_regs.app_0_tdest_remap[3];
          endcase
        end
    end

    // tdest-to-tdest re-mapping for app_to_core[1].
    assign tdest_remap_mux_select[1] = (axis_app_to_core[1].tdest == LOOPBACK) ? {1'b0, axis_app_to_core[1].tid} : axis_app_to_core[1].tdest.raw[1:0];

    always @(posedge core_clk) begin
       if (axis_app_to_core[1].tready && axis_app_to_core[1].tvalid && axis_app_to_core[1].sop) begin
          case (tdest_remap_mux_select[1])
             CMAC_PORT0 : axis_app_to_core_p_tdest[1] <= smartnic_regs.app_1_tdest_remap[0];
             CMAC_PORT1 : axis_app_to_core_p_tdest[1] <= smartnic_regs.app_1_tdest_remap[1];
             HOST_PORT0 : axis_app_to_core_p_tdest[1] <= smartnic_regs.app_1_tdest_remap[2];
             HOST_PORT1 : axis_app_to_core_p_tdest[1] <= smartnic_regs.app_1_tdest_remap[3];
          endcase
       end
    end

    logic [12:0] axis_app_to_core_p_tuser [NUM_CMAC];
    assign axis_app_to_core_p_tuser[0] = {axis_app_to_core_p[0].tuser.rss_enable, axis_app_to_core_p[0].tuser.rss_entropy};
    assign axis_app_to_core_p_tuser[1] = {axis_app_to_core_p[1].tuser.rss_enable, axis_app_to_core_p[1].tuser.rss_entropy};

    logic [12:0] _axis_core_to_host_tuser [NUM_CMAC];
    assign _axis_core_to_host[0].tuser.pid         = '0;
    assign _axis_core_to_host[0].tuser.rss_enable  = _axis_core_to_host_tuser[0][12];
    assign _axis_core_to_host[0].tuser.rss_entropy = _axis_core_to_host_tuser[0][11:0];
    assign _axis_core_to_host[0].tuser.hdr_tlast   = '0;
    assign _axis_core_to_host[1].tuser.pid         = '0;
    assign _axis_core_to_host[1].tuser.rss_enable  = _axis_core_to_host_tuser[1][12];
    assign _axis_core_to_host[1].tuser.rss_entropy = _axis_core_to_host_tuser[1][11:0];
    assign _axis_core_to_host[1].tuser.hdr_tlast   = '0;

    logic [12:0] _axis_core_to_cmac_tuser [NUM_CMAC];
    assign _axis_core_to_cmac[0].tuser = '0;
    assign _axis_core_to_cmac[1].tuser = '0;

    axis_switch_egress axis_switch_egress
    (
     .aclk    ( core_clk ),
     .aresetn ( core_rstn ),

     .m_axis_tdata  ({ _axis_core_to_host[1].tdata  , _axis_core_to_host[0].tdata  , _axis_core_to_cmac[1].tdata  , _axis_core_to_cmac[0].tdata  }),
     .m_axis_tkeep  ({ _axis_core_to_host[1].tkeep  , _axis_core_to_host[0].tkeep  , _axis_core_to_cmac[1].tkeep  , _axis_core_to_cmac[0].tkeep  }),
     .m_axis_tlast  ({ _axis_core_to_host[1].tlast  , _axis_core_to_host[0].tlast  , _axis_core_to_cmac[1].tlast  , _axis_core_to_cmac[0].tlast  }),
     .m_axis_tid    ({ _axis_core_to_host[1].tid    , _axis_core_to_host[0].tid    , _axis_core_to_cmac[1].tid    , _axis_core_to_cmac[0].tid    }),
     .m_axis_tdest  ({ _axis_core_to_host[1].tdest[1:0] , _axis_core_to_host[0].tdest[1:0] , _axis_core_to_cmac[1].tdest[1:0] , _axis_core_to_cmac[0].tdest[1:0] }),
     .m_axis_tuser  ({ _axis_core_to_host_tuser[1]  , _axis_core_to_host_tuser[0]  , _axis_core_to_cmac_tuser[1]  , _axis_core_to_cmac_tuser[0]  }),
     .m_axis_tready ({ _axis_core_to_host[1].tready , _axis_core_to_host[0].tready , _axis_core_to_cmac[1].tready , _axis_core_to_cmac[0].tready }),
     .m_axis_tvalid ({ _axis_core_to_host[1].tvalid , _axis_core_to_host[0].tvalid , _axis_core_to_cmac[1].tvalid , _axis_core_to_cmac[0].tvalid }),

     .s_axis_tdata  ({ axis_bypass_to_core.tdata  , axis_app_to_core_p[1].tdata  , axis_app_to_core_p[0].tdata  }),
     .s_axis_tkeep  ({ axis_bypass_to_core.tkeep  , axis_app_to_core_p[1].tkeep  , axis_app_to_core_p[0].tkeep  }),
     .s_axis_tlast  ({ axis_bypass_to_core.tlast  , axis_app_to_core_p[1].tlast  , axis_app_to_core_p[0].tlast  }),
     .s_axis_tid    ({ axis_bypass_to_core.tid    , axis_app_to_core_p[1].tid    , axis_app_to_core_p[0].tid    }),
     .s_axis_tdest  ({ axis_bypass_to_core.tdest  , axis_app_to_core_p_tdest[1]  , axis_app_to_core_p_tdest[0]  }),
     .s_axis_tuser  ({                  13'h0000  , axis_app_to_core_p_tuser[1]  , axis_app_to_core_p_tuser[0]  }),
     .s_axis_tready ({ axis_bypass_to_core.tready , axis_app_to_core_p[1].tready , axis_app_to_core_p[0].tready }),
     .s_axis_tvalid ({ axis_bypass_to_core.tvalid , axis_app_to_core_p[1].tvalid , axis_app_to_core_p[0].tvalid }),

     .s_decode_err ()
    );

    generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__mux_demux
        axi4s_intf_pipe axis_app_to_core_pipe (.axi4s_if_from_tx(axis_app_to_core[i]), .axi4s_if_to_rx(axis_app_to_core_p[i]));

        assign _axis_core_to_cmac[i].tready = axis_core_to_cmac[i].tready;

        assign axis_core_to_cmac[i].aclk    = core_clk;
        assign axis_core_to_cmac[i].aresetn = core_rstn;
        assign axis_core_to_cmac[i].tvalid  = _axis_core_to_cmac[i].tvalid;
        assign axis_core_to_cmac[i].tdata   = _axis_core_to_cmac[i].tdata;
        assign axis_core_to_cmac[i].tkeep   = _axis_core_to_cmac[i].tkeep;
        assign axis_core_to_cmac[i].tlast   = _axis_core_to_cmac[i].tlast;
        assign axis_core_to_cmac[i].tid     = _axis_core_to_cmac[i].tid;
        assign axis_core_to_cmac[i].tuser   = '0;
        assign axis_core_to_cmac[i].tdest   = {1'b0, _axis_core_to_cmac[i].tdest[1:0]};

        assign _axis_core_to_host[i].tready = axis_core_to_host[i].tready;

        assign axis_core_to_host[i].aclk    = core_clk;
        assign axis_core_to_host[i].aresetn = core_rstn;
        assign axis_core_to_host[i].tvalid  = _axis_core_to_host[i].tvalid;
        assign axis_core_to_host[i].tdata   = _axis_core_to_host[i].tdata;
        assign axis_core_to_host[i].tkeep   = _axis_core_to_host[i].tkeep;
        assign axis_core_to_host[i].tlast   = _axis_core_to_host[i].tlast;
        assign axis_core_to_host[i].tid     = _axis_core_to_host[i].tid;
        assign axis_core_to_host[i].tuser.pid         = '0;
        assign axis_core_to_host[i].tuser.rss_enable  = _axis_core_to_host[i].tuser.rss_enable;
        assign axis_core_to_host[i].tuser.rss_entropy = _axis_core_to_host[i].tuser.rss_entropy;
        assign axis_core_to_host[i].tuser.hdr_tlast   = '0;
        assign axis_core_to_host[i].tdest   = {1'b0, _axis_core_to_host[i].tdest[1:0]};

    end : g__mux_demux
    endgenerate

endmodule // smartnic_sw_egr
