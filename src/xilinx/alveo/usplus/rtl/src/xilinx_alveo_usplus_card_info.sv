// Combine static US+ card attributes with a dynamic card-info TLV stream.
module xilinx_alveo_usplus_card_info
#(
    parameter logic [31:0] FLASH_REG_OFFSET = '1,
    parameter logic [31:0] CMS_REG_OFFSET   = '1
) (
    input  logic       clk,
    input  logic       srst,
    // Dynamic card-info cache
    input  logic       source_vld,
    input  logic [7:0] source_len,
    output logic       source_rd,
    output logic [7:0] source_rd_addr,
    input  logic [7:0] source_rd_data,
    input  logic       source_rd_vld,
    // Combined static and dynamic card-info cache
    output logic       card_info_vld,
    output logic [8:0] card_info_len,
    input  logic       card_info_rd,
    input  logic [8:0] card_info_rd_addr,
    output logic [7:0] card_info_rd_data,
    output logic       card_info_rd_vld
);

    // =========================================================================
    // Static card attributes
    // =========================================================================
    function automatic logic [7:0][7:0] hex_string(input logic [31:0] value);
        for (int i = 0; i < 8; i++) begin
            hex_string[i] = value[i*4 +: 4] > 9
                          ? value[i*4 +: 4] - 10 + "a"
                          : value[i*4 +: 4] + "0";
        end
    endfunction

    function automatic int hex_length(input logic [31:0] value);
        for (int i = 7; i > 0; i--) begin
            if (value[i*4 +: 4] != 0) return i + 1;
        end
        return 1;
    endfunction

    localparam logic [7:0][7:0] FLASH_HEX = hex_string(FLASH_REG_OFFSET);
    localparam logic [7:0][7:0] CMS_HEX = hex_string(CMS_REG_OFFSET);
    localparam int FLASH_HEX_LEN = hex_length(FLASH_REG_OFFSET);
    localparam int CMS_HEX_LEN = hex_length(CMS_REG_OFFSET);
    localparam FLASH_LABEL = "Flash offset  : 0x";
    localparam CMS_LABEL = "CMS offset    : 0x";
    localparam logic [7:0] FLASH_LEN = $bits(FLASH_LABEL)/8 + FLASH_HEX_LEN + 1;
    localparam logic [7:0] CMS_LEN = $bits(CMS_LABEL)/8 + CMS_HEX_LEN + 1;
    localparam int PREFIX_LEN = 4 + int'(FLASH_LEN) + int'(CMS_LEN);
    localparam int PREFIX_ADDR_WID = $clog2(PREFIX_LEN);
    localparam logic [0:PREFIX_LEN-1][7:0] PREFIX = {
        xilinx_pci_pkg::CARD_INFO_KEY__FLASH_REG_OFFSET,
        FLASH_LEN, FLASH_LABEL, FLASH_HEX[FLASH_HEX_LEN-1:0], 8'b0,
        xilinx_pci_pkg::CARD_INFO_KEY__CMS_REG_OFFSET,
        CMS_LEN, CMS_LABEL, CMS_HEX[CMS_HEX_LEN-1:0], 8'b0
    };

    // =========================================================================
    // Cache access
    // =========================================================================
    logic [8:0] source_addr;
    logic       prefix_vld;
    logic [7:0] prefix_data;

    assign card_info_vld = source_vld;
    assign card_info_len = 9'(PREFIX_LEN) + {1'b0, source_len};
    assign source_addr = card_info_rd_addr - 9'(PREFIX_LEN);
    assign source_rd = !srst && card_info_rd && card_info_rd_addr >= PREFIX_LEN
                    && source_addr < {1'b0, source_len};
    assign source_rd_addr = source_addr[7:0];

    always_ff @(posedge clk) begin
        if (srst) prefix_vld <= 1'b0;
        else      prefix_vld <= card_info_rd && !source_rd;
        if (card_info_rd) begin
            if (card_info_rd_addr < PREFIX_LEN)
                prefix_data <= PREFIX[card_info_rd_addr[PREFIX_ADDR_WID-1:0]];
            else prefix_data <= 8'hff;
        end
    end

    // The consumer issues one request at a time and waits for its response.
    assign card_info_rd_vld = !srst && (prefix_vld || source_rd_vld);
    assign card_info_rd_data = prefix_vld ? prefix_data : source_rd_data;

endmodule : xilinx_alveo_usplus_card_info
