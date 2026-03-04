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

`ifndef SYSTEM_SIZES_H
`define SYSTEM_SIZES_H
  // Number of Independent AXI-Stream Weight Channels
  parameter WEIGHT_CHANNELS = RSLT_CHANNELS * DATA_CHANNELS,

  parameter GRID_SHARE = 1,
  parameter SCALE_SHARE = 1,
  parameter DATA_CHANNELS_IN  = BATCH_SIZE*DATA_CHANNELS,
  parameter DATA_CHANNELS_OUT = DATA_CHANNELS_IN,
  parameter RSLT_CHANNELS_OUT = BATCH_SIZE*RSLT_CHANNELS,
  parameter GRID_CHANNELS_OUT = (GRID_SHARE) ? 1 : DATA_CHANNELS*BATCH_SIZE,
  parameter SCALE_CHANNELS_OUT = (SCALE_SHARE) ? 1 : DATA_CHANNELS*BATCH_SIZE,

`endif