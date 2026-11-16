class uart_scoreboard;
  mailbox #(uart_transaction) tx_expected, rx_expected, tx_actual, rx_actual;
  int tx_checked, rx_checked, errors_checked;
  bit tx_seen[256], rx_seen[256];
  function new(mailbox #(uart_transaction) tx_expected, rx_expected, tx_actual, rx_actual);
    this.tx_expected=tx_expected; this.rx_expected=rx_expected;
    this.tx_actual=tx_actual; this.rx_actual=rx_actual;
  endfunction
  task check_tx();
    forever begin
      uart_transaction exp, act;
      tx_actual.get(act);
      if (tx_expected.try_get(exp) == 0) $fatal(1,"Unexpected TX frame");
      if (act.data !== exp.data)
        $fatal(1,"TX mismatch: expected %02h got %02h",exp.data,act.data);
      tx_seen[act.data]=1; tx_checked++;
    end
  endtask
  task check_rx();
    forever begin
      uart_transaction exp, act;
      rx_actual.get(act);
      if (rx_expected.try_get(exp) == 0) $fatal(1,"Unexpected RX output");
      if (act.bad_stop != exp.bad_stop) $fatal(1,"RX error status mismatch");
      if (!exp.bad_stop) begin
        if (act.data !== exp.data)
          $fatal(1,"RX mismatch: expected %02h got %02h",exp.data,act.data);
        rx_seen[act.data]=1;
      end else errors_checked++;
      rx_checked++;
    end
  endtask
  function void report(int expected_tx, expected_rx);
    int tx_bins=0, rx_bins=0;
    foreach(tx_seen[i]) begin tx_bins+=int'(tx_seen[i]); rx_bins+=int'(rx_seen[i]); end
    if (tx_checked!=expected_tx || rx_checked!=expected_rx ||
        tx_expected.num()!=0 || rx_expected.num()!=0 ||
        tx_actual.num()!=0 || rx_actual.num()!=0)
      $fatal(1,"Incomplete scoreboard: TX %0d/%0d RX %0d/%0d",
        tx_checked,expected_tx,rx_checked,expected_rx);
    if (tx_bins!=256 || rx_bins!=256 || errors_checked!=16)
      $fatal(1,"Coverage target not reached");
    $display("PASS: TX=%0d RX=%0d framing_errors=%0d",tx_checked,rx_checked,errors_checked);
    $display("Byte coverage: TX=%0d/256 RX=%0d/256",tx_bins,rx_bins);
  endfunction
endclass
