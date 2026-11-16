class uart_transaction;
  rand bit [7:0] data;
  bit is_rx;
  bit bad_stop;
  int unsigned gap;
  function new(bit is_rx = 0, bit [7:0] data = 0, bit bad_stop = 0,
               int unsigned gap = 0);
    this.is_rx = is_rx; this.data = data;
    this.bad_stop = bad_stop; this.gap = gap;
  endfunction
endclass
