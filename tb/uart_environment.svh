class uart_environment;
  mailbox #(uart_transaction) txq, rxq, tx_expected, rx_expected, tx_actual, rx_actual;
  uart_generator gen;
  uart_driver drv;
  uart_monitor mon;
  uart_scoreboard scb;
  function new(virtual uart_if vif);
    txq=new(); rxq=new(); tx_expected=new(); rx_expected=new();
    tx_actual=new(); rx_actual=new();
    gen=new(txq,rxq);
    drv=new(vif,txq,rxq,tx_expected,rx_expected);
    mon=new(vif,tx_actual,rx_actual);
    scb=new(tx_expected,rx_expected,tx_actual,rx_actual);
  endfunction
  task run(int random_count);
    gen.run(random_count);
    fork
      mon.tx_run(); mon.rx_run(); scb.check_tx(); scb.check_rx();
    join_none
    fork
      drv.tx_run(gen.expected_tx);
      drv.rx_run(gen.expected_rx);
    join
    // Keep monitors alive to detect spurious extra frames or pulses.
    #(12*BIT_TIME);
    scb.report(gen.expected_tx,gen.expected_rx);
  endtask
endclass
