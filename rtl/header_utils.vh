`ifndef UTILS_VH
`define UTILS_VH

`define LOG2(x) \
   (((x) <= 2 **  0) ? 1 : \
    ((x) <= 2 **  1) ? 1 : \
    ((x) <= 2 **  2) ? 2 : \
    ((x) <= 2 **  3) ? 3 : \
    ((x) <= 2 **  4) ? 4 : \
    ((x) <= 2 **  5) ? 5 : \
    ((x) <= 2 **  6) ? 6 : \
    ((x) <= 2 **  7) ? 7 : \
    ((x) <= 2 **  8) ? 8 : \
    ((x) <= 2 **  9) ? 9 : \
    ((x) <= 2 ** 10) ? 10 : \
    ((x) <= 2 ** 11) ? 11 : \
    ((x) <= 2 ** 12) ? 12 : \
    ((x) <= 2 ** 13) ? 13 : \
    ((x) <= 2 ** 14) ? 14 : \
    ((x) <= 2 ** 15) ? 15 : \
   -1)

`define RLOG2(x) (((x) <= 1) ? 0 : `LOG2( (x) ))

`define MAX(a, b) (((a) < (b)) ? (b) : (a))

`define MIN(a, b) (((a) < (b)) ? (a) : (b))

`define ABS(signal) (($signed((signal)) >= 0) ? (signal) : -$signed((signal)))

`define ABS_W(signal, width) ((signal[(width)-1] == 1'b1) ? -$signed((signal)) : (signal))

// `define DEBUG

// `define USE_ONE_HOT_ENCODING_FSM
    
`endif
