`timescale 1ns/1ps
interface uart_if(input logic clk);
  logic rst_n = 0;
  logic tx_start = 0;
  logic [7:0] tx_data = 0;
  logic rx = 1;
  logic tx, tx_busy, tx_done;
  logic [7:0] rx_data;
  logic rx_valid, rx_error;
endinterface
