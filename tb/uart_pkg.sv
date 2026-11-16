`timescale 1ns/1ps
package uart_pkg;
  parameter int CPB = 16;
  parameter time BIT_TIME = time'(CPB * 10ns);
  `include "uart_transaction.svh"
  `include "uart_generator.svh"
  `include "uart_driver.svh"
  `include "uart_monitor.svh"
  `include "uart_scoreboard.svh"
  `include "uart_environment.svh"
endpackage
