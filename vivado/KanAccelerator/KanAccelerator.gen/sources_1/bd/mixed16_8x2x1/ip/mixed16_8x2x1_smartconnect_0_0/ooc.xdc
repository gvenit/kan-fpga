# aclk {FREQ_HZ 125000000 CLK_DOMAIN mixed16_8x2x1_processing_system7_0_FCLK_CLK1 PHASE 0.0} aclk1 {FREQ_HZ 250000000 CLK_DOMAIN mixed16_8x2x1_processing_system7_0_FCLK_CLK2 PHASE 0.0}
# Clock Domain: mixed16_8x2x1_processing_system7_0_FCLK_CLK1
create_clock -name aclk -period 8.000 [get_ports aclk]
# Clock Domain: mixed16_8x2x1_processing_system7_0_FCLK_CLK2
create_clock -name aclk1 -period 4.000 [get_ports aclk1]
# Generated clocks
