  `include "header_SystemSizes.vh"
  parameter NUM_PERIPHERALS = 4,

  // Memory Control Unit
  parameter PERIPHERAL_MCU = 0,
  // Data Processing Unit
  parameter PERIPHERAL_DPU = 1,
  // Axi-Stream Packet Splitter
  parameter PERIPHERAL_APS = 2,
  // Axi-Stream Packet Joiner
  parameter PERIPHERAL_JNR = 3,

  // Transmission Offset
  // Memory Control Unit 
  parameter PERIPHERAL_MCU_OFFSET = 0,
  // Data Processing Unit
  parameter PERIPHERAL_DPU_OFFSET = PERIPHERAL_MCU_OFFSET + WEIGHT_CHANNELS,
  // Axi-Stream Packet Splitter
  parameter PERIPHERAL_APS_OFFSET = PERIPHERAL_DPU_OFFSET+1,
  // Axi-Stream Packet Joiner
  parameter PERIPHERAL_JNR_OFFSET = PERIPHERAL_APS_OFFSET+1,

