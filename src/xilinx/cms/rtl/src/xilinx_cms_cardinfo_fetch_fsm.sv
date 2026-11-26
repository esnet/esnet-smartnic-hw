module xilinx_cms_cardinfo_fetch_fsm (
  input logic              cms_clk,
  input logic              cms_srst,
  input logic              abort,
  // From controller
  axi4l_intf.peripheral    axil_from_controller,
  // To CMS
  axi4l_intf.controller    axil_to_cms,
  // Card information cache
  output logic             card_info_vld,
  output logic [7:0]       card_info_len,
  input  logic             card_info_rd,
  input  logic [7:0]       card_info_rd_addr,
  output logic [7:0]       card_info_rd_data,
  output logic             card_info_rd_vld,
  // Error status
  output logic             error_boot_timeout,
  output logic             error_bad_axil_transaction,
  output logic             error_card_info_length
);

    wire aclk = cms_clk;
    wire aresetn = !cms_srst;

`ifdef SYNTHESIS
    localparam int DEBOUNCE_CNT = 50*1000;       // 50k 50MHz clock cycles = 1ms
    localparam int BOOT_WAIT = 50*1000*1000;     // 50M 50MHz clock cycles = 1s
    localparam int BOOT_TIMEOUT = 250*1000*1000; // 250M 50MHz clock cycles = 5s
`else
    localparam int DEBOUNCE_CNT = 10;
    localparam int BOOT_WAIT = 50;
    localparam int BOOT_TIMEOUT = 250;
