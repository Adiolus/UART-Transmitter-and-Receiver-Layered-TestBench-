`timescale 1ns/1ps
// Two-flop input synchronizer and midpoint sampling, fixed 8N1 format.
module uart_rx #(parameter int unsigned CLKS_PER_BIT = 16)(
  input logic clk, rst_n, rx,
  output logic [7:0] data,
  output logic valid, framing_error
);
  typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
  state_t state;
  logic rx_meta, rx_sync;
  logic [7:0] shift;
  int unsigned tick, bit_index;
  initial if (CLKS_PER_BIT < 4) $fatal(1, "CLKS_PER_BIT must be >= 4");
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) begin rx_meta <= 1; rx_sync <= 1; end
    else begin rx_meta <= rx; rx_sync <= rx_meta; end
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE; data <= 0; shift <= 0;
      valid <= 0; framing_error <= 0; tick <= 0; bit_index <= 0;
    end else begin
      valid <= 0; framing_error <= 0;
      case (state)
        IDLE: begin
          tick <= 0;
          if (!rx_sync) state <= START;
        end
        START: if (tick == CLKS_PER_BIT/2-1) begin
          tick <= 0;
          if (!rx_sync) begin state <= DATA; bit_index <= 0; end
          else state <= IDLE;
        end else tick <= tick + 1;
        DATA: if (tick == CLKS_PER_BIT-1) begin
          tick <= 0; shift[bit_index] <= rx_sync;
          if (bit_index == 7) state <= STOP;
          else bit_index <= bit_index + 1;
        end else tick <= tick + 1;
        STOP: if (tick == CLKS_PER_BIT-1) begin
          tick <= 0; state <= IDLE;
          if (rx_sync) begin data <= shift; valid <= 1; end
          else framing_error <= 1;
        end else tick <= tick + 1;
        default: state <= IDLE;
      endcase
    end
  end
endmodule
