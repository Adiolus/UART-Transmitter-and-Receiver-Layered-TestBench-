`timescale 1ns/1ps
module tb_uart;
  import uart_pkg::*;
  bit clk=0;
  always #5ns clk=~clk;
  uart_if bus(clk);
  uart_environment env;
  int random_count=100;
  int done_count=0;
  int busy_cycles=0;
  // Count full busy intervals; reset intentionally discards the aborted frame.
  always @(negedge clk) begin
    if (!bus.rst_n) begin busy_cycles=0; done_count=0; end
    else begin
      if (bus.tx_busy) busy_cycles++;
      else if (busy_cycles!=0) begin
        if (busy_cycles!=10*CPB || !bus.tx_done)
          $fatal(1,"TX frame duration/done mismatch: %0d cycles",busy_cycles);
        busy_cycles=0;
      end
      if (bus.tx_done) done_count++;
    end
  end
  uart #(.CLKS_PER_BIT(CPB)) dut(
    .clk, .rst_n(bus.rst_n), .tx_start(bus.tx_start), .tx_data(bus.tx_data),
    .rx(bus.rx), .tx(bus.tx), .tx_busy(bus.tx_busy), .tx_done(bus.tx_done),
    .rx_data(bus.rx_data), .rx_valid(bus.rx_valid), .rx_error(bus.rx_error));

  // Cycle-level protocol checks complement the byte-level scoreboard.
  assert property (@(posedge clk) disable iff (!bus.rst_n)
    bus.tx_done |=> !bus.tx_done) else $fatal(1,"TX done wider than one cycle");
  assert property (@(posedge clk) disable iff (!bus.rst_n)
    bus.rx_valid |=> !bus.rx_valid) else $fatal(1,"RX valid wider than one cycle");
  assert property (@(posedge clk) disable iff (!bus.rst_n)
    bus.rx_error |=> !bus.rx_error) else $fatal(1,"RX error wider than one cycle");
  assert property (@(posedge clk) disable iff (!bus.rst_n)
    !bus.tx_busy |-> bus.tx) else $fatal(1,"TX idle is not high");
  assert property (@(posedge clk) disable iff (!bus.rst_n)
    bus.tx_done |-> !bus.tx_busy) else $fatal(1,"TX done while busy");

  task quiet_check(int cycles);
    repeat(cycles) begin
      @(negedge clk);
      if (bus.rx_valid || bus.rx_error || bus.tx_busy || !bus.tx)
        $fatal(1,"Unexpected activity during idle/recovery");
    end
  endtask
  initial begin
    if ($test$plusargs("WAVES")) begin
      $dumpfile("build/uart.vcd"); $dumpvars(0,tb_uart);
    end
    void'($value$plusargs("N_RANDOM=%d",random_count));
    if(random_count<0 || random_count>10000) $fatal(1,"N_RANDOM must be 0..10000");
    repeat(5) @(negedge clk); bus.rst_n=1;
    quiet_check(4);
    // Reset both blocks in the middle of an active frame.
    bus.tx_data=8'ha5; bus.tx_start=1; bus.rx=0;
    @(negedge clk); bus.tx_start=0;
    repeat(3*CPB) @(negedge clk);
    bus.rst_n=0; bus.rx=1;
    repeat(4) @(negedge clk); bus.rst_n=1;
    quiet_check(12*CPB);
    // A short low pulse must fail midpoint start qualification.
    bus.rx=0; repeat(2) @(negedge clk); bus.rx=1;
    quiet_check(12*CPB);
    $display("PASS: reset interruption and false-start rejection");
    env=new(bus);
    env.run(random_count);
    if (done_count != env.gen.expected_tx)
      $fatal(1,"TX done count mismatch");
    $display("PASS: TX frame duration and done count=%0d",done_count);
    $finish;
  end
  initial begin #250ms; $fatal(1,"Global simulation timeout"); end
endmodule
