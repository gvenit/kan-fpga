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

// Global FSM states
 `ifdef USE_ONE_HOT_ENCODING_FSM
  parameter GLO_FSM_WIDTH = 5,
  parameter GLO_FSM_ST0 = 2 ** 0,
  parameter GLO_FSM_STR = 2 ** 1,
  parameter GLO_FSM_OPE = 2 ** 2,
  parameter GLO_FSM_END = 2 ** 3,
  parameter GLO_FSM_ERR = 2 ** 4,
 `else
  parameter GLO_FSM_WIDTH = 3,
  parameter GLO_FSM_ST0 = 0,
  parameter GLO_FSM_STR = 1,
  parameter GLO_FSM_OPE = 2,
  parameter GLO_FSM_END = 3,
  parameter GLO_FSM_ERR = 4,
 `endif 