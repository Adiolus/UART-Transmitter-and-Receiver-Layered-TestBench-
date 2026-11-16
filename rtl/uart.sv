`timescale 1ns/1ps
module uart #(parameter int unsigned CLKS_PER_BIT = 16)(
  input logic clk, rst_n, tx_start,
  input logic [7:0] tx_data,
  input logic rx,
  output logic tx, tx_busy, tx_done,
  output logic [7:0] rx_data,
  output logic rx_valid, rx_error
);
  uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) transmitter(
    .clk, .rst_n, .start(tx_start), .data(tx_data),
    .tx, .busy(tx_busy), .done(tx_done));
  uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) receiver(
    .clk, .rst_n, .rx, .data(rx_data),
    .valid(rx_valid), .framing_error(rx_error));
endmodule
