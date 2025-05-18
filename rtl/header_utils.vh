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

`define RLOG2(x) ((x <= 1) ? 0 : `LOG2(x))

`define MAX(a,b) ((a < b) ? b : a)

`define MIN(a,b) ((a < b) ? (a) : (b))

`define ABS(signal) (($signed(signal) < 0) ? -$signed(signal) : signal)
    
`endif
