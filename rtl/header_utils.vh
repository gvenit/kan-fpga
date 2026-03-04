/*
MIT License

Copyright (c) 2025 Georgios Venitourakis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

// Language: Verilog 2001

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
