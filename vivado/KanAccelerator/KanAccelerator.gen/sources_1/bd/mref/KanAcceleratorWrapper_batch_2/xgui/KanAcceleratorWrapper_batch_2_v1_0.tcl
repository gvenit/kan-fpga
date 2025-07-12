# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "ACT_FRACTIONAL_BITS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ACT_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "AXIL_STRB_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "AXIL_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "CTRL_ADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_ADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_CHANNELS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_FRACTIONAL_BITS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_STRB_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DEST_ENABLE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DEST_OUTPUT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DEST_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DMA_KEEP_ENABLE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DMA_KEEP_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DMA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "EXTRA_CYCLE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "GRID_ADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "GRID_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "GRID_SHARE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ID_OUTPUT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "IS_ASYNCHRONOUS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ROM_DATA_PATH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "RSLT_CHANNELS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "RSLT_FIFO_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "RSLT_FRACTIONAL_BITS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "RSLT_ID_ENABLE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "RSLT_ID_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "RSLT_KEEP_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "RSLT_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SCALED_DIFF_FRACTIONAL_BITS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SCALED_DIFF_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SCALE_ADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SCALE_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SCALE_FRACTIONAL_BITS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SCALE_SHARE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SCALE_STRB_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SCALE_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "USER_ENABLE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "USER_OUTPUT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "USER_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WEIGHT_FIFO_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WEIGHT_FRACTIONAL_BITS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WEIGHT_ID_ENABLE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WEIGHT_ID_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WEIGHT_KEEP_ENABLE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WEIGHT_KEEP_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WEIGHT_LAST_ENABLE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WEIGHT_WIDTH" -parent ${Page_0}


}

proc update_PARAM_VALUE.ACT_FRACTIONAL_BITS { PARAM_VALUE.ACT_FRACTIONAL_BITS } {
	# Procedure called to update ACT_FRACTIONAL_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ACT_FRACTIONAL_BITS { PARAM_VALUE.ACT_FRACTIONAL_BITS } {
	# Procedure called to validate ACT_FRACTIONAL_BITS
	return true
}

proc update_PARAM_VALUE.ACT_WIDTH { PARAM_VALUE.ACT_WIDTH } {
	# Procedure called to update ACT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ACT_WIDTH { PARAM_VALUE.ACT_WIDTH } {
	# Procedure called to validate ACT_WIDTH
	return true
}

proc update_PARAM_VALUE.AXIL_STRB_WIDTH { PARAM_VALUE.AXIL_STRB_WIDTH } {
	# Procedure called to update AXIL_STRB_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXIL_STRB_WIDTH { PARAM_VALUE.AXIL_STRB_WIDTH } {
	# Procedure called to validate AXIL_STRB_WIDTH
	return true
}

proc update_PARAM_VALUE.AXIL_WIDTH { PARAM_VALUE.AXIL_WIDTH } {
	# Procedure called to update AXIL_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXIL_WIDTH { PARAM_VALUE.AXIL_WIDTH } {
	# Procedure called to validate AXIL_WIDTH
	return true
}

proc update_PARAM_VALUE.CTRL_ADDR { PARAM_VALUE.CTRL_ADDR } {
	# Procedure called to update CTRL_ADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CTRL_ADDR { PARAM_VALUE.CTRL_ADDR } {
	# Procedure called to validate CTRL_ADDR
	return true
}

proc update_PARAM_VALUE.DATA_ADDR { PARAM_VALUE.DATA_ADDR } {
	# Procedure called to update DATA_ADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_ADDR { PARAM_VALUE.DATA_ADDR } {
	# Procedure called to validate DATA_ADDR
	return true
}

proc update_PARAM_VALUE.DATA_CHANNELS { PARAM_VALUE.DATA_CHANNELS } {
	# Procedure called to update DATA_CHANNELS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_CHANNELS { PARAM_VALUE.DATA_CHANNELS } {
	# Procedure called to validate DATA_CHANNELS
	return true
}

proc update_PARAM_VALUE.DATA_DEPTH { PARAM_VALUE.DATA_DEPTH } {
	# Procedure called to update DATA_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_DEPTH { PARAM_VALUE.DATA_DEPTH } {
	# Procedure called to validate DATA_DEPTH
	return true
}

