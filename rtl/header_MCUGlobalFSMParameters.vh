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