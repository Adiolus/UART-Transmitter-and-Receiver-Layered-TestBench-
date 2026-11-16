class uart_monitor;
  virtual uart_if vif;
  mailbox #(uart_transaction) tx_actual, rx_actual;
  function new(virtual uart_if vif, mailbox #(uart_transaction) tx_actual, rx_actual);
    this.vif=vif; this.tx_actual=tx_actual; this.rx_actual=rx_actual;
  endfunction
  task tx_run();
    forever begin
      uart_transaction tr = new();
      @(negedge vif.tx);
      #(BIT_TIME/2);
      if (vif.tx !== 0) $fatal(1,"TX start bit invalid");
      for (int i=0; i<8; i++) begin #(BIT_TIME); tr.data[i]=vif.tx; end
      #(BIT_TIME);
      if (vif.tx !== 1) $fatal(1,"TX stop bit invalid");
      tx_actual.put(tr);
    end
  endtask
  task rx_run();
    forever begin
      @(negedge vif.clk);
      if (vif.rx_valid || vif.rx_error) begin
        uart_transaction tr = new(1,vif.rx_data,vif.rx_error);
        if (vif.rx_valid && vif.rx_error) $fatal(1,"RX valid/error overlap");
        rx_actual.put(tr);
      end
    end
  endtask
endclass
