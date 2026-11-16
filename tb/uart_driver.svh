class uart_driver;
  virtual uart_if vif;
  mailbox #(uart_transaction) txq, rxq, tx_expected, rx_expected;
  function new(virtual uart_if vif,
    mailbox #(uart_transaction) txq, rxq, tx_expected, rx_expected);
    this.vif=vif; this.txq=txq; this.rxq=rxq;
    this.tx_expected=tx_expected; this.rx_expected=rx_expected;
  endfunction
  task tx_run(int count);
    repeat (count) begin
      uart_transaction tr;
      txq.get(tr);
      while (vif.tx_busy) @(negedge vif.clk);
      tx_expected.put(tr);
      @(negedge vif.clk); vif.tx_data=tr.data; vif.tx_start=1;
      @(negedge vif.clk); vif.tx_start=0;
      if (!vif.tx_busy) $fatal(1,"TX request not accepted");
      // Attempt a second request during the start bit: it must be ignored.
      @(negedge vif.clk); vif.tx_data=~tr.data; vif.tx_start=1;
      @(negedge vif.clk); vif.tx_start=0;
      while (vif.tx_busy) @(negedge vif.clk);
      repeat (tr.gap*CPB+1) @(negedge vif.clk);
    end
  endtask
  task rx_run(int count);
    repeat (count) begin
      uart_transaction tr;
      rxq.get(tr); rx_expected.put(tr);
      // Every bit begins on a falling clock edge, away from DUT sampling.
      vif.rx=0; repeat (CPB) @(negedge vif.clk);
      for (int i=0; i<8; i++) begin
        vif.rx=tr.data[i]; repeat (CPB) @(negedge vif.clk);
      end
      vif.rx=!tr.bad_stop;
      repeat (CPB) @(negedge vif.clk);
      vif.rx=1; repeat (tr.gap*CPB) @(negedge vif.clk);
    end
  endtask
endclass