`endif
    localparam int TIMER_WID = $clog2(BOOT_TIMEOUT+1);

    localparam logic [17:0] ADDR__MB_RESETN_REG       = 18'h20000;
    localparam logic [17:0] ADDR__REG_MAP_ID_REG      = 18'h28000;
    localparam logic [17:0] ADDR__CONTROL_REG         = 18'h28018;
    localparam logic [17:0] ADDR__HOST_MSG_OFFSET_REG = 18'h28300;
    localparam logic [17:0] ADDR__HOST_STATUS2_REG    = 18'h2830C;
    localparam logic [17:0] ADDR__MAILBOX_BASE        = 18'h28000;

    localparam logic [31:0] VALUE__REG_MAP_ID = 32'h74736574;

    localparam logic [1:0]  AXIL__RESP_OKAY = 2'b00;

    localparam int CARDINFO_MAX_LEN = 255;
    localparam int CARDINFO_ARRAY_SIZE = 2**($clog2(CARDINFO_MAX_LEN));

    typedef enum logic [4:0] {
        RESET                      = 0,
        RESET_DEBOUNCE             = 1,
        DEASSERT_MB_RESET          = 2,
        INITIAL_BOOT_WAIT          = 3,
        CHECK_REG_MAP_ID           = 4,
        CHECK_REG_MAP_READY        = 5,
        GET_HOST_MSG_OFFSET        = 6,
        CARD_INFO_QUERY_REQ        = 7,
        MAILBOX_REQ                = 8,
        MAILBOX_PENDING            = 9,
        READ_CARD_INFO_LENGTH      = 10,
        READ_MAILBOX_REG           = 11,
        LATCH_MAILBOX_REG          = 12,
        READ_NXT_MAILBOX_REG       = 13,
        CARDINFO_READY             = 14,
        ERROR_BAD_AXIL_TRANSACTION = 15,
        ERROR_BOOT_TIMEOUT         = 16,
        ERROR_CARD_INFO_LENGTH     = 17,
        ASSERT_MB_RESET            = 18,
        DONE                       = 19,
        ABORT_RESET                = 20
    } state_t;

    typedef enum logic [3:0] {
        AXIL_RESET = 0,
        AXIL_IDLE  = 1,
        AXIL_AW_W  = 2,
        AXIL_AW    = 3,
        AXIL_W     = 4,
        AXIL_B     = 5,
        AXIL_AR    = 6,
        AXIL_R     = 7,
        AXIL_DONE  = 8,
        AXIL_ERROR = 9
    } axil_state_t;

    // Signals
    state_t state;
    state_t nxt_state;

    logic   done;
    wire force_abort = abort && !done && state != DONE && state != ABORT_RESET;

    logic                 reset_timer;
    logic                 inc_timer;
    logic [TIMER_WID-1:0] timer;

    logic        wr_req;
    logic        rd_req;

    logic        awvalid;
    logic [17:0] awaddr;
    logic        wvalid;
    logic [31:0] wdata;
    logic        bready;
    logic        arvalid;
    logic [17:0] araddr;
    logic        rready;
    logic [31:0] rdata;

    logic        latch_host_msg_offset;
    logic [17:0] addr_mailbox;

    logic        latch_info_data;
    logic        latch_info_len;
    logic [11:0] info_len;

    logic        reset_idx;
    logic        inc_idx;
    logic [11:0] idx;

    logic        reset_byte_idx;
    logic        inc_byte_idx;
    logic [1:0]  byte_idx;

    logic       cardinfo_valid;
    logic [7:0] cardinfo [CARDINFO_ARRAY_SIZE];

    axil_state_t axil_state;
    axil_state_t nxt_axil_state;

    logic       __error_boot_timeout;
    logic       __error_bad_axil_transaction;
    logic       __error_card_info_length;

    // Main FSM
    initial state = RESET;
    always @(posedge aclk) begin
        if (!aresetn) state <= RESET;
        else          state <= nxt_state;
    end

    always_comb begin
        nxt_state = state;
        reset_timer = 1'b0;
        inc_timer = 1'b0;
        cardinfo_valid = 1'b0;
        wr_req = 1'b0;
        awaddr = '0;
        wdata = '0;
        rd_req = 1'b0;
        araddr = '0;
        latch_host_msg_offset = 1'b0;
        latch_info_len = 1'b0;
        latch_info_data = 1'b0;
        reset_idx = 1'b0;
        inc_idx = 1'b0;
        reset_byte_idx = 1'b0;
        inc_byte_idx = 1'b0;
        __error_boot_timeout = 1'b0;
        __error_bad_axil_transaction = 1'b0;
        __error_card_info_length = 1'b0;
        case (state)
            RESET : begin
                reset_timer = 1'b1;
                nxt_state = RESET_DEBOUNCE;
            end
            RESET_DEBOUNCE : begin
                inc_timer = 1'b1;
                if (timer == DEBOUNCE_CNT) nxt_state = DEASSERT_MB_RESET;
            end
            DEASSERT_MB_RESET : begin
                reset_timer = 1'b1;
                wr_req = 1'b1;
                awaddr = ADDR__MB_RESETN_REG;
                wdata = 32'h1;
                if (axil_state == AXIL_DONE)       nxt_state = INITIAL_BOOT_WAIT;
                else if (axil_state == AXIL_ERROR) nxt_state = ERROR_BAD_AXIL_TRANSACTION;
            end
            INITIAL_BOOT_WAIT : begin
                inc_timer = 1'b1;
                if (timer == BOOT_WAIT) nxt_state = CHECK_REG_MAP_ID;
            end
            CHECK_REG_MAP_ID : begin
                inc_timer = 1'b1;
                rd_req = 1'b1;
                araddr = ADDR__REG_MAP_ID_REG;
                if (axil_state == AXIL_DONE && rdata == VALUE__REG_MAP_ID) nxt_state = CHECK_REG_MAP_READY;
                else if (axil_state == AXIL_ERROR) nxt_state = ERROR_BAD_AXIL_TRANSACTION;
                else if (timer == BOOT_TIMEOUT) nxt_state = ERROR_BOOT_TIMEOUT;
            end
            CHECK_REG_MAP_READY: begin
                rd_req = 1'b1;
                araddr = ADDR__HOST_STATUS2_REG;
                if (axil_state == AXIL_DONE) begin
                  if (rdata[0] == 1'b1) nxt_state = GET_HOST_MSG_OFFSET;
                end else if (axil_state == AXIL_ERROR) nxt_state = ERROR_BAD_AXIL_TRANSACTION;
            end
            GET_HOST_MSG_OFFSET: begin
                rd_req = 1'b1;
                latch_host_msg_offset = 1'b1;
                araddr = ADDR__HOST_MSG_OFFSET_REG;
                if (axil_state == AXIL_DONE) nxt_state = CARD_INFO_QUERY_REQ;
                else if (axil_state == AXIL_ERROR) nxt_state = ERROR_BAD_AXIL_TRANSACTION;
            end
            CARD_INFO_QUERY_REQ: begin
                wr_req = 1'b1;
                awaddr = addr_mailbox;
                wdata = 32'h04000000;
                if (axil_state == AXIL_DONE) nxt_state = MAILBOX_REQ;
                else if (axil_state == AXIL_ERROR) nxt_state = ERROR_BAD_AXIL_TRANSACTION;
            end
            MAILBOX_REQ: begin
                wr_req = 1'b1;
                awaddr = ADDR__CONTROL_REG;
                wdata = 32'h20;
                if (axil_state == AXIL_DONE) nxt_state = MAILBOX_PENDING;
                else if (axil_state == AXIL_ERROR) nxt_state = ERROR_BAD_AXIL_TRANSACTION;
            end
            MAILBOX_PENDING : begin
                rd_req = 1'b1;
                araddr = ADDR__CONTROL_REG;
                if (axil_state == AXIL_DONE) begin
                    if (rdata[5] == 1'b0) nxt_state = READ_CARD_INFO_LENGTH;
                end else if (axil_state == AXIL_ERROR) nxt_state = ERROR_BAD_AXIL_TRANSACTION;
            end
            READ_CARD_INFO_LENGTH: begin
                rd_req = 1'b1;
                reset_idx = 1'b1;
                latch_info_len = 1'b1;
                araddr = addr_mailbox;
                if (axil_state == AXIL_DONE) begin
                    if (rdata[11:0] > 0 && rdata[11:0] <= CARDINFO_MAX_LEN) nxt_state = READ_MAILBOX_REG;
                    else nxt_state = ERROR_CARD_INFO_LENGTH;
                end else if (axil_state == AXIL_ERROR) nxt_state = ERROR_BAD_AXIL_TRANSACTION;
            end
            READ_MAILBOX_REG : begin
                rd_req = 1'b1;
                araddr = addr_mailbox + idx + 4;
                reset_byte_idx = 1'b1;
                if (axil_state == AXIL_DONE) nxt_state = LATCH_MAILBOX_REG;
                else if (axil_state == AXIL_ERROR) nxt_state = ERROR_BAD_AXIL_TRANSACTION;
            end
            LATCH_MAILBOX_REG : begin
                latch_info_data = 1'b1;
                inc_byte_idx = 1'b1;
                if (idx + byte_idx + 1 == info_len) nxt_state = CARDINFO_READY;
                else if (byte_idx == 3) nxt_state = READ_NXT_MAILBOX_REG;
            end
            READ_NXT_MAILBOX_REG : begin
                inc_idx = 1'b1;
                nxt_state = READ_MAILBOX_REG;
            end
            CARDINFO_READY : begin
                cardinfo_valid = 1'b1;
                nxt_state = ASSERT_MB_RESET;
            end
            ERROR_BOOT_TIMEOUT : begin
                __error_boot_timeout = 1'b1;
                nxt_state = ASSERT_MB_RESET;
            end
            ERROR_BAD_AXIL_TRANSACTION : begin
                __error_bad_axil_transaction = 1'b1;
                nxt_state = ASSERT_MB_RESET;
            end
            ERROR_CARD_INFO_LENGTH: begin
                __error_card_info_length = 1'b1;
                nxt_state = ASSERT_MB_RESET;
            end
            ASSERT_MB_RESET : begin
                wr_req = 1'b1;
                awaddr = ADDR__MB_RESETN_REG;
                wdata = 32'h0;
                if (axil_state == AXIL_DONE || axil_state == AXIL_ERROR) nxt_state = DONE;
            end
            ABORT_RESET : begin
                inc_timer = 1'b1;
                if (timer == 15) nxt_state = DONE;
            end
            DONE : begin
            end
        endcase
        if (force_abort) begin
            nxt_state = ABORT_RESET;
            reset_timer = 1'b1;
            inc_timer = 1'b0;
        end
    end

    initial timer = 0;
    always @(posedge aclk) begin
        if (reset_timer) timer <= '0;
        else if (inc_timer) timer <= timer + 1;
    end

    initial addr_mailbox = ADDR__MAILBOX_BASE;
    always @(posedge aclk) if (latch_host_msg_offset) addr_mailbox <= ADDR__MAILBOX_BASE + rdata[17:0];

    initial info_len = '0;
    always @(posedge aclk) if (latch_info_len) info_len <= rdata[11:0];

    initial idx = '0;
    always @(posedge aclk) begin
        if (reset_idx) idx <= 0;
        else if (inc_idx) idx <= idx + 4;
    end

    initial byte_idx = '0;
    always @(posedge aclk) begin
        if (reset_byte_idx) byte_idx <= 0;
        else if (inc_byte_idx) byte_idx <= byte_idx + 1;
    end

    initial cardinfo = '{default: 0};
    always @(posedge aclk) begin
        if (latch_info_data) begin
            cardinfo[idx+byte_idx] <= rdata[byte_idx*8 +: 8];
        end
    end

    initial card_info_vld = 1'b0;
    always @(posedge aclk) begin
        if (!aresetn) card_info_vld <= 1'b0;
        else if (cardinfo_valid) card_info_vld <= 1'b1;
    end

    assign card_info_len = info_len[7:0];

    always_ff @(posedge aclk) if (card_info_rd) card_info_rd_data <= cardinfo[card_info_rd_addr];

    initial card_info_rd_vld = 1'b0;
    always @(posedge aclk) begin
        if (!aresetn) card_info_rd_vld <= 1'b0;
        else begin
            if (card_info_rd) card_info_rd_vld <= 1'b1;
            else              card_info_rd_vld <= 1'b0;
        end
    end

    // Latch error status
    initial begin
        error_boot_timeout = 1'b0;
        error_bad_axil_transaction = 1'b0;
        error_card_info_length = 1'b0;
    end
    always @(posedge aclk) begin
        if (!aresetn) begin
            error_boot_timeout <= 1'b0;
            error_bad_axil_transaction <= 1'b0;
            error_card_info_length <= 1'b0;
        end else begin
            if (__error_boot_timeout) error_boot_timeout <= 1'b1;
            if (__error_bad_axil_transaction) error_bad_axil_transaction <= 1'b1;
            if (__error_card_info_length) error_card_info_length <= 1'b1;
        end
    end

    // AXI-L state machine
    initial axil_state = AXIL_RESET;
    always @(posedge aclk) begin
        if (!aresetn || force_abort || state == ABORT_RESET) axil_state <= AXIL_RESET;
        else          axil_state <= nxt_axil_state;
    end

    always_comb begin
        nxt_axil_state = axil_state;
        awvalid = 1'b0;
        wvalid = 1'b0;
        arvalid = 1'b0;
        bready = 1'b0;
        rready = 1'b0;
        case (axil_state)
            AXIL_RESET : begin
                nxt_axil_state = AXIL_IDLE;
            end
            AXIL_IDLE : begin
                if (wr_req) nxt_axil_state = AXIL_AW_W;
                else if (rd_req) nxt_axil_state = AXIL_AR;
            end
            AXIL_AW_W : begin
                awvalid = 1'b1;
                wvalid = 1'b1;
                if (axil_to_cms.awready && axil_to_cms.wready) nxt_axil_state = AXIL_B;
                else if (axil_to_cms.awready) nxt_axil_state = AXIL_W;
                else if (axil_to_cms.wready) nxt_axil_state = AXIL_AW;
            end
            AXIL_AW : begin
                awvalid = 1'b1;
                if (axil_to_cms.awready) nxt_axil_state = AXIL_B;
            end
            AXIL_W : begin
                wvalid = 1'b1;
                if (axil_to_cms.wready) nxt_axil_state = AXIL_B;
            end
            AXIL_B : begin
                bready = 1'b1;
                if (axil_to_cms.bvalid) begin
                    if (axil_to_cms.bresp == AXIL__RESP_OKAY) nxt_axil_state = AXIL_DONE;
                    else                                     nxt_axil_state = AXIL_ERROR;
                end
            end
            AXIL_AR : begin
                arvalid = 1'b1;
                if (axil_to_cms.arready) nxt_axil_state = AXIL_R;
            end
            AXIL_R : begin
                rready = 1'b1;
                if (axil_to_cms.rvalid) begin
                    if (axil_to_cms.rresp == AXIL__RESP_OKAY) nxt_axil_state = AXIL_DONE;
                    else                                     nxt_axil_state = AXIL_ERROR;
                end
            end
            AXIL_DONE : begin
                nxt_axil_state = AXIL_IDLE;
            end
            AXIL_ERROR : begin
                nxt_axil_state = AXIL_IDLE;
            end
        endcase
    end

    always @(posedge aclk) if (axil_to_cms.rvalid && rready) rdata <= axil_to_cms.rdata;

    // AXI-L mux
    initial done = 1'b0;
    always @(posedge aclk) begin
        if (state == RESET) done <= 1'b0;
        else if (state == DONE) done <= 1'b1;
    end

    assign axil_to_cms.awvalid = done ? axil_from_controller.awvalid : awvalid;
    assign axil_to_cms.awaddr  = done ? axil_from_controller.awaddr[17:0]  : awaddr;
    assign axil_to_cms.awprot  = done ? axil_from_controller.awprot  : '0;
    assign axil_to_cms.wvalid  = done ? axil_from_controller.wvalid  : wvalid;
    assign axil_to_cms.wdata   = done ? axil_from_controller.wdata   : wdata;
    assign axil_to_cms.wstrb   = done ? axil_from_controller.wstrb   : '1;
    assign axil_to_cms.bready  = done ? axil_from_controller.bready  : bready;
    assign axil_to_cms.arvalid = done ? axil_from_controller.arvalid : arvalid;
    assign axil_to_cms.araddr  = done ? axil_from_controller.araddr[17:0]  : araddr;
    assign axil_to_cms.arprot  = done ? axil_from_controller.arprot  : '0;
    assign axil_to_cms.rready  = done ? axil_from_controller.rready  : rready;

    assign axil_from_controller.awready = done ? axil_to_cms.awready : 1'b0;
    assign axil_from_controller.wready  = done ? axil_to_cms.wready  : 1'b0;
    assign axil_from_controller.bvalid  = done ? axil_to_cms.bvalid  : 1'b0;
    assign axil_from_controller.bresp   = done ? axil_to_cms.bresp   : '0;
    assign axil_from_controller.arready = done ? axil_to_cms.arready : 1'b0;
    assign axil_from_controller.rvalid  = done ? axil_to_cms.rvalid  : 1'b0;
    assign axil_from_controller.rresp   = done ? axil_to_cms.rresp   : '0;
    assign axil_from_controller.rdata   = done ? axil_to_cms.rdata   : '0;

    assign axil_to_cms.aclk = cms_clk;
    // Fetching runs independently of host reset. During host access, reset
    // the peripheral with the host bridge to discard incomplete transactions.
    assign axil_to_cms.aresetn = !cms_srst && !force_abort && state != ABORT_RESET &&
                               (!done || axil_from_controller.aresetn);

endmodule : xilinx_cms_cardinfo_fetch_fsm
