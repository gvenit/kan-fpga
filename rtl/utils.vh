`ifndef UTILS_VH
`define UTILS_VH

`define LOG2(x) \
   ((x <= 1) ? 1 : \
   (x <= 2) ? 1 : \
   (x <= 4) ? 2 : \
   (x <= 8) ? 3 : \
   (x <= 16) ? 4 : \
   (x <= 32) ? 5 : \
   (x <= 64) ? 6 : \
   (x <= 128) ? 7 : \
   (x <= 256) ? 8 : \
   (x <= 512) ? 9 : \
   (x <= 1024) ? 10 : \
   (x <= 2048) ? 11 : \
   (x <= 4096) ? 12 : \
   (x <= 8192) ? 13 : \
   (x <= 16384) ? 14 : \
   (x <= 32768) ? 15 : \
   -1)

`define MAX(a,b) \
   ((a < b) ? b : a)

`ifndef print_message
`define print_message(mes="") \
   if (mes) begin \
      $display("---- %s", mes); \
   end
`endif 

`ifndef assert
`define assert(signal, value, custom_message="")  \
   if (signal !== value) begin \
      $display("ASSERTION FAILED in %m:"); \
      print_message(custom_message); \
      // $display("---- Time %0t",$time); \
      $display("---- %s != %s",`"signal`", `"value`");   \
      $display("---- %s = 0x%h",`"signal`",signal); \
      $display("---- %s = 0x%h",`"value`",value); \
      $finish; \
   end
`endif 

`ifndef assertTrue
`define assertTrue(signal, custom_message="")  \
   if (~signal) begin       \
      $display("ASSERTION FAILED in %m:"); \
      print_message(custom_message); \
      // $display("---- Time %0t",$time); \
      $display("---- %s is not True",`"signal`");  \
      $display("---- %s = 0x%h",`"signal`",signal); \
      $finish; \
   end
`endif 

`define abs(signal) ($signed(signal) < 0) ? -$signed(signal) : signal
    
`endif
