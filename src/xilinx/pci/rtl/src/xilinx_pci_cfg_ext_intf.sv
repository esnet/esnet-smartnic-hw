interface xilinx_pci_cfg_ext_intf (
    input logic clk
);
    // Parameters
    localparam int REG_SEL_WID = 10;
    localparam int FUNC_SEL_WID = 8;

    // Signals
    logic                   req;
    logic                   wr_rd_n;
    logic [REG_SEL_WID-1:0] register;
    logic [FUNC_SEL_WID:0]  func;
    logic [31:0]            wr_data;
    logic [3:0]             wr_byte_en;
    logic [31:0]            rd_data;
    logic                   rd_vld;

    // Modports
    modport controller (
        input  clk,
        output req,
        output wr_rd_n,
        output register,
        output func,
        output wr_data,
        output wr_byte_en,
        input  rd_data,
        input  rd_vld
    );
       
    modport peripheral (
        input  clk,
        input  req,
        input  wr_rd_n,
        input  register,
        input  func,
        input  wr_data,
        input  wr_byte_en,
        output rd_data,
        output rd_vld
    );

    clocking cb @(posedge clk);
        output req, wr_rd_n, register, func, wr_data, wr_byte_en;
        input  rd_data, rd_vld;
    endclocking

    task idle();
        cb.req <= 1'b0;
    endtask

    task _wait(input int cycles);
        repeat (cycles) @(cb);
    endtask

    task _write(
            input  bit [REG_SEL_WID-1:0]  register,
            input  bit [FUNC_SEL_WID-1:0] func,
            input  bit [31:0]             data
        );
        cb.req <= 1'b1;
        cb.wr_rd_n <= 1'b1;
        cb.register <= register;
        cb.func <= func;
        cb.wr_data <= data;
        cb.wr_byte_en <= '1;
        @(cb);
        cb.req <= 1'b0;
    endtask

    task _read(
            input  bit [REG_SEL_WID-1:0]  register,
            input  bit [FUNC_SEL_WID-1:0] func,
            output bit [31:0]             data
        );
        cb.req <= 1'b1;
        cb.wr_rd_n <= 1'b0;
        cb.register <= register;
        cb.func <= func;
        @(cb);
        cb.req <= 1'b0;
        wait(cb.rd_vld);
        data = cb.rd_data;
    endtask

    task read(
            input  bit [REG_SEL_WID-1:0]  register,
            input  bit [FUNC_SEL_WID-1:0] func,
            output bit [31:0]             data,
            output bit timeout,
            input  int RD_TIMEOUT = 0
        );
        timeout = 1'b0;
        fork
            begin
                fork
                    begin
                        _read(register, func, data);
                    end
                    begin
                        if (RD_TIMEOUT > 0) begin
                            _wait(RD_TIMEOUT);
                            timeout = 1'b1;
                        end else forever _wait(1);
                    end
                join_any
                disable fork;
            end
        join
        if (timeout) idle();
    endtask

    task write(
            input  bit [REG_SEL_WID-1:0]  register,
            input  bit [FUNC_SEL_WID-1:0] func,
            input  bit [31:0]             data,
            output bit timeout,
            input  int WR_TIMEOUT = 0
        );
        timeout = 1'b0;
        fork
            begin
                fork
                    begin
                        _write(register, func, data);
                    end
                    begin
                        if (WR_TIMEOUT > 0) begin
                            _wait(WR_TIMEOUT);
                            timeout = 1'b1;
                        end else forever _wait(1);
                    end
                join_any
                disable fork;
            end
        join
        if (timeout) idle();
    endtask

endinterface : xilinx_pci_cfg_ext_intf