proc update_PARAM_VALUE.DATA_FRACTIONAL_BITS { PARAM_VALUE.DATA_FRACTIONAL_BITS } {
	# Procedure called to update DATA_FRACTIONAL_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_FRACTIONAL_BITS { PARAM_VALUE.DATA_FRACTIONAL_BITS } {
	# Procedure called to validate DATA_FRACTIONAL_BITS
	return true
}

proc update_PARAM_VALUE.DATA_STRB_WIDTH { PARAM_VALUE.DATA_STRB_WIDTH } {
	# Procedure called to update DATA_STRB_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_STRB_WIDTH { PARAM_VALUE.DATA_STRB_WIDTH } {
	# Procedure called to validate DATA_STRB_WIDTH
	return true
}

proc update_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to update DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to validate DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.DEST_ENABLE { PARAM_VALUE.DEST_ENABLE } {
	# Procedure called to update DEST_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEST_ENABLE { PARAM_VALUE.DEST_ENABLE } {
	# Procedure called to validate DEST_ENABLE
	return true
}

proc update_PARAM_VALUE.DEST_OUTPUT { PARAM_VALUE.DEST_OUTPUT } {
	# Procedure called to update DEST_OUTPUT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEST_OUTPUT { PARAM_VALUE.DEST_OUTPUT } {
	# Procedure called to validate DEST_OUTPUT
	return true
}

proc update_PARAM_VALUE.DEST_WIDTH { PARAM_VALUE.DEST_WIDTH } {
	# Procedure called to update DEST_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEST_WIDTH { PARAM_VALUE.DEST_WIDTH } {
	# Procedure called to validate DEST_WIDTH
	return true
}

proc update_PARAM_VALUE.DMA_KEEP_ENABLE { PARAM_VALUE.DMA_KEEP_ENABLE } {
	# Procedure called to update DMA_KEEP_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DMA_KEEP_ENABLE { PARAM_VALUE.DMA_KEEP_ENABLE } {
	# Procedure called to validate DMA_KEEP_ENABLE
	return true
}

proc update_PARAM_VALUE.DMA_KEEP_WIDTH { PARAM_VALUE.DMA_KEEP_WIDTH } {
	# Procedure called to update DMA_KEEP_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DMA_KEEP_WIDTH { PARAM_VALUE.DMA_KEEP_WIDTH } {
	# Procedure called to validate DMA_KEEP_WIDTH
	return true
}

proc update_PARAM_VALUE.DMA_WIDTH { PARAM_VALUE.DMA_WIDTH } {
	# Procedure called to update DMA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DMA_WIDTH { PARAM_VALUE.DMA_WIDTH } {
	# Procedure called to validate DMA_WIDTH
	return true
}

proc update_PARAM_VALUE.EXTRA_CYCLE { PARAM_VALUE.EXTRA_CYCLE } {
	# Procedure called to update EXTRA_CYCLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.EXTRA_CYCLE { PARAM_VALUE.EXTRA_CYCLE } {
	# Procedure called to validate EXTRA_CYCLE
	return true
}

proc update_PARAM_VALUE.GRID_ADDR { PARAM_VALUE.GRID_ADDR } {
	# Procedure called to update GRID_ADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.GRID_ADDR { PARAM_VALUE.GRID_ADDR } {
	# Procedure called to validate GRID_ADDR
	return true
}

proc update_PARAM_VALUE.GRID_DEPTH { PARAM_VALUE.GRID_DEPTH } {
	# Procedure called to update GRID_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.GRID_DEPTH { PARAM_VALUE.GRID_DEPTH } {
	# Procedure called to validate GRID_DEPTH
	return true
}

proc update_PARAM_VALUE.GRID_SHARE { PARAM_VALUE.GRID_SHARE } {
	# Procedure called to update GRID_SHARE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.GRID_SHARE { PARAM_VALUE.GRID_SHARE } {
	# Procedure called to validate GRID_SHARE
	return true
}

proc update_PARAM_VALUE.ID_OUTPUT { PARAM_VALUE.ID_OUTPUT } {
	# Procedure called to update ID_OUTPUT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ID_OUTPUT { PARAM_VALUE.ID_OUTPUT } {
	# Procedure called to validate ID_OUTPUT
	return true
}

