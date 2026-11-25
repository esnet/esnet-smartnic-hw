// Native IP boundary model for host/adapter integration tests.
// This drives the IP-facing streams and AXI-L bus without simulating PCIe.
module xilinx_alveo_usplus_qdma (
    input  wire                sys_clk,
    input  wire                sys_clk_gt,
    input  wire                sys_rst_n,
    output wire                user_lnk_up,
    output wire [15 : 0]       pci_exp_txp,
    output wire [15 : 0]       pci_exp_txn,
    input  wire [15 : 0]       pci_exp_rxp,
    input  wire [15 : 0]       pci_exp_rxn,
    output wire                axi_aclk,
    output wire                axi_aresetn,
    input  wire                usr_irq_in_vld,
    input  wire [10 : 0]       usr_irq_in_vec,
    input  wire [7 : 0]        usr_irq_in_fnc,
    output wire                usr_irq_out_ack,
    output wire                usr_irq_out_fail,
    output logic [7:0]         usr_flr_fnc = '0,
    output logic               usr_flr_set = 1'b0,
    input wire [7:0]           usr_flr_done_fnc,
    input wire                 usr_flr_done_vld,
    output wire [255 : 0]      h2c_byp_out_dsc,
    output wire                h2c_byp_out_st_mm,
    output wire [1 : 0]        h2c_byp_out_dsc_sz,
    output wire [10 : 0]       h2c_byp_out_qid,
    output wire                h2c_byp_out_error,
    output wire [7 : 0]        h2c_byp_out_func,
    output wire [15 : 0]       h2c_byp_out_cidx,
    output wire [2 : 0]        h2c_byp_out_port_id,
    output wire                h2c_byp_out_vld,
    input  wire                h2c_byp_out_rdy,
    output wire [3 : 0]        h2c_byp_out_fmt,
    output wire [255 : 0]      c2h_byp_out_dsc,
    output wire                c2h_byp_out_st_mm,
    output wire [10 : 0]       c2h_byp_out_qid,
    output wire [1 : 0]        c2h_byp_out_dsc_sz,
    output wire                c2h_byp_out_error,
    output wire [7 : 0]        c2h_byp_out_func,
    output wire [15 : 0]       c2h_byp_out_cidx,
    output wire [2 : 0]        c2h_byp_out_port_id,
    output wire                c2h_byp_out_vld,
    input  wire                c2h_byp_out_rdy,
    output wire [3 : 0]        c2h_byp_out_fmt,
    output wire [6 : 0]        c2h_byp_out_pfch_tag,
    input  wire [63 : 0]       c2h_byp_in_st_csh_addr,
    input  wire [2 : 0]        c2h_byp_in_st_csh_port_id,
    input  wire [10 : 0]       c2h_byp_in_st_csh_qid,
    input  wire                c2h_byp_in_st_csh_error,
    input  wire [7 : 0]        c2h_byp_in_st_csh_func,
    input  wire                c2h_byp_in_st_csh_vld,
    output wire                c2h_byp_in_st_csh_rdy,
    input  wire [6 : 0]        c2h_byp_in_st_csh_pfch_tag,
    input  wire [63 : 0]       h2c_byp_in_st_addr,
    input  wire [15 : 0]       h2c_byp_in_st_len,
    input  wire                h2c_byp_in_st_eop,
    input  wire                h2c_byp_in_st_sop,
    input  wire                h2c_byp_in_st_mrkr_req,
    input  wire [2 : 0]        h2c_byp_in_st_port_id,
    input  wire                h2c_byp_in_st_sdi,
    input  wire [10 : 0]       h2c_byp_in_st_qid,
    input  wire                h2c_byp_in_st_error,
    input  wire [7 : 0]        h2c_byp_in_st_func,
    input  wire [15 : 0]       h2c_byp_in_st_cidx,
    input  wire                h2c_byp_in_st_no_dma,
    input  wire                h2c_byp_in_st_vld,
    output wire                h2c_byp_in_st_rdy,
    output wire                tm_dsc_sts_vld,
    output wire [2 : 0]        tm_dsc_sts_port_id,
    output wire                tm_dsc_sts_qen,
    output wire                tm_dsc_sts_byp,
    output wire                tm_dsc_sts_dir,
    output wire                tm_dsc_sts_mm,
    output wire                tm_dsc_sts_error,
    output wire [10 : 0]       tm_dsc_sts_qid,
    output wire [15 : 0]       tm_dsc_sts_avl,
    output wire                tm_dsc_sts_qinv,
    output wire                tm_dsc_sts_irq_arm,
    input  wire                tm_dsc_sts_rdy,
    output wire [15 : 0]       tm_dsc_sts_pidx,
    input  wire [15 : 0]       dsc_crdt_in_crdt,
    input  wire [10 : 0]       dsc_crdt_in_qid,
    input  wire                dsc_crdt_in_dir,
    input  wire                dsc_crdt_in_fence,
    input  wire                dsc_crdt_in_vld,
    output wire                dsc_crdt_in_rdy,
    output wire [31 : 0]       m_axil_awaddr,
    output wire [54 : 0]       m_axil_awuser,
    output wire [2 : 0]        m_axil_awprot,
    output wire                m_axil_awvalid,
    input  wire                m_axil_awready,
    output wire [31 : 0]       m_axil_wdata,
    output wire [3 : 0]        m_axil_wstrb,
    output wire                m_axil_wvalid,
    input  wire                m_axil_wready,
    input  wire                m_axil_bvalid,
    input  wire [1 : 0]        m_axil_bresp,
    output wire                m_axil_bready,
    output wire [31 : 0]       m_axil_araddr,
    output wire [54 : 0]       m_axil_aruser,
    output wire [2 : 0]        m_axil_arprot,
    output wire                m_axil_arvalid,
    input  wire                m_axil_arready,
    input  wire [31 : 0]       m_axil_rdata,
    input  wire [1 : 0]        m_axil_rresp,
    input  wire                m_axil_rvalid,
    output wire                m_axil_rready,
    output wire [511 : 0]      m_axis_h2c_tdata,
    output wire [31 : 0]       m_axis_h2c_tcrc,
    output wire [10 : 0]       m_axis_h2c_tuser_qid,
    output wire [2 : 0]        m_axis_h2c_tuser_port_id,
    output wire                m_axis_h2c_tuser_err,
    output wire [31 : 0]       m_axis_h2c_tuser_mdata,
    output wire [5 : 0]        m_axis_h2c_tuser_mty,
    output wire                m_axis_h2c_tuser_zero_byte,
    output wire                m_axis_h2c_tvalid,
    output wire                m_axis_h2c_tlast,
    input  wire                m_axis_h2c_tready,
    input  wire [511 : 0]      s_axis_c2h_tdata,
    input  wire [31 : 0]       s_axis_c2h_tcrc,
    input  wire                s_axis_c2h_ctrl_marker,
    input  wire [2 : 0]        s_axis_c2h_ctrl_port_id,
    input  wire [6 : 0]        s_axis_c2h_ctrl_ecc,
    input  wire [15 : 0]       s_axis_c2h_ctrl_len,
    input  wire [10 : 0]       s_axis_c2h_ctrl_qid,
    input  wire                s_axis_c2h_ctrl_has_cmpt,
    input  wire [5 : 0]        s_axis_c2h_mty,
    input  wire                s_axis_c2h_tvalid,
    input  wire                s_axis_c2h_tlast,
    output wire                s_axis_c2h_tready,
    input  wire [511 : 0]      s_axis_c2h_cmpt_tdata,
    input  wire [1 : 0]        s_axis_c2h_cmpt_size,
    input  wire [15 : 0]       s_axis_c2h_cmpt_dpar,
    input  wire                s_axis_c2h_cmpt_tvalid,
    input  wire [10 : 0]       s_axis_c2h_cmpt_ctrl_qid,
    input  wire [1 : 0]        s_axis_c2h_cmpt_ctrl_cmpt_type,
    input  wire [15 : 0]       s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id,
    input  wire [2 : 0]        s_axis_c2h_cmpt_ctrl_port_id,
    input  wire                s_axis_c2h_cmpt_ctrl_marker,
    input  wire                s_axis_c2h_cmpt_ctrl_user_trig,
    input  wire [2 : 0]        s_axis_c2h_cmpt_ctrl_col_idx,
    input  wire [2 : 0]        s_axis_c2h_cmpt_ctrl_err_idx,
    output wire                s_axis_c2h_cmpt_tready,
    input  wire                s_axis_c2h_cmpt_ctrl_no_wrb_marker,
    output wire                axis_c2h_status_drop,
    output wire                axis_c2h_status_valid,
    output wire                axis_c2h_status_cmp,
    output wire                axis_c2h_status_error,
    output wire                axis_c2h_status_last,
    output wire [10 : 0]       axis_c2h_status_qid,
    output wire                axis_c2h_dmawr_cmp,
    input  wire                soft_reset_n,
    output wire                phy_ready,
    output wire [7 : 0]        qsts_out_op,
    output wire [63 : 0]       qsts_out_data,
    output wire [2 : 0]        qsts_out_port_id,
    output wire [12 : 0]       qsts_out_qid,
    output wire                qsts_out_vld,
    input  wire                qsts_out_rdy
);
    axi4l_intf axil_test_if ();
    assign axi_aclk = sys_clk_gt;
    assign axi_aresetn = sys_rst_n;
    assign axil_test_if.aclk = axi_aclk;
    assign axil_test_if.aresetn = axi_aresetn;

    logic [511:0] tb_h2c_data = '0;
    logic [31:0] tb_h2c_crc = '0;
    logic [10:0] tb_h2c_qid = '0;
    logic [5:0] tb_h2c_mty = '0;
    logic tb_h2c_valid = 0, tb_h2c_last = 0, tb_h2c_err = 0;
    logic tb_c2h_ready = 1, tb_cmpt_ready = 1;
    byte c2h_bytes[$];
    int c2h_beats = 0, c2h_packets = 0, cmpt_packets = 0;
    logic [15:0] last_len, last_cmpt_id;
    logic [10:0] last_qid;
    logic [31:0] last_crc;
    logic [511:0] last_cmpt;
    assign user_lnk_up = sys_rst_n;
    assign pci_exp_txp = '0;
    assign pci_exp_txn = '0;
    assign usr_irq_out_ack = '0;
    assign usr_irq_out_fail = '0;
    assign h2c_byp_out_dsc = '0;
    assign h2c_byp_out_st_mm = '0;
    assign h2c_byp_out_dsc_sz = '0;
    assign h2c_byp_out_qid = '0;
    assign h2c_byp_out_error = '0;
    assign h2c_byp_out_func = '0;
    assign h2c_byp_out_cidx = '0;
    assign h2c_byp_out_port_id = '0;
    assign h2c_byp_out_vld = '0;
    assign h2c_byp_out_fmt = '0;
    assign c2h_byp_out_dsc = '0;
    assign c2h_byp_out_st_mm = '0;
    assign c2h_byp_out_qid = '0;
    assign c2h_byp_out_dsc_sz = '0;
    assign c2h_byp_out_error = '0;
    assign c2h_byp_out_func = '0;
    assign c2h_byp_out_cidx = '0;
    assign c2h_byp_out_port_id = '0;
    assign c2h_byp_out_vld = '0;
    assign c2h_byp_out_fmt = '0;
    assign c2h_byp_out_pfch_tag = '0;
    assign c2h_byp_in_st_csh_rdy = '0;
    assign h2c_byp_in_st_rdy = '0;
    assign tm_dsc_sts_vld = '0;
    assign tm_dsc_sts_port_id = '0;
    assign tm_dsc_sts_qen = '0;
    assign tm_dsc_sts_byp = '0;
    assign tm_dsc_sts_dir = '0;
    assign tm_dsc_sts_mm = '0;
    assign tm_dsc_sts_error = '0;
    assign tm_dsc_sts_qid = '0;
    assign tm_dsc_sts_avl = '0;
    assign tm_dsc_sts_qinv = '0;
    assign tm_dsc_sts_irq_arm = '0;
    assign tm_dsc_sts_pidx = '0;
    assign dsc_crdt_in_rdy = 1'b1;
    assign m_axil_awaddr = axil_test_if.awaddr;
    assign m_axil_awuser = '0;
    assign m_axil_awprot = axil_test_if.awprot;
    assign m_axil_awvalid = axil_test_if.awvalid;
    assign axil_test_if.awready = m_axil_awready;
    assign m_axil_wdata = axil_test_if.wdata;
    assign m_axil_wstrb = axil_test_if.wstrb;
    assign m_axil_wvalid = axil_test_if.wvalid;
    assign axil_test_if.wready = m_axil_wready;
    assign axil_test_if.bvalid = m_axil_bvalid;
    assign axil_test_if.bresp = m_axil_bresp;
    assign m_axil_bready = axil_test_if.bready;
    assign m_axil_araddr = axil_test_if.araddr;
    assign m_axil_aruser = '0;
    assign m_axil_arprot = axil_test_if.arprot;
    assign m_axil_arvalid = axil_test_if.arvalid;
    assign axil_test_if.arready = m_axil_arready;
    assign axil_test_if.rdata = m_axil_rdata;
    assign axil_test_if.rresp = m_axil_rresp;
    assign axil_test_if.rvalid = m_axil_rvalid;
    assign m_axil_rready = axil_test_if.rready;
    assign m_axis_h2c_tdata = tb_h2c_data;
    assign m_axis_h2c_tcrc = tb_h2c_crc;
    assign m_axis_h2c_tuser_qid = tb_h2c_qid;
    assign m_axis_h2c_tuser_port_id = '0;
    assign m_axis_h2c_tuser_err = tb_h2c_err;
    assign m_axis_h2c_tuser_mdata = '0;
    assign m_axis_h2c_tuser_mty = tb_h2c_mty;
    assign m_axis_h2c_tuser_zero_byte = '0;
    assign m_axis_h2c_tvalid = tb_h2c_valid;
    assign m_axis_h2c_tlast = tb_h2c_last;
    assign s_axis_c2h_tready = tb_c2h_ready;
    assign s_axis_c2h_cmpt_tready = tb_cmpt_ready;
    assign axis_c2h_status_drop = '0;
    assign axis_c2h_status_valid = '0;
    assign axis_c2h_status_cmp = '0;
    assign axis_c2h_status_error = '0;
    assign axis_c2h_status_last = '0;
    assign axis_c2h_status_qid = '0;
    assign axis_c2h_dmawr_cmp = '0;
    assign phy_ready = sys_rst_n;
    assign qsts_out_op = '0;
    assign qsts_out_data = '0;
    assign qsts_out_port_id = '0;
    assign qsts_out_qid = '0;
    assign qsts_out_vld = '0;

    task automatic send_h2c(input byte data[], input logic [10:0] qid,
                            input logic [31:0] tcrc, input bit err = 0);
        int n;
        for (int offset = 0; offset < data.size(); offset += 64) begin
            n = data.size() - offset;
            if (n > 64) n = 64;
            @(negedge axi_aclk);
            tb_h2c_data = '0;
            for (int i = 0; i < n; i++) tb_h2c_data[i*8 +: 8] = data[offset+i];
            tb_h2c_qid = qid;
            tb_h2c_crc = tcrc;
            tb_h2c_err = err;
            tb_h2c_mty = 6'(64-n);
            tb_h2c_last = offset+n == data.size();
            tb_h2c_valid = 1;
            do @(posedge axi_aclk); while (!m_axis_h2c_tready);
        end
        @(negedge axi_aclk);
        tb_h2c_valid = 0;
    endtask

    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            c2h_bytes.delete();
            c2h_beats = 0;
            c2h_packets = 0;
            cmpt_packets = 0;
            last_len = 0;
            last_qid = 0;
            last_crc = 0;
            last_cmpt = '0;
            last_cmpt_id = 0;
        end else begin
            if (s_axis_c2h_tvalid && s_axis_c2h_tready) begin
                c2h_beats++;
                for (int i = 0; i < (s_axis_c2h_tlast ? 64-s_axis_c2h_mty : 64); i++)
                    c2h_bytes.push_back(s_axis_c2h_tdata[i*8 +: 8]);
                if (s_axis_c2h_tlast) begin
                    c2h_packets++;
                    last_len = s_axis_c2h_ctrl_len;
                    last_qid = s_axis_c2h_ctrl_qid;
                    last_crc = s_axis_c2h_tcrc;
                end
            end
            if (s_axis_c2h_cmpt_tvalid && s_axis_c2h_cmpt_tready) begin
                cmpt_packets++;
                last_cmpt = s_axis_c2h_cmpt_tdata;
                last_cmpt_id = s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id;
            end
        end
    end
endmodule

module xilinx_alveo_usplus_clk_axil (input wire clk_in1, output logic clk_out1 = 0);
    always @(posedge clk_in1) clk_out1 <= ~clk_out1;
endmodule

// The ILA is observational and has no behavior in this boundary test.
module xilinx_alveo_usplus_axil_ila (
    input wire clk,
    input wire [0:0] probe0,
    input wire [31:0] probe1,
    input wire [1:0] probe2,
    input wire [0:0] probe3,
    input wire [0:0] probe4,
    input wire [31:0] probe5,
    input wire [0:0] probe6,
    input wire [0:0] probe7,
    input wire [0:0] probe8,
    input wire [0:0] probe9,
    input wire [31:0] probe10,
    input wire [0:0] probe11,
    input wire [0:0] probe12,
    input wire [1:0] probe13,
    input wire [31:0] probe14,
    input wire [3:0] probe15,
    input wire [0:0] probe16,
    input wire [2:0] probe17,
    input wire [2:0] probe18
);
endmodule
