`timescale 1ns/1ps
// 8N1 transmitter. A request is accepted only while busy is low.
module uart_tx #(parameter int unsigned CLKS_PER_BIT = 16)(
  input logic clk, rst_n, start,
  input logic [7:0] data,
  output logic tx, busy, done
);
  logic [9:0] frame;
  int unsigned tick, bit_index;
  initial if (CLKS_PER_BIT < 4) $fatal(1, "CLKS_PER_BIT must be >= 4");
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx <= 1; busy <= 0; done <= 0;
      frame <= '1; tick <= 0; bit_index <= 0;
    end else begin
      done <= 0;
      if (!busy) begin
        tx <= 1;
        if (start) begin
          frame <= {1'b1, data, 1'b0};
          tx <= 0; busy <= 1; tick <= 0; bit_index <= 0;
        end
      end else if (tick == CLKS_PER_BIT-1) begin
        tick <= 0;
        if (bit_index == 9) begin
          tx <= 1; busy <= 0; done <= 1;
        end else begin
          bit_index <= bit_index + 1;
          tx <= frame[bit_index+1];
        end
      end else tick <= tick + 1;
    end
  end
endmodule