proc update_PARAM_VALUE.IS_ASYNCHRONOUS { PARAM_VALUE.IS_ASYNCHRONOUS } {
	# Procedure called to update IS_ASYNCHRONOUS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IS_ASYNCHRONOUS { PARAM_VALUE.IS_ASYNCHRONOUS } {
	# Procedure called to validate IS_ASYNCHRONOUS
	return true
}

proc update_PARAM_VALUE.ROM_DATA_PATH { PARAM_VALUE.ROM_DATA_PATH } {
	# Procedure called to update ROM_DATA_PATH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ROM_DATA_PATH { PARAM_VALUE.ROM_DATA_PATH } {
	# Procedure called to validate ROM_DATA_PATH
	return true
}

proc update_PARAM_VALUE.RSLT_CHANNELS { PARAM_VALUE.RSLT_CHANNELS } {
	# Procedure called to update RSLT_CHANNELS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RSLT_CHANNELS { PARAM_VALUE.RSLT_CHANNELS } {
	# Procedure called to validate RSLT_CHANNELS
	return true
}

proc update_PARAM_VALUE.RSLT_FIFO_DEPTH { PARAM_VALUE.RSLT_FIFO_DEPTH } {
	# Procedure called to update RSLT_FIFO_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RSLT_FIFO_DEPTH { PARAM_VALUE.RSLT_FIFO_DEPTH } {
	# Procedure called to validate RSLT_FIFO_DEPTH
	return true
}

proc update_PARAM_VALUE.RSLT_FRACTIONAL_BITS { PARAM_VALUE.RSLT_FRACTIONAL_BITS } {
	# Procedure called to update RSLT_FRACTIONAL_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RSLT_FRACTIONAL_BITS { PARAM_VALUE.RSLT_FRACTIONAL_BITS } {
	# Procedure called to validate RSLT_FRACTIONAL_BITS
	return true
}

proc update_PARAM_VALUE.RSLT_ID_ENABLE { PARAM_VALUE.RSLT_ID_ENABLE } {
	# Procedure called to update RSLT_ID_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RSLT_ID_ENABLE { PARAM_VALUE.RSLT_ID_ENABLE } {
	# Procedure called to validate RSLT_ID_ENABLE
	return true
}

proc update_PARAM_VALUE.RSLT_ID_WIDTH { PARAM_VALUE.RSLT_ID_WIDTH } {
	# Procedure called to update RSLT_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RSLT_ID_WIDTH { PARAM_VALUE.RSLT_ID_WIDTH } {
	# Procedure called to validate RSLT_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.RSLT_KEEP_WIDTH { PARAM_VALUE.RSLT_KEEP_WIDTH } {
	# Procedure called to update RSLT_KEEP_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RSLT_KEEP_WIDTH { PARAM_VALUE.RSLT_KEEP_WIDTH } {
	# Procedure called to validate RSLT_KEEP_WIDTH
	return true
}

proc update_PARAM_VALUE.RSLT_WIDTH { PARAM_VALUE.RSLT_WIDTH } {
	# Procedure called to update RSLT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RSLT_WIDTH { PARAM_VALUE.RSLT_WIDTH } {
	# Procedure called to validate RSLT_WIDTH
	return true
}

proc update_PARAM_VALUE.SCALED_DIFF_FRACTIONAL_BITS { PARAM_VALUE.SCALED_DIFF_FRACTIONAL_BITS } {
	# Procedure called to update SCALED_DIFF_FRACTIONAL_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SCALED_DIFF_FRACTIONAL_BITS { PARAM_VALUE.SCALED_DIFF_FRACTIONAL_BITS } {
	# Procedure called to validate SCALED_DIFF_FRACTIONAL_BITS
	return true
}

proc update_PARAM_VALUE.SCALED_DIFF_WIDTH { PARAM_VALUE.SCALED_DIFF_WIDTH } {
	# Procedure called to update SCALED_DIFF_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SCALED_DIFF_WIDTH { PARAM_VALUE.SCALED_DIFF_WIDTH } {
	# Procedure called to validate SCALED_DIFF_WIDTH
	return true
}

