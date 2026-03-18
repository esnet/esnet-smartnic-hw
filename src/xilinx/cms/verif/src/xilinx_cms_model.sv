module xilinx_cms_model (
    input logic cms_clk,
    input logic cms_srst,

    axi4l_intf.peripheral axil_if,

    // Timing control
    input int   mb_boot_time = 100,

    // Error injection
    input logic error_no_sn_key = 1'b0,
    input logic error_no_sn_terminator = 1'b0
);
    logic mb_timer_done;
    int mb_timer;

    cms_reg_intf cms_reg_if ();

    cms_reg_blk cms_reg_blk_0 (
        .axil_if    ( axil_if ),
        .reg_blk_if ( cms_reg_if )
    );

    assign cms_reg_if.host_status2_reg_nxt_v = 1'b1;
    assign cms_reg_if.host_status2_reg_nxt[0] = cms_reg_if.mb_resetn_reg[0];

    initial begin
        cms_reg_if.reg_map_id_reg_nxt = 32'h0;
        cms_reg_if.host_status2_reg_nxt[0] = 0;
    end
    always_ff @(posedge cms_clk) begin
        if (cms_srst) begin
            cms_reg_if.reg_map_id_reg_nxt = 32'h0;
            cms_reg_if.host_status2_reg_nxt[0] <= 0;
        end
        else if (cms_reg_if.mb_resetn_reg[0] && mb_timer_done) begin
            cms_reg_if.reg_map_id_reg_nxt = 32'h74736574;
            cms_reg_if.host_status2_reg_nxt[0] <= 1'b1;
        end else begin
            cms_reg_if.reg_map_id_reg_nxt = 32'h0;
            cms_reg_if.host_status2_reg_nxt[0] = 0;
        end
    end

    initial mb_timer = 0;
    always @(posedge cms_clk) begin
        if (cms_srst) mb_timer <= 0;
        else if (cms_reg_if.mb_resetn_reg[0]) mb_timer <= mb_timer + 1;
        else mb_timer <= 0;
    end

    assign mb_timer_done = (mb_timer >= mb_boot_time);

    assign cms_reg_if.host_msg_offset_reg_nxt_v = 1'b1;
    assign cms_reg_if.host_msg_offset_reg_nxt = 32'h1000;

    assign cms_reg_if.reg_map_id_reg_nxt_v = 1'b1;

    // Mailbox request is self-clearing
    always @(posedge cms_clk) begin
        if (cms_reg_if.control_reg.mailbox_msg_status) force cms_reg_blk_0.control_reg_reg._reg = '0;
        else release cms_reg_blk_0.control_reg_reg._reg;
    end

    assign cms_reg_if.mailbox_nxt_v[0] = 1'b1;
    always @(posedge cms_clk) begin
        if (axil_to_cms.awaddr == cms_reg_pkg::OFFSET_MAILBOX[0] && axil_to_cms.wvalid && axil_to_cms.wready) begin
            cms_reg_if.mailbox_nxt[0] <= axil_to_cms.wdata;
        end else if (cms_reg_if.control_reg.mailbox_msg_status && cms_reg_if.mailbox[0][31:24] == 8'h04) begin
            cms_reg_if.mailbox_nxt[0] <= cms_reg_if.mailbox[0] | 8'h3b;
        end
    end

    for (genvar g_reg = 1; g_reg < 16; g_reg++) begin : g__reg
        assign cms_reg_if.mailbox_nxt_v[g_reg] = 1'b1;
    end : g__reg
    assign cms_reg_if.mailbox_nxt[1]  = {8'h4c,8'h41,8'h0d,8'h27};
    assign cms_reg_if.mailbox_nxt[2]  = {8'h20,8'h4f,8'h45,8'h56};
    assign cms_reg_if.mailbox_nxt[3]  = {8'h20,8'h30,8'h35,8'h55};
    assign cms_reg_if.mailbox_nxt[4]  = {8'h26,8'h00,8'h51,8'h50};
    assign cms_reg_if.mailbox_nxt[5]  = error_no_sn_key ? {8'h20,8'h00,8'h31,8'h02} : {8'h21,8'h00,8'h31,8'h02};
    assign cms_reg_if.mailbox_nxt[6]  = {8'h31,8'h30,8'h35,8'h0d};
    assign cms_reg_if.mailbox_nxt[7]  = {8'h31,8'h31,8'h31,8'h32};
    assign cms_reg_if.mailbox_nxt[8]  = {8'h50,8'h53,8'h43,8'h39};
    assign cms_reg_if.mailbox_nxt[9]  = error_no_sn_terminator ? {8'h08,8'h4b,8'h01,8'h4d} : {8'h08,8'h4b,8'h00,8'h4d};
    assign cms_reg_if.mailbox_nxt[10] = {8'h0a,8'h00,8'h00,8'h04};
    assign cms_reg_if.mailbox_nxt[11] = {8'hd8,8'h0f,8'h05,8'h35};
    assign cms_reg_if.mailbox_nxt[12] = {8'h2b,8'h50,8'h01,8'h2a};
    assign cms_reg_if.mailbox_nxt[13] = {8'h01,8'h29,8'h07,8'h01};
    assign cms_reg_if.mailbox_nxt[14] = {8'h35,8'h04,8'h28,8'h00};
    assign cms_reg_if.mailbox_nxt[15] = {8'h00,8'h00,8'h30,8'h2e};

endmodule : xilinx_cms_model


