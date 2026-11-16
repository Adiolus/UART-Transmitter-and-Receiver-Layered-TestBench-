class uart_generator;
  mailbox #(uart_transaction) txq, rxq;
  int expected_tx, expected_rx;
  function new(mailbox #(uart_transaction) txq, rxq);
    this.txq = txq; this.rxq = rxq;
  endfunction
  task add(bit direction, bit [7:0] data, bit bad_stop = 0, int gap = 0);
    uart_transaction tr = new(direction, data, bad_stop, gap);
    if (direction) begin rxq.put(tr); expected_rx++; end
    else begin txq.put(tr); expected_tx++; end
  endtask
  task run(int random_count);
    bit [7:0] patterns[4] = '{8'h00,8'hff,8'h55,8'haa};
    foreach (patterns[i]) begin add(0,patterns[i]); add(1,patterns[i]); end
    for (int i=0; i<256; i++) begin add(0,8'(i)); add(1,8'(i)); end
    repeat (random_count) begin
      uart_transaction tr = new();
      if (tr.randomize() == 0) $fatal(1,"Randomization failed");
      add(0,tr.data,0,$urandom_range(0,3));
      if (tr.randomize() == 0) $fatal(1,"Randomization failed");
      add(1,tr.data,0,$urandom_range(0,3));
    end
    // A full low stop bit is followed by two idle bit periods for recovery.
    repeat (16) add(1,8'($urandom),1,2);
  endtask
endclass