proc update_PARAM_VALUE.SCALE_ADDR { PARAM_VALUE.SCALE_ADDR } {
	# Procedure called to update SCALE_ADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SCALE_ADDR { PARAM_VALUE.SCALE_ADDR } {
	# Procedure called to validate SCALE_ADDR
	return true
}

proc update_PARAM_VALUE.SCALE_DEPTH { PARAM_VALUE.SCALE_DEPTH } {
	# Procedure called to update SCALE_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SCALE_DEPTH { PARAM_VALUE.SCALE_DEPTH } {
	# Procedure called to validate SCALE_DEPTH
	return true
}

proc update_PARAM_VALUE.SCALE_FRACTIONAL_BITS { PARAM_VALUE.SCALE_FRACTIONAL_BITS } {
	# Procedure called to update SCALE_FRACTIONAL_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SCALE_FRACTIONAL_BITS { PARAM_VALUE.SCALE_FRACTIONAL_BITS } {
	# Procedure called to validate SCALE_FRACTIONAL_BITS
	return true
}

proc update_PARAM_VALUE.SCALE_SHARE { PARAM_VALUE.SCALE_SHARE } {
	# Procedure called to update SCALE_SHARE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SCALE_SHARE { PARAM_VALUE.SCALE_SHARE } {
	# Procedure called to validate SCALE_SHARE
	return true
}

proc update_PARAM_VALUE.SCALE_STRB_WIDTH { PARAM_VALUE.SCALE_STRB_WIDTH } {
	# Procedure called to update SCALE_STRB_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SCALE_STRB_WIDTH { PARAM_VALUE.SCALE_STRB_WIDTH } {
	# Procedure called to validate SCALE_STRB_WIDTH
	return true
}

proc update_PARAM_VALUE.SCALE_WIDTH { PARAM_VALUE.SCALE_WIDTH } {
	# Procedure called to update SCALE_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SCALE_WIDTH { PARAM_VALUE.SCALE_WIDTH } {
	# Procedure called to validate SCALE_WIDTH
	return true
}

proc update_PARAM_VALUE.USER_ENABLE { PARAM_VALUE.USER_ENABLE } {
	# Procedure called to update USER_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.USER_ENABLE { PARAM_VALUE.USER_ENABLE } {
	# Procedure called to validate USER_ENABLE
	return true
}

proc update_PARAM_VALUE.USER_OUTPUT { PARAM_VALUE.USER_OUTPUT } {
	# Procedure called to update USER_OUTPUT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.USER_OUTPUT { PARAM_VALUE.USER_OUTPUT } {
	# Procedure called to validate USER_OUTPUT
	return true
}

proc update_PARAM_VALUE.USER_WIDTH { PARAM_VALUE.USER_WIDTH } {
	# Procedure called to update USER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.USER_WIDTH { PARAM_VALUE.USER_WIDTH } {
	# Procedure called to validate USER_WIDTH
	return true
}

proc update_PARAM_VALUE.WEIGHT_FIFO_DEPTH { PARAM_VALUE.WEIGHT_FIFO_DEPTH } {
	# Procedure called to update WEIGHT_FIFO_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WEIGHT_FIFO_DEPTH { PARAM_VALUE.WEIGHT_FIFO_DEPTH } {
	# Procedure called to validate WEIGHT_FIFO_DEPTH
	return true
}

proc update_PARAM_VALUE.WEIGHT_FRACTIONAL_BITS { PARAM_VALUE.WEIGHT_FRACTIONAL_BITS } {
	# Procedure called to update WEIGHT_FRACTIONAL_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WEIGHT_FRACTIONAL_BITS { PARAM_VALUE.WEIGHT_FRACTIONAL_BITS } {
	# Procedure called to validate WEIGHT_FRACTIONAL_BITS
	return true
}

proc update_PARAM_VALUE.WEIGHT_ID_ENABLE { PARAM_VALUE.WEIGHT_ID_ENABLE } {
	# Procedure called to update WEIGHT_ID_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WEIGHT_ID_ENABLE { PARAM_VALUE.WEIGHT_ID_ENABLE } {
	# Procedure called to validate WEIGHT_ID_ENABLE
	return true
}

