module smartnic_timestamp
#() (
    input  logic        clk,
    input  logic        rstn,
    output logic [63:0] timestamp,

    input  logic [31:0] timestamp_incr,

    input  logic        timestamp_wr_req,
    input  logic [63:0] timestamp_wr,

    input  logic        timestamp_rd_req,
    output logic        timestamp_rd_ack,
    output logic [63:0] timestamp_rd,
    output logic [63:0] freerun_rd
);

    // Signals
    logic [32:0] timestamp_lsbs,  freerun_lsbs;
    logic [91:0] timestamp_cntr,  freerun_cntr;
    logic [63:0] timestamp_latch, freerun_latch;
    logic        timestamp_rd_latch_wr_evt_d1;
    logic [63:0] timestamp_p;

    // Timestamp counter and access logic.
    always @(posedge clk) begin
       if (!rstn) begin
          timestamp_lsbs <= '0; timestamp_cntr <= '0;
          freerun_lsbs   <= '0; freerun_cntr   <= '0;
       end
       else begin
          if (timestamp_wr_req) begin
             timestamp_lsbs <= '0;
             timestamp_cntr <= { timestamp_wr,
                                 28'd0 };
             freerun_lsbs   <= '0;
             freerun_cntr   <= { timestamp_wr,
                                 28'd0 };
          end else begin
             timestamp_lsbs <= {1'b0, timestamp_lsbs[31:0]} + {1'd0, timestamp_incr};
             timestamp_cntr[31:0]  <= timestamp_lsbs[31:0];
             timestamp_cntr[91:32] <= timestamp_cntr[91:32] + {59'd0, timestamp_lsbs[32]};

             freerun_lsbs <= {1'b0, freerun_lsbs[31:0]} + {1'd0, smartnic_reg_pkg::INIT_TIMESTAMP_INCR};
             freerun_cntr[31:0]  <= freerun_lsbs[31:0];
             freerun_cntr[91:32] <= freerun_cntr[91:32] + { 59'd0, freerun_lsbs[32] };
          end
       end
    end

    always @(posedge clk) begin
        timestamp_p <= timestamp_cntr[91:28];
        timestamp   <= timestamp_p;
    end

    always @(posedge clk)
       if (timestamp_rd_req) begin
          timestamp_latch <= timestamp;
          freerun_latch   <= freerun_cntr[91:28];
       end
   
    assign timestamp_rd = timestamp_latch;
 
    assign freerun_rd = freerun_latch;

    initial timestamp_rd_ack <= '0;
    always @(posedge clk) timestamp_rd_ack <= timestamp_rd_req;

endmodule : smartnic_timestamp
