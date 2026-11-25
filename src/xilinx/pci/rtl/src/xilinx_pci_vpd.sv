// VPD image construction.
module xilinx_pci_vpd #(
    parameter int          CLK_FREQ_HZ         = 50_000_000,
    parameter bit          CARD_INFO_EN        = 1,
    parameter int          CARD_INFO_TIMEOUT_MS = 6000,
    parameter              PRODUCT_ID          = "(empty)",
    parameter              APPLICATION_ID      = "(empty)",
    parameter logic [31:0] BUILD_ID            = 0,
    parameter              BUILD_GIT_REPO      = "(empty)",
    parameter              BUILD_GIT_HASH      = "(empty)",
    parameter              BUILD_TIMESTAMP_STR = "(empty)",
    parameter logic [31:0] FLASH_REG_OFFSET    = -1,
    parameter logic [31:0] CMS_REG_OFFSET      = -1
) (
    pci_vpd_intf.peripheral vpd_if,
    input  logic        srst,

    output logic        init_done,
    output logic        init_error,
    output logic        init_timeout,
    output logic        init_early_read,
    output logic [13:0] init_time_ms,
    input  logic        init_done_mask,

    // Card info interface (from CMS)
    input  logic        card_info_vld,
    input  logic        card_info_error,
    input  logic [7:0]  card_info_len,
    output logic        card_info_rd,
    output logic [7:0]  card_info_rd_addr,
    input  logic [7:0]  card_info_rd_data,
    input  logic        card_info_rd_vld
);
    // Parameters
    localparam logic [7:0]  CARD_INFO_KEY__CARD_SN    = 8'h21;
    localparam logic [7:0]  CARD_INFO_KEY__CARD_NAME  = 8'h27;
    localparam logic [7:0]  CARD_INFO_KEY__SC_VERSION = 8'h28;

    localparam int          CARD_INFO_MAX_LEN = 255;
    localparam int          CARD_INFO_IDX_WID = $clog2(CARD_INFO_MAX_LEN+1);
    localparam int          CARD_INFO_SIZE_WID = $clog2(CARD_INFO_MAX_LEN+1);

    localparam int CLKS_PER_MS = CLK_FREQ_HZ / 1000;
    localparam int CLK_CNT_WID = CLKS_PER_MS > 1 ? $clog2(CLKS_PER_MS) : 1;

    initial begin
        std_pkg::param_check_gt(CLK_FREQ_HZ, 999, "CLK_FREQ_HZ");
        std_pkg::param_check(CLK_FREQ_HZ % 1000, 0, "CLK_FREQ_HZ % 1000");
        std_pkg::param_check_gt(CARD_INFO_TIMEOUT_MS, 0, "CARD_INFO_TIMEOUT_MS");
        std_pkg::param_check_lt(CARD_INFO_TIMEOUT_MS, 16384, "CARD_INFO_TIMEOUT_MS");
    end

    wire clk = vpd_if.clk;
    wire vpd_req = vpd_if.req;
    wire vpd_wr_rd_n = vpd_if.wr_rd_n;
    wire [14:0] vpd_addr = vpd_if.addr;
    logic [7:0] vpd_rd_data;
    logic vpd_rd_vld;
    assign vpd_if.rd_data = vpd_rd_data;
    assign vpd_if.rd_vld = vpd_rd_vld;

    function automatic logic [7:0][7:0] get_dword_hex_string(input logic [31:0] dword);
        logic [7:0][7:0] dword_string;
        for (int i = 0; i < 8; i++) begin
            dword_string[i] = dword[i*4 +: 4] > 9 ? dword[i*4 +: 4]- 10 + "a" : dword[i*4 +: 4] + "0"; 
        end
        return dword_string;
    endfunction

    function automatic int get_dword_hex_string_len(input logic [7:0][7:0] dword_hex_string);
        automatic int len = 8;
        for (int i = 7; i > 0; i--) begin
            if (dword_hex_string[i] > "0") return len;
            else len--;
        end
        return len;
    endfunction

    function automatic logic [9:0][7:0] get_dword_dec_string(input logic [31:0] dword);
        logic [9:0][7:0] dword_string;
        for (int i = 0; i < 10; i++) begin
            dword_string[i] = dword % 10 + "0";
            dword = dword / 10;
        end
        return dword_string;
    endfunction

    function automatic int get_dword_dec_string_len(input logic [9:0][7:0] dword_dec_string);
        automatic int len = 10;
        for (int i = 9; i > 0; i--) begin
            if (dword_dec_string[i] > "0") return len;
            else len--;
        end
        return len;
    endfunction

    localparam logic [15:0] PRODUCT_ID_LEN = $bits(PRODUCT_ID)/8 + 1; // Account for null string termination

    localparam int VPD_RO_START_OFFSET = 3 + PRODUCT_ID_LEN;

    localparam int VPD_VA_START_OFFSET = VPD_RO_START_OFFSET + 3;
    localparam     VPD_VA_LABEL = "Application   : ";
    localparam int VPD_VA_LABEL_LEN = $bits(VPD_VA_LABEL)/8;
    localparam int VPD_VA_VALUE_LEN = $bits(APPLICATION_ID)/8;
    localparam logic [7:0] VPD_VA_LEN = VPD_VA_LABEL_LEN + VPD_VA_VALUE_LEN + 1; // String is null-terminated

    localparam int VPD_VB_START_OFFSET = VPD_VA_START_OFFSET + 3 + VPD_VA_LEN;
    localparam     VPD_VB_LABEL = "Build ID      : ";
    localparam int VPD_VB_LABEL_LEN = $bits(VPD_VB_LABEL)/8;
    localparam logic [9:0][7:0] VPD_VB_VALUE = get_dword_dec_string(BUILD_ID);
    localparam int         VPD_VB_VALUE_LEN = get_dword_dec_string_len(VPD_VB_VALUE);
    localparam logic [7:0] VPD_VB_LEN = VPD_VB_LABEL_LEN + VPD_VB_VALUE_LEN + 1; // String is null-terminated

    localparam int VPD_VR_START_OFFSET = VPD_VB_START_OFFSET + VPD_VB_LEN + 3;
    localparam     VPD_VR_LABEL = "Build git repo: ";
    localparam int VPD_VR_LABEL_LEN = $bits(VPD_VR_LABEL)/8;
    localparam int VPD_VR_VALUE_LEN = $bits(BUILD_GIT_REPO)/8;
    localparam logic [7:0] VPD_VR_LEN = VPD_VR_LABEL_LEN + VPD_VR_VALUE_LEN + 1; // String is null-terminated

    localparam int VPD_VH_START_OFFSET = VPD_VR_START_OFFSET + 3 + VPD_VR_LEN;
    localparam     VPD_VH_LABEL = "Build git hash: ";
    localparam int VPD_VH_LABEL_LEN = $bits(VPD_VH_LABEL)/8;
    localparam int VPD_VH_VALUE_LEN = $bits(BUILD_GIT_HASH)/8;
    localparam logic [7:0] VPD_VH_LEN = VPD_VH_LABEL_LEN + VPD_VH_VALUE_LEN + 1; // String is null-terminated

    localparam int VPD_VT_START_OFFSET = VPD_VH_START_OFFSET + 3 + VPD_VH_LEN;
    localparam     VPD_VT_LABEL = "Build time    : ";
    localparam int VPD_VT_LABEL_LEN = $bits(VPD_VT_LABEL)/8;
    localparam int VPD_VT_VALUE_LEN = $bits(BUILD_TIMESTAMP_STR)/8;
    localparam logic [7:0] VPD_VT_LEN = VPD_VT_LABEL_LEN + VPD_VT_VALUE_LEN + 1; // String is null-terminated

    localparam int VPD_VF_START_OFFSET = VPD_VT_START_OFFSET + 3 + VPD_VT_LEN;
    localparam     VPD_VF_LABEL = "Flash offset  : ";
    localparam int VPD_VF_LABEL_LEN = $bits(VPD_VF_LABEL)/8;
    localparam logic [7:0][7:0] VPD_VF_VALUE = get_dword_hex_string(FLASH_REG_OFFSET);
    localparam int         VPD_VF_VALUE_LEN = get_dword_hex_string_len(VPD_VF_VALUE);
    localparam logic [7:0] VPD_VF_LEN = VPD_VF_LABEL_LEN + 2 + VPD_VF_VALUE_LEN + 1; // Include 0x prefix and null termination

    localparam int VPD_VC_START_OFFSET = VPD_VF_START_OFFSET + 3 + VPD_VF_LEN;
    localparam     VPD_VC_LABEL = "CMS offset    : ";
    localparam int VPD_VC_LABEL_LEN = $bits(VPD_VC_LABEL)/8;
    localparam logic [7:0][7:0] VPD_VC_VALUE = get_dword_hex_string(CMS_REG_OFFSET);
    localparam int         VPD_VC_VALUE_LEN = get_dword_hex_string_len(VPD_VC_VALUE);
    localparam logic [7:0] VPD_VC_LEN = VPD_VC_LABEL_LEN + 2 + VPD_VC_VALUE_LEN + 1; // Include 0x prefix and null termination

    localparam int VPD_CARDINFO_START_OFFSET = VPD_VC_START_OFFSET + 3 + VPD_VC_LEN;
    localparam int VPD_VAR_START_OFFSET = VPD_CARDINFO_START_OFFSET; // Start of 'variable' data, retrieved from card info
                                                                     // ... or, end of 'static' data
    localparam int VPD_STATIC_SIZE = VPD_VAR_START_OFFSET;
    localparam int VPD_ROM_SIZE    = VPD_STATIC_SIZE + 3;
    localparam int VPD_ROM_SIZE_WID = $clog2(VPD_ROM_SIZE);

    localparam int VPD_VAR_SIZE = 128;
    localparam int VPD_VAR_SIZE_WID = $clog2(VPD_VAR_SIZE);


    localparam int VPD_MAX_LEN = VPD_STATIC_SIZE + VPD_VAR_SIZE;
    localparam int VPD_IDX_WID = $clog2(VPD_MAX_LEN);
    localparam int VPD_SIZE_WID = $clog2(VPD_MAX_LEN+1);

    localparam logic [15:0] VPD_RO_LEN = (VPD_MAX_LEN-1) - VPD_RO_START_OFFSET - 3; // Size of VPD-R (read-only data)
    localparam logic [7:0]  VPD_ROM_RSVD_LEN = VPD_VAR_SIZE-4;

    // Typedefs
    typedef enum logic {
        VPD_RESOURCE_TYPE__SMALL = 0,
        VPD_RESOURCE_TYPE__LARGE = 1
    } vpd_resource_type_t;

    typedef enum logic [6:0] {
        VPD_TAG_INVALID = 7'h0,
        VPD_TAG_ID      = 7'h2,
        VPD_TAG_END     = 7'hf,
        VPD_TAG_VPD_R   = 7'h10,
        VPD_TAG_VPD_W   = 7'h11
    } vpd_tag_t;

    typedef logic [3:0] vpd_tag_small_t;

    typedef struct packed {
        vpd_resource_type_t _type; // 0 for small resource data type
        vpd_tag_small_t     tag;
        logic [2:0]         len;
    } vpd_srdt_t;

    typedef struct packed {
        vpd_resource_type_t _type; // 1 for small resource data type
        vpd_tag_t           tag;
    } vpd_lrdt_t;

    typedef enum logic [3:0] {
        RESET,
        IDLE,
        GET_CARD_NAME,
        CARD_NAME_WRITE_TO_VPD,
        GET_CARD_SN,
        CARD_SN_WRITE_TO_VPD,
        GET_SC_VERSION,
        SC_VERSION_WRITE_TO_VPD,
        CHKSUM,
        DONE,
        STATIC_DONE,
        ERROR
    } state_t;

    typedef enum logic [3:0] {
        PARSE_RESET,
        PARSE_IDLE,
        PARSE_INIT,
        PARSE_GET_KEY,
        PARSE_WAIT_KEY,
        PARSE_GET_LEN,
        PARSE_WAIT_LEN,
        PARSE_TEST_LEN,
        PARSE_EVAL,
        PARSE_SKIP_VALUE,
        PARSE_DONE,
        PARSE_ERROR,
        PARSE_KEY_NOT_FOUND
    } parse_state_t;

    typedef enum logic [4:0] {
        VPD_RESET,
        VPD_IDLE,
        VPD_WR,
        VPD_WR_TAG,
        VPD_WR_LEN,
        VPD_RD_CARDINFO,
        VPD_WAIT_CARDINFO,
        VPD_WR_DATA,
        VPD_CHKSUM_WR_TAG,
        VPD_CHKSUM_WR_LEN,
        VPD_CHKSUM_INIT,
        VPD_CHKSUM_RD_DATA,
        VPD_CHKSUM_ACC,
        VPD_CHKSUM_WR_DATA,
        VPD_CHKSUM_PAD,
        VPD_DONE,
        VPD_ERROR
    } vpd_state_t;

    // Functions
    function vpd_tag_small_t vpd_get_small_tag(input vpd_tag_t tag);
        if (tag <= 'hf) return vpd_tag_small_t'(tag);
        else            return vpd_tag_small_t'(VPD_TAG_INVALID);
    endfunction

    function logic [7:0] vpd_get_srdt(input vpd_tag_t tag, input logic [2:0] len);
        vpd_srdt_t srdt;
        srdt._type = VPD_RESOURCE_TYPE__SMALL;
        srdt.tag = vpd_get_small_tag(tag);
        srdt.len = len;
        return srdt;
    endfunction

    function logic [7:0] vpd_get_lrdt(input vpd_tag_t tag);
        vpd_lrdt_t lrdt;
        lrdt._type = VPD_RESOURCE_TYPE__LARGE;
        lrdt.tag = tag;
        return lrdt;
    endfunction

    localparam logic [7:0] VPD_LRDT_ID    = vpd_get_lrdt(VPD_TAG_ID);
    localparam logic [7:0] VPD_LRDT_VPD_R = vpd_get_lrdt(VPD_TAG_VPD_R);
    localparam logic [7:0] VPD_SRDT_END   = vpd_get_srdt(VPD_TAG_END, 0);

    // Signals
    state_t                       state;
    state_t                       nxt_state;

    logic                         __init_done;
    logic                         __init_error;
    logic                         __init_timeout;

    parse_state_t                 parse_state;
    parse_state_t                 nxt_parse_state;

    logic                         reset_parse_idx;
    logic [CARD_INFO_IDX_WID:0]   parse_idx_incr;
    logic [CARD_INFO_IDX_WID:0]   parse_idx;
    logic                         parse_req;
    logic [7:0]                   parse_key;
    logic [CARD_INFO_IDX_WID-1:0] parse_len;
    logic                         latch_key;
    logic                         latch_len;
    logic [7:0]                   found_key;

    logic                         parse_cardinfo_rd;

    vpd_state_t                   vpd_state;
    vpd_state_t                   nxt_vpd_state;

    logic                         reset_vpd_init_idx;
    logic                         inc_vpd_init_idx;
    logic [VPD_VAR_SIZE_WID-1:0]  vpd_init_idx;

    logic                         vpd_chksum_init;
    logic [VPD_VAR_SIZE_WID-1:0]  vpd_chksum_idx;
    logic [7:0]                   vpd_sum;
    logic [7:0]                   vpd_chksum;
    logic                         vpd_wr_req;
    logic [0:1][7:0]              vpd_wr_tag;
    logic                         vpd_chksum_req;
    logic                         vpd_cardinfo_rd;
    logic [CARD_INFO_IDX_WID-1:0] vpd_cardinfo_rd_addr;
    logic                         vpd_cardinfo_rd_vld;

    logic                         vpd_init_wr;
    logic [7:0]                   vpd_init_wr_data;
    logic                         vpd_init_rd;
    logic [7:0]                   vpd_init_rd_data;

    logic                         reset_vpd_byte_idx;
    logic [CARD_INFO_IDX_WID-1:0] vpd_byte_idx;
    logic                         vpd_chksum_acc;

    logic [7:0]                   vpd_rom_rd_data;

    logic                         vpd_ram_req;
    logic                         vpd_ram_wr_rd_n;
    logic [14:0]                  vpd_ram_addr;
    logic [7:0]                   vpd_ram_wr_data;
    logic [7:0]                   vpd_ram_rd_data;

    logic [14:0]                  vpd_addr_r;

    logic [CLK_CNT_WID-1:0]       init_time_clks;

    // VPD data structure
    logic [0:VPD_ROM_SIZE-1][7:0] VPD_ROM;
    logic [7:0] VPD_RAM [VPD_VAR_SIZE];
    
    localparam logic [0:VPD_ROM_SIZE-1][7:0] VPD_ROM_CONTENTS = {
    // -- Product ID Section
        VPD_LRDT_ID,
        PRODUCT_ID_LEN[7:0], PRODUCT_ID_LEN[15:8],
        PRODUCT_ID, 8'h0,
    // -- VPD-R (read-only) Section
        VPD_LRDT_VPD_R,
        // VPD-R section extends from here until the end of the
        // (fixed-size) data structure; this is possible by filling
        // 'zero' bytes in the RV field)
        VPD_RO_LEN[7:0], VPD_RO_LEN[15:8],
        "VA", VPD_VA_LEN, VPD_VA_LABEL, APPLICATION_ID, 8'h0,
        "VB", VPD_VB_LEN, VPD_VB_LABEL, VPD_VB_VALUE[VPD_VB_VALUE_LEN-1:0], 8'h0,
        "VR", VPD_VR_LEN, VPD_VR_LABEL, BUILD_GIT_REPO, 8'h0,
        "VH", VPD_VH_LEN, VPD_VH_LABEL, BUILD_GIT_HASH, 8'h0,
        "VT", VPD_VT_LEN, VPD_VT_LABEL, BUILD_TIMESTAMP_STR, 8'h0,
        "VF", VPD_VF_LEN, VPD_VF_LABEL, "0x", VPD_VF_VALUE[VPD_VF_VALUE_LEN-1:0], 8'h0,
        "VC", VPD_VC_LEN, VPD_VC_LABEL, "0x", VPD_VC_VALUE[VPD_VC_VALUE_LEN-1:0], 8'h0,
    // -- Variable data (i.e. card info) goes here (populated by Init FSM)
    // -- Add RV (checksum) for all static data
    //    This checksum is only used while card info data is unavailable or
    //    in progress; this ensures that VPD queries always return data
    //    corresponding to a valid (parseable, good checksum) database.
        "RV", VPD_ROM_RSVD_LEN
    };

    function automatic logic [7:0] get_static_byte_sum();
        automatic logic [7:0] sum = 0;
        for (int i = 0; i < VPD_STATIC_SIZE; i++) sum += VPD_ROM_CONTENTS[i];
        return sum;
    endfunction

    function automatic logic [7:0] get_rom_byte_sum();
        automatic logic [7:0] sum = 0;
        for (int i = 0; i < VPD_ROM_SIZE; i++) sum += VPD_ROM_CONTENTS[i];
        return sum;
    endfunction

    localparam logic [7:0] VPD_STATIC_SUM = get_static_byte_sum();
 
    localparam logic [7:0] VPD_ROM_SUM = get_rom_byte_sum();
    localparam logic [7:0] VPD_ROM_CHECKSUM = 9'h100-VPD_ROM_SUM;

    // ROM containing 'static' elements; card info is filled in
    // by the state machine after retrieval from CMS/SC
    initial VPD_ROM = VPD_ROM_CONTENTS;

    always_ff @(posedge clk) begin
        if (vpd_addr < VPD_ROM_SIZE)       vpd_rom_rd_data <= VPD_ROM[vpd_addr[VPD_ROM_SIZE_WID-1:0]];
        else if (vpd_addr == VPD_ROM_SIZE) vpd_rom_rd_data <= VPD_ROM_CHECKSUM;
        else                               vpd_rom_rd_data <= 8'h0;
    end

    // Init (main) FSM
    // - Manage population of (non-static) elements of the VPD data structure
    // - The main content for this is cardinfo data, retrieved at initialization
    //   from System Controller (via CMS)
    initial state = RESET;
    always @(posedge clk) begin
        if (srst) state <= RESET;
        else      state <= nxt_state;
    end

    always_comb begin
        nxt_state = state;
        reset_vpd_init_idx = 1'b0;
        parse_req = 1'b0;
        parse_key = 'h0;
        vpd_wr_req = 1'b0;
        vpd_wr_tag = '0;
        vpd_chksum_req = 1'b0;
        __init_done = 1'b0;
        __init_error = 1'b0;
        case (state)
            RESET : begin
                if (!CARD_INFO_EN) nxt_state = STATIC_DONE;
                else if (card_info_vld) nxt_state = IDLE;
            end
            IDLE : begin
                reset_vpd_init_idx = 1'b1;
                nxt_state = GET_CARD_NAME;
            end
            GET_CARD_NAME : begin
                parse_req = 1'b1;
                parse_key = CARD_INFO_KEY__CARD_NAME;
                if (parse_state == PARSE_DONE)               nxt_state = CARD_NAME_WRITE_TO_VPD;
                else if (parse_state == PARSE_KEY_NOT_FOUND) nxt_state = GET_CARD_SN;
                else if (parse_state == PARSE_ERROR)         nxt_state = ERROR;
            end
            CARD_NAME_WRITE_TO_VPD: begin
                vpd_wr_req = 1'b1;
                vpd_wr_tag = "PN";
                if (vpd_state == VPD_DONE)       nxt_state = GET_CARD_SN;
                else if (vpd_state == VPD_ERROR) nxt_state = ERROR;
            end
            GET_CARD_SN : begin
                parse_req = 1'b1;
                parse_key = CARD_INFO_KEY__CARD_SN;
                if (parse_state == PARSE_DONE)               nxt_state = CARD_SN_WRITE_TO_VPD;
                else if (parse_state == PARSE_KEY_NOT_FOUND) nxt_state = GET_SC_VERSION;
                else if (parse_state == PARSE_ERROR)         nxt_state = ERROR;
            end
            CARD_SN_WRITE_TO_VPD: begin
                vpd_wr_req = 1'b1;
                vpd_wr_tag = "SN";
                if (vpd_state == VPD_DONE)       nxt_state = GET_SC_VERSION;
                else if (vpd_state == VPD_ERROR) nxt_state = ERROR;
            end
            GET_SC_VERSION : begin
                parse_req = 1'b1;
                parse_key = CARD_INFO_KEY__SC_VERSION;
                if (parse_state == PARSE_DONE) begin
                    nxt_state = SC_VERSION_WRITE_TO_VPD;
                end else if (parse_state == PARSE_KEY_NOT_FOUND) begin
                    if (vpd_init_idx == 0) nxt_state = ERROR;
                    else                   nxt_state = CHKSUM;
                end else if (parse_state == PARSE_ERROR) begin
                    nxt_state = ERROR;
                end
            end 
            SC_VERSION_WRITE_TO_VPD : begin
                vpd_wr_req = 1'b1;
                vpd_wr_tag = "RM";
                if (vpd_state == VPD_DONE)       nxt_state = CHKSUM;
                else if (vpd_state == VPD_ERROR) nxt_state = ERROR;
            end
            CHKSUM : begin
                vpd_chksum_req = 1'b1;
                vpd_wr_tag = "RV";
                if (vpd_state == VPD_DONE)       nxt_state = DONE;
                else if (vpd_state == VPD_ERROR) nxt_state = ERROR;
            end
            DONE, STATIC_DONE : begin
                __init_done = 1'b1;
            end
            ERROR : begin
                __init_error = 1'b1;
            end
        endcase
        // Bound the entire initialization, including an unresponsive provider.
        // Once complete, keep the selected image stable until reset.
        if (CARD_INFO_EN && !__init_done && !__init_error &&
            (card_info_error || __init_timeout)) nxt_state = ERROR;
    end

    assign __init_timeout = CARD_INFO_EN && !__init_done && !__init_error &&
                            init_time_ms >= CARD_INFO_TIMEOUT_MS;

    // Manage pointer into VPD data structure
    // - this pointer is used to populate cardinfo on init
    // - start at the specified start offset (immediately following any 'static' records)
    // - increment as new data is written into the VPD structure
    always @(posedge clk) begin
        if (reset_vpd_init_idx)    vpd_init_idx <= 0;
        else if (vpd_chksum_init)  vpd_init_idx <= 0;
        else if (inc_vpd_init_idx) vpd_init_idx <= vpd_init_idx + 1;
    end

    // VPD FSM
    // - manages init accesses to VPD data structure, including:
    //   - writing card info data elements as VPD TLVs
    //   - calculating and populating VPD-R checksum
    //   - writing end tag
    initial vpd_state = VPD_RESET;
    always @(posedge clk) begin
        if (srst) vpd_state <= VPD_RESET;
        else      vpd_state <= nxt_vpd_state;
    end

    always_comb begin
        nxt_vpd_state = vpd_state;
        reset_vpd_byte_idx = 1'b0;
        inc_vpd_init_idx = 1'b0;
        vpd_init_wr = 1'b0;
        vpd_init_rd = 1'b0;
        vpd_cardinfo_rd = 1'b0;
        vpd_chksum_init = 1'b0;
        vpd_chksum_acc = 1'b0;
        case (vpd_state)
            VPD_RESET : begin
                nxt_vpd_state = VPD_IDLE;
            end
            VPD_IDLE : begin
                reset_vpd_byte_idx = 1'b1;
                if (vpd_wr_req)          nxt_vpd_state = VPD_WR;
                else if (vpd_chksum_req) nxt_vpd_state = VPD_CHKSUM_WR_TAG;
            end
            VPD_WR : begin
                if (int'(vpd_init_idx) + int'(parse_len) + 7 <= VPD_VAR_SIZE) nxt_vpd_state = VPD_WR_TAG;
                else                                                         nxt_vpd_state = VPD_ERROR;
            end
            VPD_WR_TAG : begin
                vpd_init_wr = 1'b1;
                inc_vpd_init_idx = 1'b1;
                if (vpd_byte_idx == 1) nxt_vpd_state = VPD_WR_LEN;
            end
            VPD_WR_LEN : begin
                vpd_init_wr = 1'b1;
                inc_vpd_init_idx = 1'b1;
                nxt_vpd_state = VPD_RD_CARDINFO;
            end
            VPD_RD_CARDINFO: begin
                vpd_cardinfo_rd = 1'b1;
                nxt_vpd_state = VPD_WAIT_CARDINFO;
            end
            VPD_WAIT_CARDINFO: begin
                if (card_info_rd_vld) nxt_vpd_state = VPD_WR_DATA;
            end
            VPD_WR_DATA : begin
                vpd_init_wr = 1'b1;
                inc_vpd_init_idx = 1'b1;
                if (vpd_byte_idx == 3+parse_len-1) nxt_vpd_state = VPD_DONE;
                else                               nxt_vpd_state = VPD_RD_CARDINFO;
            end
            VPD_CHKSUM_WR_TAG : begin
                vpd_init_wr = 1'b1;
                inc_vpd_init_idx = 1'b1;
                if (vpd_byte_idx == 1) nxt_vpd_state = VPD_CHKSUM_WR_LEN;
            end
            VPD_CHKSUM_WR_LEN : begin
                vpd_init_wr = 1'b1;
                inc_vpd_init_idx = 1'b1;
                nxt_vpd_state = VPD_CHKSUM_INIT;
            end
            VPD_CHKSUM_INIT : begin
                vpd_chksum_init = 1'b1;
                if (int'(vpd_init_idx) < VPD_VAR_SIZE) nxt_vpd_state = VPD_CHKSUM_RD_DATA;
                else                                   nxt_vpd_state = VPD_ERROR;
            end
            VPD_CHKSUM_RD_DATA : begin
                vpd_init_rd = 1'b1;
                inc_vpd_init_idx = 1'b1;
                nxt_vpd_state = VPD_CHKSUM_ACC;
            end
            VPD_CHKSUM_ACC : begin
                vpd_chksum_acc = 1'b1;
                if (vpd_init_idx == vpd_chksum_idx) nxt_vpd_state = VPD_CHKSUM_WR_DATA;
                else                                nxt_vpd_state = VPD_CHKSUM_RD_DATA;
            end
            VPD_CHKSUM_WR_DATA : begin
                vpd_init_wr = 1'b1;
                inc_vpd_init_idx = 1'b1;
                if (vpd_init_idx == VPD_VAR_SIZE - 1) nxt_vpd_state = VPD_DONE;
                else                                  nxt_vpd_state = VPD_CHKSUM_PAD;
            end
            VPD_CHKSUM_PAD : begin
                vpd_init_wr = 1'b1;
                inc_vpd_init_idx = 1'b1;
                if (vpd_init_idx == VPD_VAR_SIZE - 1) nxt_vpd_state = VPD_DONE;
            end
            VPD_DONE : begin
                nxt_vpd_state = VPD_IDLE;
            end
            VPD_ERROR : begin
                nxt_vpd_state = VPD_IDLE;
            end
        endcase
    end

    // Manage current element byte pointer
    always_ff @(posedge clk) begin
        if (reset_vpd_byte_idx)    vpd_byte_idx <= 0;
        else if (inc_vpd_init_idx) vpd_byte_idx <= vpd_byte_idx + 1;
    end

    // Cardinfo data mux
    assign card_info_rd      = CARD_INFO_EN && state != ERROR && state != STATIC_DONE &&
                               ((parse_state == PARSE_IDLE) ? vpd_cardinfo_rd : parse_cardinfo_rd);
    assign card_info_rd_addr = (parse_state == PARSE_IDLE) ? vpd_cardinfo_rd_addr : parse_idx[CARD_INFO_IDX_WID-1:0];

    // Adjust card info pointer to account for type and length fields
    assign vpd_cardinfo_rd_addr = parse_idx[CARD_INFO_IDX_WID-1:0] + vpd_byte_idx - 3;

    // Write data mux
    always_comb begin
        case (vpd_state)
            VPD_WR_TAG, VPD_CHKSUM_WR_TAG : vpd_init_wr_data = vpd_wr_tag[vpd_byte_idx];
            VPD_WR_LEN                    : vpd_init_wr_data = parse_len;
            VPD_WR_DATA                   : vpd_init_wr_data = card_info_rd_data;
            VPD_CHKSUM_WR_LEN             : vpd_init_wr_data = (VPD_MAX_LEN-VPD_STATIC_SIZE-1) - vpd_init_idx - 1; // Zero-pad to end of VPD (except for END tag)
            VPD_CHKSUM_WR_DATA            : vpd_init_wr_data = vpd_chksum;
            VPD_CHKSUM_PAD                : vpd_init_wr_data = 8'h00;
            default                       : vpd_init_wr_data = '0;
        endcase
    end

    // Latch checksum byte offset
    // - checksum is the value that needs to be added to the sum of all
    //   bytes, from byte 0 to this offset, to make the sum 0
    //  -when calculated, the checksum is written to this location
    always_ff @(posedge clk) if (vpd_chksum_init) vpd_chksum_idx <= vpd_init_idx;

    // Calulate sum of all RO bytes
    always_ff @(posedge clk) begin
        if (vpd_chksum_init) vpd_sum <= VPD_STATIC_SUM;
        else if (vpd_chksum_acc) vpd_sum <= vpd_sum + vpd_init_rd_data;
    end

    // Determine checksum
    assign vpd_chksum = 9'h100 - vpd_sum;

    // Card info parse FSM
    // - Given a key (parse_key), find the length of the associated
    //   data value (parse_len) and the offset of the data value
    //   within the cardinfo data structure (parse_idx)
    // - If matching key is found, traverse PARSE_DONE state
    // - If parsing error occurs (e.g. attempt to read past end of array)
    //   or key is not found, traverse PARSE_ERROR state
    initial parse_state = PARSE_RESET;
    always @(posedge clk) begin
        if (srst) parse_state <= PARSE_RESET;
        else      parse_state <= nxt_parse_state;
    end

    always_comb begin
        nxt_parse_state = parse_state;
        reset_parse_idx = 1'b0;
        parse_idx_incr = '0;
        parse_cardinfo_rd = 1'b0;
        latch_key = 1'b0;
        latch_len = 1'b0;
        case (parse_state)
            PARSE_RESET : begin
                nxt_parse_state = PARSE_IDLE;
            end
            PARSE_IDLE : begin
                if (parse_req) nxt_parse_state = PARSE_INIT;
            end
            PARSE_INIT : begin
                reset_parse_idx = 1'b1;
                nxt_parse_state = PARSE_GET_KEY;
            end
            PARSE_GET_KEY : begin
                parse_cardinfo_rd = 1'b1;
                parse_idx_incr = 1;
                nxt_parse_state = PARSE_WAIT_KEY;
            end
            PARSE_WAIT_KEY : begin
                latch_key = 1'b1;
                if (card_info_rd_vld) begin
                    if (parse_idx < card_info_len) nxt_parse_state = PARSE_GET_LEN;
                    else                           nxt_parse_state = PARSE_KEY_NOT_FOUND;
                end
            end
            PARSE_GET_LEN : begin
                parse_cardinfo_rd = 1'b1;
                parse_idx_incr = 1;
                nxt_parse_state = PARSE_WAIT_LEN;
            end
            PARSE_WAIT_LEN : begin
                latch_len = 1'b1;
                if (card_info_rd_vld) begin
                    if (parse_idx <= card_info_len) nxt_parse_state = PARSE_TEST_LEN;
                    else                            nxt_parse_state = PARSE_ERROR;
                end
            end
            PARSE_TEST_LEN : begin
                if (parse_len > 0 && (parse_idx + parse_len) <= card_info_len) nxt_parse_state = PARSE_EVAL;
                else                                                           nxt_parse_state = PARSE_ERROR;
            end
            PARSE_EVAL : begin
                if (found_key == parse_key)                        nxt_parse_state = PARSE_DONE;
                else if ((parse_idx + parse_len) == card_info_len) nxt_parse_state = PARSE_KEY_NOT_FOUND;
                else                                               nxt_parse_state = PARSE_SKIP_VALUE;
            end
            PARSE_SKIP_VALUE : begin
                parse_idx_incr = {1'b0, parse_len};
                nxt_parse_state = PARSE_GET_KEY;
            end
            PARSE_KEY_NOT_FOUND : begin
                nxt_parse_state = PARSE_IDLE;
            end
            PARSE_DONE : begin
                nxt_parse_state = PARSE_IDLE;
            end
            PARSE_ERROR : begin
                nxt_parse_state = PARSE_IDLE;
            end
        endcase
    end

    // Manage pointer into cardinfo data structure
    always_ff @(posedge clk) begin
        if (reset_parse_idx) parse_idx <= 0;
        else                 parse_idx <= parse_idx + parse_idx_incr;
    end

    // Latch key/length from current cardinfo record
    always_ff @(posedge clk) if (card_info_rd_vld && latch_key) found_key <= card_info_rd_data;
    always_ff @(posedge clk) if (card_info_rd_vld && latch_len) parse_len <= card_info_rd_data;

    // VPD Access Mux
    
    // No need to arbitrate write access (yet), since VPD writes (from external controller
    // are not supported. Could add this but generally these writes would end up in NV RAM,
    // whereas this VPD data struture would last only until the next reset/power cycle

    // Read
    // Need to arbitrate here between read requests coming from PCIe extended config
    // interface and initialization reads
    always_comb begin
        case (state)
            DONE: begin
                vpd_ram_req     = vpd_req && !vpd_wr_rd_n;
                vpd_ram_wr_rd_n = 1'b0;
                vpd_ram_addr    = vpd_addr > VPD_STATIC_SIZE-1 ? vpd_addr - VPD_STATIC_SIZE : 0;
                vpd_ram_wr_data = '0;
            end
            ERROR: begin
                vpd_ram_req     = 1'b0;
                vpd_ram_wr_rd_n = 1'b0;
                vpd_ram_addr    = '0;
                vpd_ram_wr_data = '0;
            end
            default : begin
                vpd_ram_req     = vpd_init_wr || vpd_init_rd;
                vpd_ram_wr_rd_n = vpd_init_wr;
                vpd_ram_addr    = {'0, vpd_init_idx};
                vpd_ram_wr_data = vpd_init_wr_data;
            end
        endcase
    end

    initial vpd_rd_vld = 1'b0;
    always @(posedge clk) begin
        if (srst) vpd_rd_vld <= 1'b0;
        else begin
            if (vpd_req && !vpd_wr_rd_n) vpd_rd_vld <= 1'b1;
            else                         vpd_rd_vld <= 1'b0;
        end
    end

    always @(posedge clk) if (vpd_req) vpd_addr_r <= vpd_addr;

    initial VPD_RAM = '{default: 8'h0};
    always @(posedge clk) begin
        if (vpd_ram_req && vpd_ram_addr < VPD_MAX_LEN) begin
            if (vpd_ram_wr_rd_n) VPD_RAM[vpd_ram_addr[VPD_IDX_WID-1:0]] <= vpd_ram_wr_data;
            else vpd_ram_rd_data <= VPD_RAM[vpd_ram_addr[VPD_IDX_WID-1:0]];
        end
    end

    always_comb begin
        vpd_rd_data = 8'hff;
        if (vpd_addr_r < VPD_MAX_LEN) begin
            if (vpd_addr_r == VPD_MAX_LEN-1)       vpd_rd_data = VPD_SRDT_END;
            else if (vpd_addr_r < VPD_STATIC_SIZE) vpd_rd_data = vpd_rom_rd_data;
            else if (init_done && state == DONE)   vpd_rd_data = vpd_ram_rd_data;
            else                                   vpd_rd_data = vpd_rom_rd_data;
        end
    end

    assign vpd_init_rd_data = vpd_ram_rd_data;

    // Drive init_* status outputs
    always_ff @(posedge clk or posedge srst) begin
        if (srst) begin
            init_done <= 1'b0;
            init_error <= 1'b0;
            init_timeout <= 1'b0;
            init_early_read <= 1'b0;
            init_time_clks <= '0;
            init_time_ms <= '0;
        end else begin
            init_done <= init_done_mask ? 1'b0 : __init_done;
            init_error <= __init_error;
            if (__init_timeout) init_timeout <= 1'b1;
            if (!__init_done && !__init_error) begin
                if (vpd_req && !vpd_wr_rd_n) init_early_read <= 1'b1;
                init_time_clks <= init_time_clks < CLKS_PER_MS-1 ? init_time_clks + 1 : 0;
                if (init_time_clks == CLKS_PER_MS-1) init_time_ms <= init_time_ms < '1 ? init_time_ms + 1 : init_time_ms;
            end
        end
    end

endmodule : xilinx_pci_vpd