proc update_PARAM_VALUE.WEIGHT_ID_WIDTH { PARAM_VALUE.WEIGHT_ID_WIDTH } {
	# Procedure called to update WEIGHT_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WEIGHT_ID_WIDTH { PARAM_VALUE.WEIGHT_ID_WIDTH } {
	# Procedure called to validate WEIGHT_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.WEIGHT_KEEP_ENABLE { PARAM_VALUE.WEIGHT_KEEP_ENABLE } {
	# Procedure called to update WEIGHT_KEEP_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WEIGHT_KEEP_ENABLE { PARAM_VALUE.WEIGHT_KEEP_ENABLE } {
	# Procedure called to validate WEIGHT_KEEP_ENABLE
	return true
}

proc update_PARAM_VALUE.WEIGHT_KEEP_WIDTH { PARAM_VALUE.WEIGHT_KEEP_WIDTH } {
	# Procedure called to update WEIGHT_KEEP_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WEIGHT_KEEP_WIDTH { PARAM_VALUE.WEIGHT_KEEP_WIDTH } {
	# Procedure called to validate WEIGHT_KEEP_WIDTH
	return true
}

proc update_PARAM_VALUE.WEIGHT_LAST_ENABLE { PARAM_VALUE.WEIGHT_LAST_ENABLE } {
	# Procedure called to update WEIGHT_LAST_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WEIGHT_LAST_ENABLE { PARAM_VALUE.WEIGHT_LAST_ENABLE } {
	# Procedure called to validate WEIGHT_LAST_ENABLE
	return true
}

proc update_PARAM_VALUE.WEIGHT_WIDTH { PARAM_VALUE.WEIGHT_WIDTH } {
	# Procedure called to update WEIGHT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WEIGHT_WIDTH { PARAM_VALUE.WEIGHT_WIDTH } {
	# Procedure called to validate WEIGHT_WIDTH
	return true
}


proc update_MODELPARAM_VALUE.DMA_WIDTH { MODELPARAM_VALUE.DMA_WIDTH PARAM_VALUE.DMA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DMA_WIDTH}] ${MODELPARAM_VALUE.DMA_WIDTH}
}

proc update_MODELPARAM_VALUE.DMA_KEEP_ENABLE { MODELPARAM_VALUE.DMA_KEEP_ENABLE PARAM_VALUE.DMA_KEEP_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DMA_KEEP_ENABLE}] ${MODELPARAM_VALUE.DMA_KEEP_ENABLE}
}

proc update_MODELPARAM_VALUE.DMA_KEEP_WIDTH { MODELPARAM_VALUE.DMA_KEEP_WIDTH PARAM_VALUE.DMA_KEEP_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DMA_KEEP_WIDTH}] ${MODELPARAM_VALUE.DMA_KEEP_WIDTH}
}

proc update_MODELPARAM_VALUE.AXIL_WIDTH { MODELPARAM_VALUE.AXIL_WIDTH PARAM_VALUE.AXIL_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIL_WIDTH}] ${MODELPARAM_VALUE.AXIL_WIDTH}
}

proc update_MODELPARAM_VALUE.AXIL_STRB_WIDTH { MODELPARAM_VALUE.AXIL_STRB_WIDTH PARAM_VALUE.AXIL_STRB_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIL_STRB_WIDTH}] ${MODELPARAM_VALUE.AXIL_STRB_WIDTH}
}

proc update_MODELPARAM_VALUE.DATA_WIDTH { MODELPARAM_VALUE.DATA_WIDTH PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_WIDTH}] ${MODELPARAM_VALUE.DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.DATA_FRACTIONAL_BITS { MODELPARAM_VALUE.DATA_FRACTIONAL_BITS PARAM_VALUE.DATA_FRACTIONAL_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_FRACTIONAL_BITS}] ${MODELPARAM_VALUE.DATA_FRACTIONAL_BITS}
}

proc update_MODELPARAM_VALUE.DATA_CHANNELS { MODELPARAM_VALUE.DATA_CHANNELS PARAM_VALUE.DATA_CHANNELS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_CHANNELS}] ${MODELPARAM_VALUE.DATA_CHANNELS}
}

