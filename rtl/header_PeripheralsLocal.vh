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

  localparam NUM_PERIPHERALS = 4;

  // Memory Control Unit
  localparam PERIPHERAL_MCU = 0;
  // Data Processing Unit
  localparam PERIPHERAL_DPU = 1;
  // Axi-Stream Packet Splitter
  localparam PERIPHERAL_APS = 2;
  // Axi-Stream Packet Joiner
  localparam PERIPHERAL_JNR = 3;

  // Transmission Offset
  // Memory Control Unit 
  localparam PERIPHERAL_MCU_OFFSET = 0;
  // Data Processing Unit
  localparam PERIPHERAL_DPU_OFFSET = PERIPHERAL_MCU_OFFSET + DATA_CHANNELS_OUT + GRID_CHANNELS_OUT + SCALE_CHANNELS_OUT;
  // Axi-Stream Packet Splitter
  localparam PERIPHERAL_APS_OFFSET = PERIPHERAL_DPU_OFFSET + 1;
  // Axi-Stream Packet Joiner
  localparam PERIPHERAL_JNR_OFFSET = PERIPHERAL_APS_OFFSET + WEIGHT_CHANNELS;
  // Total transmission length
  localparam PERIPHERAL_TRANSMISSION_WIDTH = PERIPHERAL_JNR_OFFSET + 1;

