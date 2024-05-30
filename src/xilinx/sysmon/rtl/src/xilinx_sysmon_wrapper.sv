// See https://docs.xilinx.com/v/u/en-US/ug580-ultrascale-sysmon

module xilinx_sysmon_wrapper (
    axi4l_intf.peripheral axil_if
);
    // =========================================================================
    // Imports
    // =========================================================================
    import xilinx_sysmon_pkg::*;

    // =========================================================================
    // Signals
    // =========================================================================
    logic s_axi_aclk;
    logic s_axi_aresetn;
    logic [12 : 0] s_axi_awaddr;
    logic s_axi_awvalid;
    logic s_axi_awready;
    logic [31 : 0] s_axi_wdata;
    logic [3 : 0] s_axi_wstrb;
    logic s_axi_wvalid;
    logic s_axi_wready;
    logic [1 : 0] s_axi_bresp;
    logic s_axi_bvalid;
    logic s_axi_bready;
    logic [12 : 0] s_axi_araddr;
    logic s_axi_arvalid;
    logic s_axi_arready;
    logic [31 : 0] s_axi_rdata;
    logic [1 : 0] s_axi_rresp;
    logic s_axi_rvalid;
    logic s_axi_rready;
    logic ip2intc_irpt;
    logic vp;
    logic vn;
    logic [5 : 0] channel_out;
    logic eoc_out;
    logic alarm_out;
    logic eos_out;
    logic busy_out;

    // =========================================================================
    // AXI-L register access
    // =========================================================================
    assign s_axi_aclk = axil_if.aclk;       // input wire s_axi_aclk
    assign s_axi_aresetn = axil_if.aresetn; // input wire s_axi_sreset
    assign s_axi_awaddr = axil_if.awaddr;   // input wire [31 : 0] s_axi_awaddr
    assign s_axi_awvalid = axil_if.awvalid; // input wire s_axi_awvalid
    assign axil_if.awready = s_axi_awready; // output wire s_axi_awready
    assign s_axi_wdata = axil_if.wdata;     // input wire [31 : 0] s_axi_wdata
    assign s_axi_wstrb = axil_if.wstrb;     // input wire [3 : 0] s_axi_wstrb
    assign s_axi_wvalid = axil_if.wvalid;   // input wire s_axi_wvalid
    assign axil_if.wready = s_axi_wready;   // output wire s_axi_wready
    assign axil_if.bresp = s_axi_bresp;     // output wire [1 : 0] s_axi_bresp
    assign axil_if.bvalid = s_axi_bvalid;   // output wire s_axi_bvalid
    assign s_axi_bready = axil_if.bready;   // input wire s_axi_bready
    assign s_axi_araddr = axil_if.araddr;   // input wire [31 : 0] s_axi_araddr
    assign s_axi_arvalid = axil_if.arvalid; // input wire s_axi_arvalid
    assign axil_if.arready = s_axi_arready; // output wire s_axi_arready
    assign axil_if.rdata = s_axi_rdata;     // output wire [31 : 0] s_axi_rdata
    assign axil_if.rresp = s_axi_rresp;     // output wire [1 : 0] s_axi_rresp
    assign axil_if.rvalid = s_axi_rvalid;   // output wire s_axi_rvalid
    assign s_axi_rready = axil_if.rready;   // input wire s_axi_rready

    // =========================================================================
    // Analog inputs
    // =========================================================================
    assign vp = 1'b0;
    assign vn = 1'b0;
//
// NOTE: Use instantiation template exactly as provided in IP (including whitespace, but with
//       generic instance name commented out) to enable trivial diffs to simplify upgrades or changes,
//       identify added/removed signals, etc.
//
//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
//xilinx_sysmon your_instance_name (
xilinx_sysmon i_xilinx_sysmon_0 (
  .s_axi_aclk(s_axi_aclk),        // input wire s_axi_aclk
  .s_axi_aresetn(s_axi_aresetn),  // input wire s_axi_aresetn
  .s_axi_awaddr(s_axi_awaddr),    // input wire [12 : 0] s_axi_awaddr
  .s_axi_awvalid(s_axi_awvalid),  // input wire s_axi_awvalid
  .s_axi_awready(s_axi_awready),  // output wire s_axi_awready
  .s_axi_wdata(s_axi_wdata),      // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(s_axi_wstrb),      // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid(s_axi_wvalid),    // input wire s_axi_wvalid
  .s_axi_wready(s_axi_wready),    // output wire s_axi_wready
  .s_axi_bresp(s_axi_bresp),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(s_axi_bvalid),    // output wire s_axi_bvalid
  .s_axi_bready(s_axi_bready),    // input wire s_axi_bready
  .s_axi_araddr(s_axi_araddr),    // input wire [12 : 0] s_axi_araddr
  .s_axi_arvalid(s_axi_arvalid),  // input wire s_axi_arvalid
  .s_axi_arready(s_axi_arready),  // output wire s_axi_arready
  .s_axi_rdata(s_axi_rdata),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(s_axi_rresp),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid(s_axi_rvalid),    // output wire s_axi_rvalid
  .s_axi_rready(s_axi_rready),    // input wire s_axi_rready
  .ip2intc_irpt(ip2intc_irpt),    // output wire ip2intc_irpt
  .vp(vp),                        // input wire vp
  .vn(vn),                        // input wire vn
  .channel_out(channel_out),      // output wire [5 : 0] channel_out
  .eoc_out(eoc_out),              // output wire eoc_out
  .alarm_out(alarm_out),          // output wire alarm_out
  .eos_out(eos_out),              // output wire eos_out
  .busy_out(busy_out)            // output wire busy_out
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

endmodule : xilinx_sysmon_wrapper