proc update_MODELPARAM_VALUE.DATA_DEPTH { MODELPARAM_VALUE.DATA_DEPTH PARAM_VALUE.DATA_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_DEPTH}] ${MODELPARAM_VALUE.DATA_DEPTH}
}

proc update_MODELPARAM_VALUE.DATA_STRB_WIDTH { MODELPARAM_VALUE.DATA_STRB_WIDTH PARAM_VALUE.DATA_STRB_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_STRB_WIDTH}] ${MODELPARAM_VALUE.DATA_STRB_WIDTH}
}

proc update_MODELPARAM_VALUE.DATA_ADDR { MODELPARAM_VALUE.DATA_ADDR PARAM_VALUE.DATA_ADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_ADDR}] ${MODELPARAM_VALUE.DATA_ADDR}
}

proc update_MODELPARAM_VALUE.GRID_SHARE { MODELPARAM_VALUE.GRID_SHARE PARAM_VALUE.GRID_SHARE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.GRID_SHARE}] ${MODELPARAM_VALUE.GRID_SHARE}
}

proc update_MODELPARAM_VALUE.GRID_DEPTH { MODELPARAM_VALUE.GRID_DEPTH PARAM_VALUE.GRID_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.GRID_DEPTH}] ${MODELPARAM_VALUE.GRID_DEPTH}
}

proc update_MODELPARAM_VALUE.GRID_ADDR { MODELPARAM_VALUE.GRID_ADDR PARAM_VALUE.GRID_ADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.GRID_ADDR}] ${MODELPARAM_VALUE.GRID_ADDR}
}

proc update_MODELPARAM_VALUE.SCALE_SHARE { MODELPARAM_VALUE.SCALE_SHARE PARAM_VALUE.SCALE_SHARE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SCALE_SHARE}] ${MODELPARAM_VALUE.SCALE_SHARE}
}

proc update_MODELPARAM_VALUE.SCALE_WIDTH { MODELPARAM_VALUE.SCALE_WIDTH PARAM_VALUE.SCALE_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SCALE_WIDTH}] ${MODELPARAM_VALUE.SCALE_WIDTH}
}

proc update_MODELPARAM_VALUE.SCALE_FRACTIONAL_BITS { MODELPARAM_VALUE.SCALE_FRACTIONAL_BITS PARAM_VALUE.SCALE_FRACTIONAL_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SCALE_FRACTIONAL_BITS}] ${MODELPARAM_VALUE.SCALE_FRACTIONAL_BITS}
}

proc update_MODELPARAM_VALUE.SCALE_DEPTH { MODELPARAM_VALUE.SCALE_DEPTH PARAM_VALUE.SCALE_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SCALE_DEPTH}] ${MODELPARAM_VALUE.SCALE_DEPTH}
}

proc update_MODELPARAM_VALUE.RSLT_CHANNELS { MODELPARAM_VALUE.RSLT_CHANNELS PARAM_VALUE.RSLT_CHANNELS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RSLT_CHANNELS}] ${MODELPARAM_VALUE.RSLT_CHANNELS}
}

proc update_MODELPARAM_VALUE.RSLT_WIDTH { MODELPARAM_VALUE.RSLT_WIDTH PARAM_VALUE.RSLT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RSLT_WIDTH}] ${MODELPARAM_VALUE.RSLT_WIDTH}
}

proc update_MODELPARAM_VALUE.RSLT_FRACTIONAL_BITS { MODELPARAM_VALUE.RSLT_FRACTIONAL_BITS PARAM_VALUE.RSLT_FRACTIONAL_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RSLT_FRACTIONAL_BITS}] ${MODELPARAM_VALUE.RSLT_FRACTIONAL_BITS}
}

proc update_MODELPARAM_VALUE.RSLT_KEEP_WIDTH { MODELPARAM_VALUE.RSLT_KEEP_WIDTH PARAM_VALUE.RSLT_KEEP_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RSLT_KEEP_WIDTH}] ${MODELPARAM_VALUE.RSLT_KEEP_WIDTH}
}

proc update_MODELPARAM_VALUE.RSLT_FIFO_DEPTH { MODELPARAM_VALUE.RSLT_FIFO_DEPTH PARAM_VALUE.RSLT_FIFO_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RSLT_FIFO_DEPTH}] ${MODELPARAM_VALUE.RSLT_FIFO_DEPTH}
}

proc update_MODELPARAM_VALUE.SCALE_STRB_WIDTH { MODELPARAM_VALUE.SCALE_STRB_WIDTH PARAM_VALUE.SCALE_STRB_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SCALE_STRB_WIDTH}] ${MODELPARAM_VALUE.SCALE_STRB_WIDTH}
}

proc update_MODELPARAM_VALUE.SCALE_ADDR { MODELPARAM_VALUE.SCALE_ADDR PARAM_VALUE.SCALE_ADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SCALE_ADDR}] ${MODELPARAM_VALUE.SCALE_ADDR}
}

proc update_MODELPARAM_VALUE.WEIGHT_WIDTH { MODELPARAM_VALUE.WEIGHT_WIDTH PARAM_VALUE.WEIGHT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WEIGHT_WIDTH}] ${MODELPARAM_VALUE.WEIGHT_WIDTH}
}

proc update_MODELPARAM_VALUE.WEIGHT_FRACTIONAL_BITS { MODELPARAM_VALUE.WEIGHT_FRACTIONAL_BITS PARAM_VALUE.WEIGHT_FRACTIONAL_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WEIGHT_FRACTIONAL_BITS}] ${MODELPARAM_VALUE.WEIGHT_FRACTIONAL_BITS}
}

proc update_MODELPARAM_VALUE.WEIGHT_KEEP_ENABLE { MODELPARAM_VALUE.WEIGHT_KEEP_ENABLE PARAM_VALUE.WEIGHT_KEEP_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WEIGHT_KEEP_ENABLE}] ${MODELPARAM_VALUE.WEIGHT_KEEP_ENABLE}
}

proc update_MODELPARAM_VALUE.WEIGHT_KEEP_WIDTH { MODELPARAM_VALUE.WEIGHT_KEEP_WIDTH PARAM_VALUE.WEIGHT_KEEP_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WEIGHT_KEEP_WIDTH}] ${MODELPARAM_VALUE.WEIGHT_KEEP_WIDTH}
}

proc update_MODELPARAM_VALUE.WEIGHT_FIFO_DEPTH { MODELPARAM_VALUE.WEIGHT_FIFO_DEPTH PARAM_VALUE.WEIGHT_FIFO_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WEIGHT_FIFO_DEPTH}] ${MODELPARAM_VALUE.WEIGHT_FIFO_DEPTH}
}

proc update_MODELPARAM_VALUE.SCALED_DIFF_WIDTH { MODELPARAM_VALUE.SCALED_DIFF_WIDTH PARAM_VALUE.SCALED_DIFF_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SCALED_DIFF_WIDTH}] ${MODELPARAM_VALUE.SCALED_DIFF_WIDTH}
}

proc update_MODELPARAM_VALUE.SCALED_DIFF_FRACTIONAL_BITS { MODELPARAM_VALUE.SCALED_DIFF_FRACTIONAL_BITS PARAM_VALUE.SCALED_DIFF_FRACTIONAL_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SCALED_DIFF_FRACTIONAL_BITS}] ${MODELPARAM_VALUE.SCALED_DIFF_FRACTIONAL_BITS}
}

proc update_MODELPARAM_VALUE.ACT_WIDTH { MODELPARAM_VALUE.ACT_WIDTH PARAM_VALUE.ACT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ACT_WIDTH}] ${MODELPARAM_VALUE.ACT_WIDTH}
}

proc update_MODELPARAM_VALUE.ACT_FRACTIONAL_BITS { MODELPARAM_VALUE.ACT_FRACTIONAL_BITS PARAM_VALUE.ACT_FRACTIONAL_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ACT_FRACTIONAL_BITS}] ${MODELPARAM_VALUE.ACT_FRACTIONAL_BITS}
}

proc update_MODELPARAM_VALUE.WEIGHT_LAST_ENABLE { MODELPARAM_VALUE.WEIGHT_LAST_ENABLE PARAM_VALUE.WEIGHT_LAST_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WEIGHT_LAST_ENABLE}] ${MODELPARAM_VALUE.WEIGHT_LAST_ENABLE}
}

proc update_MODELPARAM_VALUE.WEIGHT_ID_ENABLE { MODELPARAM_VALUE.WEIGHT_ID_ENABLE PARAM_VALUE.WEIGHT_ID_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WEIGHT_ID_ENABLE}] ${MODELPARAM_VALUE.WEIGHT_ID_ENABLE}
}

proc update_MODELPARAM_VALUE.WEIGHT_ID_WIDTH { MODELPARAM_VALUE.WEIGHT_ID_WIDTH PARAM_VALUE.WEIGHT_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WEIGHT_ID_WIDTH}] ${MODELPARAM_VALUE.WEIGHT_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.RSLT_ID_ENABLE { MODELPARAM_VALUE.RSLT_ID_ENABLE PARAM_VALUE.RSLT_ID_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RSLT_ID_ENABLE}] ${MODELPARAM_VALUE.RSLT_ID_ENABLE}
}

proc update_MODELPARAM_VALUE.RSLT_ID_WIDTH { MODELPARAM_VALUE.RSLT_ID_WIDTH PARAM_VALUE.RSLT_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RSLT_ID_WIDTH}] ${MODELPARAM_VALUE.RSLT_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.ID_OUTPUT { MODELPARAM_VALUE.ID_OUTPUT PARAM_VALUE.ID_OUTPUT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ID_OUTPUT}] ${MODELPARAM_VALUE.ID_OUTPUT}
}

proc update_MODELPARAM_VALUE.DEST_ENABLE { MODELPARAM_VALUE.DEST_ENABLE PARAM_VALUE.DEST_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEST_ENABLE}] ${MODELPARAM_VALUE.DEST_ENABLE}
}

proc update_MODELPARAM_VALUE.DEST_WIDTH { MODELPARAM_VALUE.DEST_WIDTH PARAM_VALUE.DEST_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEST_WIDTH}] ${MODELPARAM_VALUE.DEST_WIDTH}
}

proc update_MODELPARAM_VALUE.DEST_OUTPUT { MODELPARAM_VALUE.DEST_OUTPUT PARAM_VALUE.DEST_OUTPUT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEST_OUTPUT}] ${MODELPARAM_VALUE.DEST_OUTPUT}
}

proc update_MODELPARAM_VALUE.USER_ENABLE { MODELPARAM_VALUE.USER_ENABLE PARAM_VALUE.USER_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.USER_ENABLE}] ${MODELPARAM_VALUE.USER_ENABLE}
}

proc update_MODELPARAM_VALUE.USER_WIDTH { MODELPARAM_VALUE.USER_WIDTH PARAM_VALUE.USER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.USER_WIDTH}] ${MODELPARAM_VALUE.USER_WIDTH}
}

proc update_MODELPARAM_VALUE.USER_OUTPUT { MODELPARAM_VALUE.USER_OUTPUT PARAM_VALUE.USER_OUTPUT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.USER_OUTPUT}] ${MODELPARAM_VALUE.USER_OUTPUT}
}

proc update_MODELPARAM_VALUE.EXTRA_CYCLE { MODELPARAM_VALUE.EXTRA_CYCLE PARAM_VALUE.EXTRA_CYCLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.EXTRA_CYCLE}] ${MODELPARAM_VALUE.EXTRA_CYCLE}
}

proc update_MODELPARAM_VALUE.CTRL_ADDR { MODELPARAM_VALUE.CTRL_ADDR PARAM_VALUE.CTRL_ADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CTRL_ADDR}] ${MODELPARAM_VALUE.CTRL_ADDR}
}

proc update_MODELPARAM_VALUE.IS_ASYNCHRONOUS { MODELPARAM_VALUE.IS_ASYNCHRONOUS PARAM_VALUE.IS_ASYNCHRONOUS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IS_ASYNCHRONOUS}] ${MODELPARAM_VALUE.IS_ASYNCHRONOUS}
}

proc update_MODELPARAM_VALUE.ROM_DATA_PATH { MODELPARAM_VALUE.ROM_DATA_PATH PARAM_VALUE.ROM_DATA_PATH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ROM_DATA_PATH}] ${MODELPARAM_VALUE.ROM_DATA_PATH}
}

